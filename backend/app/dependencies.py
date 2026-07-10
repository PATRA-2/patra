from typing import Annotated
from uuid import UUID

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.database import get_db
from app.errors import AppError
from app.models import User
from app.security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False, scheme_name="BearerAuth")


def get_request_settings(request: Request) -> Settings:
    return request.app.state.settings


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    settings: Annotated[Settings, Depends(get_request_settings)],
    session: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise AppError(401, "UNAUTHORIZED", "Bearer token wajib dikirim.")
    payload = decode_access_token(credentials.credentials, settings)
    try:
        user_id = UUID(str(payload["sub"]))
    except (ValueError, KeyError) as exc:
        raise AppError(401, "UNAUTHORIZED", "Bearer token tidak valid.") from exc
    user = await session.get(User, user_id)
    if user is None:
        raise AppError(401, "UNAUTHORIZED", "User untuk token ini tidak ditemukan.")
    return user


async def require_admin(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if user.role != "cooperative_admin":
        raise AppError(403, "FORBIDDEN", "Akses hanya tersedia untuk admin koperasi.")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
AdminUser = Annotated[User, Depends(require_admin)]
DBSession = Annotated[AsyncSession, Depends(get_db)]
RequestSettings = Annotated[Settings, Depends(get_request_settings)]
