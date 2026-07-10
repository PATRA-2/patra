from fastapi import APIRouter, status
from sqlalchemy import select

from app.dependencies import CurrentUser, DBSession
from app.models import UserDevice, utc_now
from app.schemas import DataResponse, DeviceCreate, DeviceOut
from app.services import as_utc

router = APIRouter(prefix="/devices", tags=["Devices"])


@router.post("", response_model=DataResponse[DeviceOut], status_code=status.HTTP_201_CREATED)
async def upsert_device(
    payload: DeviceCreate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[DeviceOut]:
    device = await session.scalar(
        select(UserDevice).where(UserDevice.fcm_token == payload.fcm_token)
    )
    if device is None:
        device = UserDevice(
            user_id=user.id,
            fcm_token=payload.fcm_token,
            platform=payload.platform,
        )
        session.add(device)
    else:
        device.user_id = user.id
        device.platform = payload.platform
        device.last_seen_at = utc_now()
    await session.commit()
    await session.refresh(device)
    return DataResponse(
        data=DeviceOut(
            id=device.id,
            platform=device.platform,
            last_seen_at=as_utc(device.last_seen_at),
        )
    )
