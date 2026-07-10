from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Request
from sqlalchemy import func, select, text

from app.dependencies import AdminUser, DBSession
from app.errors import AppError
from app.models import Farm, Notification, PlantReport, UserDevice
from app.schemas import (
    BroadcastSummary,
    Coordinate,
    DashboardReportOut,
    DataResponse,
    MapItemsOut,
    MapReportOut,
    PaginatedData,
    RejectReportIn,
    VerifyBroadcastIn,
    VerifyBroadcastOut,
)
from app.services import (
    REPORT_PENDING,
    REPORT_REJECTED,
    REPORT_VERIFIED,
    as_utc,
    dashboard_report_out,
    haversine_km,
    report_out,
)

router = APIRouter(prefix="/dashboard", tags=["Cooperative Dashboard"])


@router.get("/reports", response_model=DataResponse[PaginatedData[DashboardReportOut]])
async def dashboard_reports(
    _admin: AdminUser,
    session: DBSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    status: str | None = None,
    category: str | None = None,
) -> DataResponse[PaginatedData[DashboardReportOut]]:
    conditions = []
    if status:
        conditions.append(PlantReport.status == status)
    if category:
        conditions.append(PlantReport.category == category)
    total = await session.scalar(select(func.count()).select_from(PlantReport).where(*conditions))
    reports = (
        await session.scalars(
            select(PlantReport)
            .where(*conditions)
            .order_by(PlantReport.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    items = [await dashboard_report_out(session, report) for report in reports]
    return DataResponse(
        data=PaginatedData(items=items, page=page, page_size=page_size, total=total or 0)
    )


@router.get("/map-reports", response_model=DataResponse[MapItemsOut])
async def dashboard_map_reports(
    _admin: AdminUser,
    session: DBSession,
) -> DataResponse[MapItemsOut]:
    reports = (
        await session.scalars(select(PlantReport).order_by(PlantReport.created_at.desc()))
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


async def _target_farms(
    session: DBSession, report: PlantReport, radius_km: float
) -> dict[UUID, Farm]:
    dialect_name = session.bind.dialect.name if session.bind else "sqlite"
    if dialect_name == "postgresql":
        rows = (
            await session.execute(
                text(
                    """
                    SELECT id, user_id
                    FROM farms
                    WHERE user_id != CAST(:owner_id AS uuid)
                      AND ST_DWithin(
                          geo_location,
                          (SELECT geo_location FROM plant_reports
                           WHERE id = CAST(:report_id AS uuid)),
                          :radius_meters
                      )
                    ORDER BY ST_Distance(
                        geo_location,
                        (SELECT geo_location FROM plant_reports
                         WHERE id = CAST(:report_id AS uuid))
                    )
                    """
                ),
                {
                    "owner_id": report.user_id,
                    "report_id": report.id,
                    "radius_meters": radius_km * 1000,
                },
            )
        ).all()
        targets: dict[UUID, Farm] = {}
        for row in rows:
            user_id = UUID(str(row.user_id))
            if user_id not in targets:
                farm = await session.get(Farm, UUID(str(row.id)))
                if farm:
                    targets[user_id] = farm
        return targets

    farms = (await session.scalars(select(Farm).where(Farm.user_id != report.user_id))).all()
    candidates = sorted(
        (
            (
                farm,
                haversine_km(
                    report.latitude,
                    report.longitude,
                    farm.latitude,
                    farm.longitude,
                ),
            )
            for farm in farms
        ),
        key=lambda item: item[1],
    )
    targets: dict[UUID, Farm] = {}
    for farm, distance in candidates:
        if distance <= radius_km and farm.user_id not in targets:
            targets[farm.user_id] = farm
    return targets


@router.post(
    "/reports/{report_id}/verify-broadcast",
    response_model=DataResponse[VerifyBroadcastOut],
)
async def verify_and_broadcast(
    report_id: UUID,
    payload: VerifyBroadcastIn,
    request: Request,
    admin: AdminUser,
    session: DBSession,
) -> DataResponse[VerifyBroadcastOut]:
    report = await session.get(PlantReport, report_id)
    if report is None:
        raise AppError(404, "NOT_FOUND", "Laporan tidak ditemukan.")
    if report.status == REPORT_VERIFIED:
        raise AppError(409, "REPORT_ALREADY_VERIFIED", "Laporan sudah diverifikasi.")
    if report.status == REPORT_REJECTED:
        raise AppError(409, "REPORT_ALREADY_REJECTED", "Laporan sudah ditolak.")
    if report.status != REPORT_PENDING:
        raise AppError(
            409,
            "REPORT_NOT_READY",
            "Laporan belum siap diverifikasi karena analisis AI belum selesai.",
        )

    report.status = REPORT_VERIFIED
    report.verified_by = admin.id
    report.verified_at = datetime.now(UTC)
    targets = await _target_farms(session, report, payload.radius_km)

    notifications: dict[UUID, Notification] = {}
    for user_id, farm in targets.items():
        notification = Notification(
            receiver_user_id=user_id,
            receiver_farm_id=farm.id,
            report_id=report.id,
            title="Peringatan Radar Tani",
            message=f"Laporan {report.title} terverifikasi di sekitar lahan Anda.",
            status="pending",
        )
        session.add(notification)
        notifications[user_id] = notification
    await session.commit()

    devices = (
        (
            await session.scalars(select(UserDevice).where(UserDevice.user_id.in_(list(targets))))
        ).all()
        if targets
        else []
    )
    token_to_user = {device.fcm_token: device.user_id for device in devices}
    delivery_results = await request.app.state.services.notifier.send(
        list(token_to_user),
        "Peringatan Radar Tani",
        f"{report.title} terverifikasi di sekitar lahan Anda.",
        {"report_id": str(report.id), "route": "radar-feed"},
    )
    successful_users = {
        token_to_user[result.token] for result in delivery_results if result.success
    }
    now = datetime.now(UTC)
    for user_id, notification in notifications.items():
        if user_id in successful_users:
            notification.status = "sent"
            notification.sent_at = now
        else:
            notification.status = "failed"
    await session.commit()
    await session.refresh(report)

    targeted = len(targets)
    sent = len(successful_users)
    return DataResponse(
        data=VerifyBroadcastOut(
            report=await report_out(session, report),
            broadcast=BroadcastSummary(
                targeted=targeted,
                sent=sent,
                failed=targeted - sent,
            ),
        )
    )


@router.post("/reports/{report_id}/reject", response_model=DataResponse[DashboardReportOut])
async def reject_report(
    report_id: UUID,
    payload: RejectReportIn,
    _admin: AdminUser,
    session: DBSession,
) -> DataResponse[DashboardReportOut]:
    report = await session.get(PlantReport, report_id)
    if report is None:
        raise AppError(404, "NOT_FOUND", "Laporan tidak ditemukan.")
    if report.status == REPORT_VERIFIED:
        raise AppError(409, "REPORT_ALREADY_VERIFIED", "Laporan sudah diverifikasi.")
    report.status = REPORT_REJECTED
    report.rejected_reason = payload.reason
    await session.commit()
    await session.refresh(report)
    return DataResponse(data=await dashboard_report_out(session, report))
