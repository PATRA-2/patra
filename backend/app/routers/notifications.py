from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Response, status
from sqlalchemy import func, select, update

from app.dependencies import CurrentUser, DBSession
from app.errors import AppError
from app.models import Notification
from app.schemas import DataResponse, NotificationOut, PaginatedData
from app.services import as_utc

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def notification_out(item: Notification) -> NotificationOut:
    return NotificationOut(
        id=item.id,
        title=item.title,
        message=item.message,
        related_report_id=item.report_id,
        is_read=item.is_read,
        created_at=as_utc(item.created_at),
    )


@router.get("", response_model=DataResponse[PaginatedData[NotificationOut]])
async def list_notifications(
    user: CurrentUser,
    session: DBSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    unread_only: bool = False,
) -> DataResponse[PaginatedData[NotificationOut]]:
    conditions = [Notification.receiver_user_id == user.id]
    if unread_only:
        conditions.append(Notification.is_read.is_(False))
    total = await session.scalar(select(func.count()).select_from(Notification).where(*conditions))
    rows = (
        await session.scalars(
            select(Notification)
            .where(*conditions)
            .order_by(Notification.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    return DataResponse(
        data=PaginatedData(
            items=[notification_out(item) for item in rows],
            page=page,
            page_size=page_size,
            total=total or 0,
        )
    )


@router.patch("/{notification_id}/read", response_model=DataResponse[NotificationOut])
async def mark_read(
    notification_id: UUID,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[NotificationOut]:
    item = await session.get(Notification, notification_id)
    if item is None:
        raise AppError(404, "NOT_FOUND", "Notifikasi tidak ditemukan.")
    if item.receiver_user_id != user.id:
        raise AppError(403, "FORBIDDEN", "Notifikasi bukan milik user ini.")
    item.is_read = True
    await session.commit()
    await session.refresh(item)
    return DataResponse(data=notification_out(item))


@router.patch("/read-all", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
async def mark_all_read(user: CurrentUser, session: DBSession) -> Response:
    await session.execute(
        update(Notification)
        .where(Notification.receiver_user_id == user.id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
