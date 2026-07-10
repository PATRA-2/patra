from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_name: str = "Radar Tani API"
    app_version: str = "1.0.0"
    app_env: Literal["development", "test", "production"] = "development"
    service_mode: Literal["demo", "real"] = "demo"
    api_v1_prefix: str = "/api/v1"

    database_url: str = "sqlite+aiosqlite:///./.data/radar_tani.db"
    public_base_url: str = "http://127.0.0.1:8000"
    upload_dir: Path = Path(".data/uploads")

    jwt_secret: str = "development-only-change-me-at-least-32-bytes"
    jwt_algorithm: str = "HS256"
    access_token_expire_seconds: int = 3600
    refresh_token_expire_days: int = 30

    max_upload_bytes: int = 10 * 1024 * 1024
    ai_sync_timeout_seconds: float = 10.0
    standalone_ai_timeout_seconds: float = 30.0
    demo_ai_delay_seconds: float = 0.0

    demo_admin_email: str = "admin@radartani.id"
    demo_admin_password: str = "admin123"

    supabase_url: str | None = None
    supabase_service_role_key: str | None = None
    supabase_bucket_name: str = "plant-reports"
    signed_url_expire_seconds: int = 3600

    gemini_api_key: str | None = None
    gemini_model: str = "gemini-2.5-flash"

    firebase_project_id: str | None = None
    firebase_client_email: str | None = None
    firebase_private_key: str | None = None

    cors_origins: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_runtime_configuration(self) -> "Settings":
        if len(self.jwt_secret.encode("utf-8")) < 32:
            raise ValueError("JWT_SECRET minimal 32 byte.")
        if (
            self.app_env == "production"
            and self.jwt_secret == "development-only-change-me-at-least-32-bytes"
        ):
            raise ValueError("JWT_SECRET wajib diganti di production.")

        if self.service_mode == "real":
            required = {
                "SUPABASE_URL": self.supabase_url,
                "SUPABASE_SERVICE_ROLE_KEY": self.supabase_service_role_key,
                "GEMINI_API_KEY": self.gemini_api_key,
                "FIREBASE_PROJECT_ID": self.firebase_project_id,
                "FIREBASE_CLIENT_EMAIL": self.firebase_client_email,
                "FIREBASE_PRIVATE_KEY": self.firebase_private_key,
            }
            missing = [name for name, value in required.items() if not value]
            if missing:
                raise ValueError(
                    "Konfigurasi service production belum lengkap: " + ", ".join(missing)
                )
            if not self.database_url.startswith(("postgresql://", "postgresql+asyncpg://")):
                raise ValueError("SERVICE_MODE=real membutuhkan PostgreSQL DATABASE_URL.")
        return self

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")

    @property
    def async_database_url(self) -> str:
        if self.database_url.startswith("postgresql://"):
            return self.database_url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return self.database_url


@lru_cache
def get_settings() -> Settings:
    return Settings()
