from io import BytesIO
from pathlib import Path
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from pydantic import ValidationError

from app.config import Settings
from app.main import create_app


def png_bytes() -> bytes:
    buffer = BytesIO()
    Image.new("RGB", (12, 12), color=(40, 150, 70)).save(buffer, format="PNG")
    return buffer.getvalue()


def register(
    client: TestClient,
    email: str = "petani@example.com",
    password: str = "secret123",
) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "name": "Petani Test",
            "email": email,
            "password": password,
            "cooperative_name": "Koperasi Test",
            "farm_location": "Desa Test",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["data"]


def login(client: TestClient, email: str, password: str) -> dict:
    response = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200, response.text
    return response.json()["data"]


def auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def create_farm(
    client: TestClient,
    token: str,
    name: str = "Sawah Utara",
    latitude: float = -7.7956,
    longitude: float = 110.3695,
) -> dict:
    response = client.post(
        "/api/v1/farms",
        headers=auth_header(token),
        json={
            "name": name,
            "crop": "Cabai",
            "location": "Desa Sukamaju",
            "coordinate": {"latitude": latitude, "longitude": longitude},
            "is_active": True,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["data"]


def create_report(client: TestClient, token: str, farm_id: str, title: str = "Daun rusak") -> dict:
    response = client.post(
        "/api/v1/plant-reports",
        headers=auth_header(token),
        data={
            "title": title,
            "category": "Hama",
            "description": "Daun mengeriting sejak dua hari lalu.",
            "farm_id": farm_id,
            "publish_to_feed": "true",
        },
        files={"image": ("plant.png", png_bytes(), "image/png")},
    )
    assert response.status_code == 201, response.text
    return response.json()["data"]


def test_health_openapi_security_and_validation_shape(client: TestClient) -> None:
    health = client.get("/health")
    assert health.status_code == 200
    assert health.json() == {
        "data": {"status": "ok", "service": "radar-tani-api", "version": "1.0.0"}
    }
    assert client.get("/api/v1/health").status_code == 200

    openapi = client.get("/openapi.json").json()
    assert "BearerAuth" in openapi["components"]["securitySchemes"]
    assert "/api/v1/plant-reports" in openapi["paths"]
    assert "/api/v1/dashboard/reports/{report_id}/verify-broadcast" in openapi["paths"]
    validation_schema = openapi["paths"]["/api/v1/auth/register"]["post"]["responses"]["422"]
    assert validation_schema["content"]["application/json"]["schema"]["$ref"].endswith(
        "/ErrorResponse"
    )

    invalid = client.post(
        "/api/v1/auth/register",
        json={"name": "x", "email": "not-email", "password": "123"},
    )
    assert invalid.status_code == 422
    body = invalid.json()["error"]
    assert body["code"] == "VALIDATION_ERROR"
    assert {detail["field"] for detail in body["details"]} >= {"name", "email", "password"}

    unauthorized = client.get("/api/v1/me")
    assert unauthorized.status_code == 401
    assert unauthorized.json()["error"]["code"] == "UNAUTHORIZED"


def test_auth_refresh_rotation_and_logout(client: TestClient) -> None:
    auth = register(client)
    token = auth["access_token"]
    assert auth["token_type"] == "Bearer"
    assert auth["expires_in"] == 3600
    assert UUID(auth["user"]["id"])

    duplicate = client.post(
        "/api/v1/auth/register",
        json={
            "name": "Petani Test",
            "email": "PETANI@example.com",
            "password": "secret123",
        },
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["error"]["code"] == "EMAIL_ALREADY_REGISTERED"

    me = client.get("/api/v1/me", headers=auth_header(token))
    assert me.status_code == 200
    assert me.json()["data"]["email"] == "petani@example.com"

    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": auth["refresh_token"]})
    assert refreshed.status_code == 200
    replacement = refreshed.json()["data"]
    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": auth["refresh_token"]})
    assert reused.status_code == 401
    assert reused.json()["error"]["code"] == "INVALID_REFRESH_TOKEN"

    logout = client.post("/api/v1/auth/logout", headers=auth_header(replacement["access_token"]))
    assert logout.status_code == 204
    assert logout.content == b""
    after_logout = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": replacement["refresh_token"]}
    )
    assert after_logout.status_code == 401


def test_farm_crud_and_single_active_farm(client: TestClient) -> None:
    auth = register(client)
    token = auth["access_token"]
    first = create_farm(client, token, "Sawah Pertama")
    second = create_farm(client, token, "Sawah Kedua")

    listing = client.get("/api/v1/farms", headers=auth_header(token)).json()["data"]
    assert listing["total"] == 2
    active = [item for item in listing["items"] if item["is_active"]]
    assert [item["id"] for item in active] == [second["id"]]
    assert listing["items"][0]["created_at"].endswith("Z")

    updated = client.patch(
        f"/api/v1/farms/{first['id']}",
        headers=auth_header(token),
        json={"is_active": True, "crop": "Padi"},
    )
    assert updated.status_code == 200
    assert updated.json()["data"]["crop"] == "Padi"

    deleted = client.delete(f"/api/v1/farms/{second['id']}", headers=auth_header(token))
    assert deleted.status_code == 204
    assert deleted.content == b""


def test_report_diagnosis_feed_map_and_orders(client: TestClient) -> None:
    auth = register(client)
    token = auth["access_token"]
    farm = create_farm(client, token)
    report = create_report(client, token, farm["id"])

    assert report["status"] == "Menunggu verifikasi"
    assert report["diagnosis"]["confidence"] == 82
    assert report["image_url"].startswith("http://testserver/media/")

    history = client.get("/api/v1/plant-reports", headers=auth_header(token)).json()["data"]
    assert history["total"] == 1
    assert history["items"][0]["id"] == report["id"]

    feed = client.get("/api/v1/radar-feed/reports", headers=auth_header(token)).json()["data"]
    assert feed["total"] == 1
    assert feed["items"][0]["distance"] == "0.0 km"
    assert isinstance(feed["items"][0]["distance_km"], float)

    map_result = client.get("/api/v1/map/reports", headers=auth_header(token)).json()
    assert map_result["data"]["items"][0]["id"] == report["id"]

    diagnosis = client.post(
        "/api/v1/plant-diagnoses",
        headers=auth_header(token),
        data={"crop": "Cabai", "symptom_notes": "Bercak cokelat"},
        files={"image": ("plant.png", png_bytes(), "image/png")},
    )
    assert diagnosis.status_code == 200
    assert diagnosis.json()["data"]["confidence"] == 82

    unsupported = client.post(
        "/api/v1/plant-diagnoses",
        headers=auth_header(token),
        files={"image": ("plant.txt", b"not an image", "text/plain")},
    )
    assert unsupported.status_code == 415
    assert unsupported.json()["error"]["code"] == "UNSUPPORTED_MEDIA_TYPE"

    order = client.post(
        "/api/v1/pesticide-orders",
        headers=auth_header(token),
        json={
            "product_name": "Pestisida Nabati",
            "quantity": 2,
            "related_report_id": report["id"],
        },
    )
    assert order.status_code == 201
    assert order.json()["data"]["status"] == "Diproses"
    orders = client.get("/api/v1/pesticide-orders", headers=auth_header(token)).json()["data"]
    assert orders["total"] == 1


def test_dashboard_verify_broadcast_and_notification_history(client: TestClient) -> None:
    owner = register(client, "owner@example.com")
    owner_token = owner["access_token"]
    owner_farm = create_farm(client, owner_token, "Sawah Owner")
    report = create_report(client, owner_token, owner_farm["id"], "Serangan trips")

    target = register(client, "target@example.com")
    target_token = target["access_token"]
    create_farm(client, target_token, "Sawah Target", -7.796, 110.37)
    device = client.post(
        "/api/v1/devices",
        headers=auth_header(target_token),
        json={"fcm_token": "test-device-token-123456", "platform": "ios"},
    )
    assert device.status_code == 201
    assert "fcm_token" not in device.json()["data"]

    admin = login(client, "admin@radartani.id", "admin123")
    admin_headers = auth_header(admin["access_token"])
    dashboard = client.get("/api/v1/dashboard/reports", headers=admin_headers)
    assert dashboard.status_code == 200
    assert dashboard.json()["data"]["total"] == 1

    verified = client.post(
        f"/api/v1/dashboard/reports/{report['id']}/verify-broadcast",
        headers=admin_headers,
        json={"radius_km": 10},
    )
    assert verified.status_code == 200, verified.text
    body = verified.json()["data"]
    assert body["report"]["status"] == "Terverifikasi"
    assert body["broadcast"] == {"targeted": 1, "sent": 1, "failed": 0}

    duplicate = client.post(
        f"/api/v1/dashboard/reports/{report['id']}/verify-broadcast",
        headers=admin_headers,
        json={"radius_km": 10},
    )
    assert duplicate.status_code == 409

    notifications = client.get("/api/v1/notifications", headers=auth_header(target_token)).json()[
        "data"
    ]
    assert notifications["total"] == 1
    notification = notifications["items"][0]
    assert notification["related_report_id"] == report["id"]
    assert notification["is_read"] is False

    marked = client.patch(
        f"/api/v1/notifications/{notification['id']}/read",
        headers=auth_header(target_token),
    )
    assert marked.status_code == 200
    assert marked.json()["data"]["is_read"] is True
    mark_all = client.patch("/api/v1/notifications/read-all", headers=auth_header(target_token))
    assert mark_all.status_code == 204


def test_cross_user_ownership_and_farm_required(client: TestClient) -> None:
    first = register(client, "first@example.com")
    first_token = first["access_token"]
    farm = create_farm(client, first_token)
    report = create_report(client, first_token, farm["id"])

    second = register(client, "second@example.com")
    second_headers = auth_header(second["access_token"])
    forbidden = client.get(f"/api/v1/plant-reports/{report['id']}", headers=second_headers)
    assert forbidden.status_code == 403

    missing_farm = client.post(
        "/api/v1/plant-reports",
        headers=second_headers,
        data={"title": "Daun rusak", "category": "Hama"},
        files={"image": ("plant.png", png_bytes(), "image/png")},
    )
    assert missing_farm.status_code == 422
    assert missing_farm.json()["error"]["code"] == "FARM_REQUIRED"

    admin_only = client.get("/api/v1/dashboard/reports", headers=second_headers)
    assert admin_only.status_code == 403


def test_ai_timeout_finishes_in_background_and_size_limit(tmp_path: Path) -> None:
    settings = Settings(
        _env_file=None,
        app_env="test",
        service_mode="demo",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'async.db'}",
        upload_dir=tmp_path / "uploads",
        public_base_url="http://testserver",
        jwt_secret="test-secret-with-enough-entropy-123456",
        demo_admin_email="admin@radartani.id",
        demo_admin_password="admin123",
        demo_ai_delay_seconds=0.03,
        ai_sync_timeout_seconds=0.001,
        max_upload_bytes=100,
    )
    with TestClient(create_app(settings)) as async_client:
        auth = register(async_client, "async@example.com")
        token = auth["access_token"]
        farm = create_farm(async_client, token)
        response = async_client.post(
            "/api/v1/plant-reports",
            headers=auth_header(token),
            data={"title": "Analisis lambat", "category": "Penyakit", "farm_id": farm["id"]},
            files={"image": ("plant.png", png_bytes(), "image/png")},
        )
        assert response.status_code == 201
        created = response.json()["data"]
        assert created["status"] == "Analisis berjalan"
        assert created["diagnosis"] is None

        detail = async_client.get(
            f"/api/v1/plant-reports/{created['id']}", headers=auth_header(token)
        )
        assert detail.status_code == 200
        assert detail.json()["data"]["status"] == "Menunggu verifikasi"
        assert detail.json()["data"]["diagnosis"]["confidence"] == 82

        oversized = async_client.post(
            "/api/v1/plant-diagnoses",
            headers=auth_header(token),
            files={"image": ("large.png", b"x" * 101, "image/png")},
        )
        assert oversized.status_code == 413
        assert oversized.json()["error"]["code"] == "PAYLOAD_TOO_LARGE"


def test_rejected_report_is_hidden_from_feed(client: TestClient) -> None:
    owner = register(client, "reject-owner@example.com")
    token = owner["access_token"]
    farm = create_farm(client, token)
    report = create_report(client, token, farm["id"], "Laporan ditolak")
    admin = login(client, "admin@radartani.id", "admin123")

    rejected = client.post(
        f"/api/v1/dashboard/reports/{report['id']}/reject",
        headers=auth_header(admin["access_token"]),
        json={"reason": "Foto tidak cukup jelas."},
    )
    assert rejected.status_code == 200
    assert rejected.json()["data"]["status"] == "Ditolak"
    assert rejected.json()["data"]["rejected_reason"] == "Foto tidak cukup jelas."

    feed = client.get("/api/v1/radar-feed/reports", headers=auth_header(token)).json()["data"]
    assert feed["total"] == 0
    blocked_edit = client.patch(
        f"/api/v1/plant-reports/{report['id']}",
        headers=auth_header(token),
        json={"title": "Tidak boleh diubah"},
    )
    assert blocked_edit.status_code == 409


def test_settings_normalize_postgres_url_and_reject_short_secret() -> None:
    settings = Settings(
        _env_file=None,
        database_url="postgresql://user:password@example.com/database",
        jwt_secret="a" * 32,
    )
    assert settings.async_database_url.startswith("postgresql+asyncpg://")
    with pytest.raises(ValidationError):
        Settings(_env_file=None, jwt_secret="too-short")
