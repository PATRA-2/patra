from collections.abc import Iterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def client(tmp_path: Path) -> Iterator[TestClient]:
    settings = Settings(
        _env_file=None,
        app_env="test",
        service_mode="demo",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'test.db'}",
        upload_dir=tmp_path / "uploads",
        public_base_url="http://testserver",
        jwt_secret="test-secret-with-enough-entropy-123456",
        demo_admin_email="admin@radartani.id",
        demo_admin_password="admin123",
        demo_ai_delay_seconds=0,
    )
    with TestClient(create_app(settings)) as test_client:
        yield test_client
