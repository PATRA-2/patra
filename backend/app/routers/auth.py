from datetime import UTC, datetime

from fastapi import APIRouter, Response, status
from sqlalchemy import select, update

from app.config import Settings
from app.dependencies import CurrentUser, DBSession, RequestSettings
from app.errors import AppError
from app.models import RefreshSession, User
from app.schemas import (
    AuthOut,
    DataResponse,
    LoginIn,
    RefreshIn,
    RegisterIn,
    TokenPairOut,
    UserOut,
)
from app.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    hash_refresh_token,
    refresh_expiry,
    verify_password,
)
from app.services import user_out

router = APIRouter(tags=["Authentication"])


def _new_token_pair(user: User, settings: Settings) -> tuple[TokenPairOut, RefreshSession]:
    raw_refresh = create_refresh_token()
    refresh_session = RefreshSession(
        user_id=user.id,
        token_hash=hash_refresh_token(raw_refresh),
        expires_at=refresh_expiry(settings),
    )
    return (
        TokenPairOut(
            access_token=create_access_token(user, settings),
            refresh_token=raw_refresh,
            expires_in=settings.access_token_expire_seconds,
        ),
        refresh_session,
    )


@router.post(
    "/auth/register",
    response_model=DataResponse[AuthOut],
    status_code=status.HTTP_201_CREATED,
)
async def register(
    payload: RegisterIn,
    session: DBSession,
    settings: RequestSettings,
) -> DataResponse[AuthOut]:
    email = str(payload.email).lower()
    existing = await session.scalar(select(User.id).where(User.email == email))
    if existing is not None:
        raise AppError(409, "EMAIL_ALREADY_REGISTERED", "Email sudah terdaftar.")

    user = User(
        name=payload.name,
        email=email,
        password_hash=hash_password(payload.password),
        cooperative_name=payload.cooperative_name,
        farm_location=payload.farm_location,
        role="farmer",
    )
    session.add(user)
    await session.flush()
    tokens, refresh_session = _new_token_pair(user, settings)
    session.add(refresh_session)
    await session.commit()
    return DataResponse(data=AuthOut(user=user_out(user), **tokens.model_dump()))


@router.post("/auth/login", response_model=DataResponse[AuthOut])
async def login(
    payload: LoginIn,
    session: DBSession,
    settings: RequestSettings,
) -> DataResponse[AuthOut]:
    user = await session.scalar(select(User).where(User.email == str(payload.email).lower()))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise AppError(401, "INVALID_CREDENTIALS", "Email atau password salah.")
    tokens, refresh_session = _new_token_pair(user, settings)
    session.add(refresh_session)
    await session.commit()
    return DataResponse(data=AuthOut(user=user_out(user), **tokens.model_dump()))


@router.post("/auth/refresh", response_model=DataResponse[TokenPairOut])
async def refresh(
    payload: RefreshIn,
    session: DBSession,
    settings: RequestSettings,
) -> DataResponse[TokenPairOut]:
    token_hash = hash_refresh_token(payload.refresh_token)
    refresh_session = await session.scalar(
        select(RefreshSession).where(RefreshSession.token_hash == token_hash)
    )
    now = datetime.now(UTC)
    if (
        refresh_session is None
        or refresh_session.revoked_at is not None
        or refresh_session.expires_at.replace(tzinfo=UTC) <= now
    ):
        raise AppError(401, "INVALID_REFRESH_TOKEN", "Refresh token tidak valid atau kedaluwarsa.")

    user = await session.get(User, refresh_session.user_id)
    if user is None:
        raise AppError(401, "INVALID_REFRESH_TOKEN", "User untuk refresh token tidak ditemukan.")
    refresh_session.revoked_at = now
    tokens, replacement = _new_token_pair(user, settings)
    session.add(replacement)
    await session.commit()
    return DataResponse(data=tokens)


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
async def logout(user: CurrentUser, session: DBSession) -> Response:
    await session.execute(
        update(RefreshSession)
        .where(RefreshSession.user_id == user.id, RefreshSession.revoked_at.is_(None))
        .values(revoked_at=datetime.now(UTC))
    )
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=DataResponse[UserOut])
async def me(user: CurrentUser) -> DataResponse[UserOut]:
    return DataResponse(data=user_out(user))
