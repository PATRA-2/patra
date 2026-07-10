from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import select

from app.config import Settings, get_settings
from app.database import Database
from app.errors import install_exception_handlers
from app.integrations import create_services
from app.models import User
from app.routers import auth, dashboard, devices, farms, feed, notifications, orders, reports
from app.schemas import DataResponse, ErrorResponse, HealthOut
from app.security import hash_password


async def seed_demo_admin(app: FastAPI) -> None:
    settings: Settings = app.state.settings
    if settings.service_mode != "demo" or not settings.demo_admin_email:
        return
    async with app.state.database.session_factory() as session:
        email = settings.demo_admin_email.lower()
        existing = await session.scalar(select(User).where(User.email == email))
        if existing is None:
            session.add(
                User(
                    name="Admin Koperasi",
                    email=email,
                    password_hash=hash_password(settings.demo_admin_password),
                    cooperative_name="Koperasi Radar Tani",
                    role="cooperative_admin",
                )
            )
            await session.commit()


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved = settings or get_settings()
    database = Database.create(resolved)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        if resolved.service_mode == "demo":
            resolved.upload_dir.mkdir(parents=True, exist_ok=True)
        if resolved.is_sqlite:
            await database.create_demo_schema()
        await seed_demo_admin(app)
        yield
        await database.dispose()

    error_responses = {
        code: {"model": ErrorResponse, "description": description}
        for code, description in {
            400: "Bad request",
            401: "Bearer token tidak valid",
            403: "Akses ditolak",
            404: "Resource tidak ditemukan",
            409: "Konflik status resource",
            413: "Upload terlalu besar",
            415: "Media type tidak didukung",
            422: "Validasi request gagal",
            429: "Rate limit terlampaui",
            500: "Kesalahan internal server",
        }.items()
    }
    app = FastAPI(
        title=resolved.app_name,
        version=resolved.app_version,
        description="Backend Radar Tani Desa untuk mobile petani dan dashboard koperasi.",
        lifespan=lifespan,
        docs_url=None if resolved.is_production else "/docs",
        redoc_url=None if resolved.is_production else "/redoc",
        openapi_url=None if resolved.is_production else "/openapi.json",
        responses=error_responses,
    )
    app.state.settings = resolved
    app.state.database = database
    app.state.services = create_services(resolved)

    if resolved.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=resolved.cors_origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    install_exception_handlers(app)
    app.mount("/media", StaticFiles(directory=resolved.upload_dir, check_dir=False), name="media")

    async def health() -> DataResponse[HealthOut]:
        return DataResponse(
            data=HealthOut(
                status="ok",
                service="radar-tani-api",
                version=resolved.app_version,
            )
        )

    app.add_api_route(
        "/health",
        health,
        methods=["GET"],
        response_model=DataResponse[HealthOut],
        tags=["Health"],
    )
    app.add_api_route(
        f"{resolved.api_v1_prefix}/health",
        health,
        methods=["GET"],
        response_model=DataResponse[HealthOut],
        tags=["Health"],
        include_in_schema=False,
    )

    for module in (auth, farms, reports, feed, notifications, orders, devices, dashboard):
        app.include_router(module.router, prefix=resolved.api_v1_prefix)
    return app


app = create_app()
