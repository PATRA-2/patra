from typing import Annotated

from fastapi import APIRouter, Query, status
from sqlalchemy import func, select

from app.dependencies import CurrentUser, DBSession
from app.errors import AppError
from app.models import PesticideOrder, PlantReport
from app.schemas import (
    DataResponse,
    PaginatedData,
    PesticideOrderCreate,
    PesticideOrderOut,
)
from app.services import as_utc

router = APIRouter(prefix="/pesticide-orders", tags=["Pesticide Orders"])


def order_out(order: PesticideOrder) -> PesticideOrderOut:
    return PesticideOrderOut(
        id=order.id,
        product_name=order.product_name,
        quantity=order.quantity,
        status=order.status,
        created_at=as_utc(order.created_at),
    )


@router.get("", response_model=DataResponse[PaginatedData[PesticideOrderOut]])
async def list_orders(
    user: CurrentUser,
    session: DBSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> DataResponse[PaginatedData[PesticideOrderOut]]:
    condition = PesticideOrder.user_id == user.id
    total = await session.scalar(select(func.count()).select_from(PesticideOrder).where(condition))
    orders = (
        await session.scalars(
            select(PesticideOrder)
            .where(condition)
            .order_by(PesticideOrder.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    return DataResponse(
        data=PaginatedData(
            items=[order_out(order) for order in orders],
            page=page,
            page_size=page_size,
            total=total or 0,
        )
    )


@router.post(
    "",
    response_model=DataResponse[PesticideOrderOut],
    status_code=status.HTTP_201_CREATED,
)
async def create_order(
    payload: PesticideOrderCreate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[PesticideOrderOut]:
    if payload.related_report_id:
        report = await session.get(PlantReport, payload.related_report_id)
        if report is None:
            raise AppError(404, "NOT_FOUND", "Laporan terkait tidak ditemukan.")
    order = PesticideOrder(
        user_id=user.id,
        related_report_id=payload.related_report_id,
        product_name=payload.product_name,
        quantity=payload.quantity,
        status="Diproses",
    )
    session.add(order)
    await session.commit()
    await session.refresh(order)
    return DataResponse(data=order_out(order))
