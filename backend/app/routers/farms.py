from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Response, status
from sqlalchemy import func, select, update

from app.dependencies import CurrentUser, DBSession
from app.errors import AppError
from app.models import Farm, PlantReport
from app.schemas import DataResponse, FarmCreate, FarmOut, FarmUpdate, PaginatedData
from app.services import farm_out, find_owned_farm

router = APIRouter(prefix="/farms", tags=["Farms"])


@router.get("", response_model=DataResponse[PaginatedData[FarmOut]])
async def list_farms(
    user: CurrentUser,
    session: DBSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> DataResponse[PaginatedData[FarmOut]]:
    conditions = Farm.user_id == user.id
    total = await session.scalar(select(func.count()).select_from(Farm).where(conditions))
    rows = (
        await session.scalars(
            select(Farm)
            .where(conditions)
            .order_by(Farm.is_active.desc(), Farm.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    return DataResponse(
        data=PaginatedData(
            items=[farm_out(farm) for farm in rows],
            page=page,
            page_size=page_size,
            total=total or 0,
        )
    )


@router.post("", response_model=DataResponse[FarmOut], status_code=status.HTTP_201_CREATED)
async def create_farm(
    payload: FarmCreate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[FarmOut]:
    if payload.is_active:
        await session.execute(update(Farm).where(Farm.user_id == user.id).values(is_active=False))
    farm = Farm(
        user_id=user.id,
        name=payload.name,
        crop=payload.crop,
        location=payload.location,
        latitude=payload.coordinate.latitude,
        longitude=payload.coordinate.longitude,
        is_active=payload.is_active,
    )
    session.add(farm)
    await session.commit()
    await session.refresh(farm)
    return DataResponse(data=farm_out(farm))


@router.patch("/{farm_id}", response_model=DataResponse[FarmOut])
async def update_farm(
    farm_id: UUID,
    payload: FarmUpdate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[FarmOut]:
    farm = await find_owned_farm(session, farm_id, user.id)
    changes = payload.model_dump(exclude_unset=True)
    coordinate = changes.pop("coordinate", None)
    if changes.get("is_active") is True:
        await session.execute(
            update(Farm).where(Farm.user_id == user.id, Farm.id != farm.id).values(is_active=False)
        )
    for field, value in changes.items():
        setattr(farm, field, value)
    if coordinate:
        farm.latitude = coordinate["latitude"]
        farm.longitude = coordinate["longitude"]
    await session.commit()
    await session.refresh(farm)
    return DataResponse(data=farm_out(farm))


@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
async def delete_farm(
    farm_id: UUID,
    user: CurrentUser,
    session: DBSession,
) -> Response:
    farm = await find_owned_farm(session, farm_id, user.id)
    referenced = await session.scalar(
        select(func.count()).select_from(PlantReport).where(PlantReport.farm_id == farm.id)
    )
    if referenced:
        raise AppError(409, "FARM_IN_USE", "Lahan masih digunakan oleh laporan.")
    await session.delete(farm)
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
