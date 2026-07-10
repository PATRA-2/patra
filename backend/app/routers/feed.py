from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query
from sqlalchemy import select, text

from app.dependencies import CurrentUser, DBSession
from app.errors import AppError
from app.models import Farm, PlantReport
from app.schemas import (
    Coordinate,
    DataResponse,
    FeedReportOut,
    MapItemsOut,
    MapReportOut,
    PaginatedData,
    PlantReportOut,
)
from app.services import REPORT_REJECTED, active_farm, as_utc, haversine_km, report_out

router = APIRouter(tags=["Radar Feed and Map"])


async def _origin(
    session: DBSession,
    user_id: UUID,
    latitude: float | None,
    longitude: float | None,
) -> tuple[float, float]:
    if (latitude is None) != (longitude is None):
        raise AppError(422, "VALIDATION_ERROR", "latitude dan longitude harus dikirim bersama.")
    if latitude is not None and longitude is not None:
        return latitude, longitude
    farm = await active_farm(session, user_id)
    if farm is None:
        raise AppError(422, "LOCATION_REQUIRED", "Lokasi atau lahan aktif diperlukan.")
    return farm.latitude, farm.longitude


async def _nearby_reports(
    session: DBSession,
    latitude: float,
    longitude: float,
    radius_km: float,
    category: str | None,
) -> list[tuple[PlantReport, float]]:
    dialect_name = session.bind.dialect.name if session.bind else "sqlite"
    if dialect_name == "postgresql":
        sql = """
            SELECT id,
                   ST_Distance(
                       geo_location,
                       ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography
                   ) / 1000.0 AS distance_km
            FROM plant_reports
            WHERE publish_to_feed = true
              AND status != :rejected
              AND ST_DWithin(
                    geo_location,
                    ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography,
                    :radius_meters
              )
              AND (:category IS NULL OR category = :category)
            ORDER BY distance_km, created_at DESC
        """
        rows = (
            await session.execute(
                text(sql),
                {
                    "latitude": latitude,
                    "longitude": longitude,
                    "radius_meters": radius_km * 1000,
                    "category": category,
                    "rejected": REPORT_REJECTED,
                },
            )
        ).all()
        if not rows:
            return []
        ids = [UUID(str(row.id)) for row in rows]
        reports = (await session.scalars(select(PlantReport).where(PlantReport.id.in_(ids)))).all()
        by_id = {report.id: report for report in reports}
        return [
            (by_id[report_id], float(row.distance_km))
            for report_id, row in zip(ids, rows, strict=True)
        ]

    conditions = [
        PlantReport.publish_to_feed.is_(True),
        PlantReport.status != REPORT_REJECTED,
    ]
    if category:
        conditions.append(PlantReport.category == category)
    reports = (await session.scalars(select(PlantReport).where(*conditions))).all()
    nearby = [
        (
            report,
            haversine_km(latitude, longitude, report.latitude, report.longitude),
        )
        for report in reports
    ]
    return sorted(
        (item for item in nearby if item[1] <= radius_km),
        key=lambda item: (item[1], -item[0].created_at.timestamp()),
    )


@router.get("/radar-feed/reports", response_model=DataResponse[PaginatedData[FeedReportOut]])
async def radar_feed(
    user: CurrentUser,
    session: DBSession,
    latitude: Annotated[float | None, Query(ge=-90, le=90)] = None,
    longitude: Annotated[float | None, Query(ge=-180, le=180)] = None,
    radius_km: Annotated[float, Query(gt=0, le=100)] = 10,
    category: str | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> DataResponse[PaginatedData[FeedReportOut]]:
    origin_lat, origin_lon = await _origin(session, user.id, latitude, longitude)
    nearby = await _nearby_reports(session, origin_lat, origin_lon, radius_km, category)
    total = len(nearby)
    window = nearby[(page - 1) * page_size : page * page_size]
    items: list[FeedReportOut] = []
    for report, distance_km in window:
        farm = await session.get(Farm, report.farm_id)
        if farm is None:
            continue
        rounded = round(distance_km, 1)
        items.append(
            FeedReportOut(
                id=report.id,
                category=report.category,
                distance=f"{rounded:.1f} km",
                distance_km=rounded,
                title=report.title,
                summary=report.summary,
                status=report.status,
                farm_name=farm.name,
                coordinate=Coordinate(latitude=report.latitude, longitude=report.longitude),
                image_url=report.image_url,
                created_at=as_utc(report.created_at),
            )
        )
    return DataResponse(
        data=PaginatedData(items=items, page=page, page_size=page_size, total=total)
    )


@router.get("/radar-feed/reports/{report_id}", response_model=DataResponse[PlantReportOut])
async def public_report_detail(
    report_id: UUID,
    _user: CurrentUser,
    session: DBSession,
) -> DataResponse[PlantReportOut]:
    report = await session.get(PlantReport, report_id)
    if report is None or not report.publish_to_feed or report.status == REPORT_REJECTED:
        raise AppError(404, "NOT_FOUND", "Laporan publik tidak ditemukan.")
    return DataResponse(data=await report_out(session, report))


@router.get("/map/reports", response_model=DataResponse[MapItemsOut])
async def map_reports(
    _user: CurrentUser,
    session: DBSession,
    min_latitude: Annotated[float | None, Query(ge=-90, le=90)] = None,
    max_latitude: Annotated[float | None, Query(ge=-90, le=90)] = None,
    min_longitude: Annotated[float | None, Query(ge=-180, le=180)] = None,
    max_longitude: Annotated[float | None, Query(ge=-180, le=180)] = None,
    category: str | None = None,
) -> DataResponse[MapItemsOut]:
    if min_latitude is not None and max_latitude is not None and min_latitude > max_latitude:
        raise AppError(422, "VALIDATION_ERROR", "Batas latitude tidak valid.")
    if min_longitude is not None and max_longitude is not None and min_longitude > max_longitude:
        raise AppError(422, "VALIDATION_ERROR", "Batas longitude tidak valid.")
    conditions = [
        PlantReport.publish_to_feed.is_(True),
        PlantReport.status != REPORT_REJECTED,
    ]
    if min_latitude is not None:
        conditions.append(PlantReport.latitude >= min_latitude)
    if max_latitude is not None:
        conditions.append(PlantReport.latitude <= max_latitude)
    if min_longitude is not None:
        conditions.append(PlantReport.longitude >= min_longitude)
    if max_longitude is not None:
        conditions.append(PlantReport.longitude <= max_longitude)
    if category:
        conditions.append(PlantReport.category == category)
    reports = (
        await session.scalars(
            select(PlantReport).where(*conditions).order_by(PlantReport.created_at.desc())
        )
    ).all()
    return DataResponse(
        data=MapItemsOut(
            items=[
                MapReportOut(
                    id=report.id,
                    title=report.title,
                    category=report.category,
                    status=report.status,
                    coordinate=Coordinate(latitude=report.latitude, longitude=report.longitude),
                    created_at=as_utc(report.created_at),
                )
                for report in reports
            ]
        )
    )
