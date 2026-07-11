# Panduan Backend Radar Tani Desa

**Stack:** FastAPI + SQLAlchemy async + Alembic + JWT + pytest

---

## Daftar Isi

1. [Struktur Proyek](#1-struktur-proyek)
2. [Setup & Menjalankan](#2-setup--menjalankan)
3. [Pola Arsitektur](#3-pola-arsitektur)
4. [Membuat Endpoint Baru](#4-membuat-endpoint-baru)
5. [Membuat Model & Migration](#5-membuat-model--migration)
6. [Autentikasi & Authorisasi](#6-autentikasi--authorisasi)
7. [Error Handling](#7-error-handling)
8. [Integrasi Layanan Eksternal](#8-integrasi-layanan-eksternal)
9. [Testing](#9-testing)
10. [CLI Tools](#10-cli-tools)
11. [Production Checklist](#11-production-checklist)
12. [Daftar Lengkap Endpoint](#12-daftar-lengkap-endpoint)

---

## 1. Struktur Proyek

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # Entry point FastAPI, create_app()
│   ├── config.py             # Settings via pydantic-settings (.env)
│   ├── database.py           # Database class (engine, session, Base)
│   ├── models.py             # SQLAlchemy models (tabel DB)
│   ├── schemas.py            # Pydantic schemas (request/response)
│   ├── security.py           # JWT, password hashing (Argon2)
│   ├── errors.py             # AppError + exception handlers
│   ├── dependencies.py       # FastAPI dependencies (CurrentUser, DBSession, dll)
│   ├── services.py           # Business logic, helpers
│   ├── integrations.py       # Integrasi eksternal (AI, Storage, FCM)
│   ├── cli.py                # CLI utilities (create-admin)
│   └── routers/
│       ├── auth.py           # Register, login, refresh, logout
│       ├── farms.py          # CRUD lahan
│       ├── reports.py        # Plant reports + AI diagnosis
│       ├── feed.py           # Radar feed + map publik
│       ├── notifications.py  # Notifikasi in-app
│       ├── orders.py         # Order pestisida
│       ├── devices.py        # FCM token device
│       └── dashboard.py      # Admin dashboard (verif + broadcast)
├── alembic/
│   ├── env.py
│   └── versions/
│       └── 0001_initial.py
├── tests/
│   ├── conftest.py
│   └── test_api.py
├── .env.example
├── alembic.ini
├── pyproject.toml
└── README.md
```

### Aliran Data per Request

```
HTTP Request
    ↓
main.py → router terdaftar di app.include_router()
    ↓
dependencies.py → validasi Bearer token → CurrentUser
    ↓
routers/*.py → baca request, validasi schema, panggil services
    ↓
services.py → business logic, query DB, panggil integration
    ↓
integrations.py → hit API eksternal (Gemini, Supabase, Firebase)
    ↓
models.py ↔ database.py → simpan/ambil dari DB
    ↓
schemas.py → response Pydantic → JSON
```

---

## 2. Setup & Menjalankan

### Prasyarat

- Python >= 3.12
- [uv](https://docs.astral.sh/uv/) (package manager, lebih cepat dari pip)

### Mode Demo (development tanpa dependency eksternal)

```bash
cd patra/backend

# 1. Copy env
cp .env.example .env

# 2. Install dependencies (termasuk dev)
uv sync --all-groups

# 3. Jalankan migration
uv run alembic upgrade head

# 4. Jalankan server hot-reload
uv run fastapi dev app/main.py
```

Buka:
- Swagger: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc
- Health: http://127.0.0.1:8000/health

**Login demo:** `admin@radartani.id` / `admin123`

### Mode Production

```bash
APP_ENV=production
SERVICE_MODE=real
DATABASE_URL=postgresql+asyncpg://user:pass@host/db
# + SUPABASE_URL, GEMINI_API_KEY, FIREBASE_*
```

Production otomatis nonaktifkan `/docs`, `/redoc`, dan tolak startup jika provider belum lengkap.

### Perintah Penting

```bash
uv sync                       # Install semua dependencies
uv sync --all-groups          # Termasuk dev dependencies
uv add <package>              # Tambah dependency baru
uv remove <package>           # Hapus dependency
uv run <command>              # Jalankan dalam venv
uv run fastapi dev app/main.py  # Dev server
uv run pytest --cov=app       # Test + coverage
uv run ruff check .           # Linting
```

---

## 3. Pola Arsitektur

### 3.1 App Factory — `main.py`

```python
# app/main.py
def create_app(settings: Settings | None = None) -> FastAPI:
    resolved = settings or get_settings()
    database = Database.create(resolved)

    @asynccontextmanager
    async def lifespan(app):
        # Startup: seed schema SQLite, seed admin demo
        yield
        # Shutdown: dispose DB

    app = FastAPI(lifespan=lifespan, ...)
    app.state.settings = resolved
    app.state.database = database
    app.state.services = create_services(resolved)

    for module in (auth, farms, reports, ...):
        app.include_router(module.router, prefix="/api/v1")
    return app

app = create_app()  # module-level untuk `fastapi dev`
```

**Poin penting:**
- Semua state global lewat `app.state` (settings, database, services)
- Factory pattern biar test bisa inject `Settings` kustom
- `lifespan` menggantikan `@app.on_event`

### 3.2 Settings — `config.py`

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")

    app_env: Literal["development", "test", "production"] = "development"
    service_mode: Literal["demo", "real"] = "demo"
    database_url: str = "sqlite+aiosqlite:///./.data/radar_tani.db"
    jwt_secret: str = "development-only-change-me-at-least-32-bytes"
    # ... semua config di sini

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")

    @model_validator(mode="after")
    def validate_runtime_configuration(self) -> "Settings":
        # Validasi production: JWT wajib diganti, provider wajib lengkap
        ...
```

**Cara akses settings di endpoint:**
```python
@router.get("/example")
async def example(settings: RequestSettings):
    # RequestSettings = Annotated[Settings, Depends(get_request_settings)]
    ...
```

### 3.3 Database — `database.py`

```python
@dataclass(slots=True)
class Database:
    engine: AsyncEngine
    session_factory: async_sessionmaker[AsyncSession]

    @classmethod
    def create(cls, settings: Settings) -> "Database":
        engine = create_async_engine(settings.async_database_url)
        return cls(engine=engine, session_factory=async_sessionmaker(engine))

    async def create_demo_schema(self) -> None:
        # Auto-create tabel untuk SQLite (tanpa migration)
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
```

**Dependency injection session:**
```python
async def get_db(request: Request) -> AsyncIterator[AsyncSession]:
    database: Database = request.app.state.database
    async with database.session_factory() as session:
        yield session

DBSession = Annotated[AsyncSession, Depends(get_db)]
```

### 3.4 Dependency Injection — `dependencies.py`

Semua reusable dependency di sini:

```python
CurrentUser    = Annotated[User, Depends(get_current_user)]
AdminUser      = Annotated[User, Depends(require_admin)]  # role == "cooperative_admin"
DBSession      = Annotated[AsyncSession, Depends(get_db)]
RequestSettings = Annotated[Settings, Depends(get_request_settings)]
```

### 3.5 Services — Service Layer

File `services.py` berisi:
- **Helper functions** — `report_out()`, `farm_out()`, `diagnosis_out()`
- **Business logic** — `validate_image()`, `attach_diagnosis()`, `finish_report_ai()`
- **Utility** — `haversine_km()`, `as_utc()`, `summary_from()`
- **Query helpers** — `find_owned_farm()`, `active_farm()`

**Status constants:**
```python
REPORT_ANALYZING = "Analisis berjalan"
REPORT_PENDING   = "Menunggu verifikasi"
REPORT_VERIFIED  = "Terverifikasi"
REPORT_REJECTED  = "Ditolak"
REPORT_AI_FAILED = "Analisis gagal"
```

---

## 4. Membuat Endpoint Baru

### 4.1 Buat file router

```python
# app/routers/my_feature.py
from fastapi import APIRouter
from app.dependencies import CurrentUser, DBSession
from app.schemas import DataResponse

router = APIRouter(prefix="/my-feature", tags=["My Feature"])


@router.get("", response_model=DataResponse[list[SomeOut]])
async def list_items(
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[list[SomeOut]]:
    # query DB via session
    return DataResponse(data=[...])


@router.post("", response_model=DataResponse[SomeOut], status_code=201)
async def create_item(
    payload: SomeCreate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[SomeOut]:
    item = SomeModel(user_id=user.id, **payload.model_dump())
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return DataResponse(data=some_out(item))
```

### 4.2 Daftarkan di main.py

```python
# app/main.py — di fungsi create_app()
from app.routers import my_feature

for module in (auth, farms, reports, feed, notifications, orders, devices, dashboard, my_feature):
    app.include_router(module.router, prefix=resolved.api_v1_prefix)
```

### 4.3 Aturan Penulisan

| Aturan | Contoh |
|---|---|
| Prefix endpoint | `/api/v1` (set `api_v1_prefix` di Settings) |
| Response wrapper | Selalu pakai `DataResponse[T]` |
| Pagination | `PaginatedData[T]` — field `items`, `page`, `page_size`, `total` |
| Status code CREATE | `status_code=status.HTTP_201_CREATED` |
| Status code DELETE | `status_code=status.HTTP_204_NO_CONTENT, response_class=Response` |
| ID sebagai path param | `UUID` type annotation → auto validation |
| Filter query params | `Annotated[str \| None, Query()] = None` |
| Bearer token | Inject `user: CurrentUser` — otomatis validasi token |

### 4.4 CRUD Pattern (wajib diikuti)

```python
# CREATE
item = Model(user_id=user.id, ...)
session.add(item)
await session.commit()
await session.refresh(item)     # ← penting! biar dapat generated fields

# READ (list + pagination)
total = await session.scalar(select(func.count()).select_from(Model).where(...))
rows = (await session.scalars(
    select(Model).where(...).order_by(...).offset(...).limit(...)
)).all()

# READ (single)
item = await session.get(Model, item_id)
if item is None:
    raise AppError(404, "NOT_FOUND", "...")

# UPDATE
changes = payload.model_dump(exclude_unset=True)
for field, value in changes.items():
    setattr(item, field, value)
await session.commit()
await session.refresh(item)

# DELETE
await session.delete(item)
await session.commit()
```

---

## 5. Membuat Model & Migration

### 5.1 Model Baru

```python
# app/models.py
class MyNewModel(TimestampMixin, Base):
    __tablename__ = "my_new_models"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    value: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    metadata_json: Mapped[dict | None] = mapped_column(JSON)

# TimestampMixin otomatis kasih created_at + updated_at
```

**Panduan kolom:**
| Type | Import | Use case |
|---|---|---|
| `Uuid` | `from sqlalchemy import Uuid` | Primary key UUID |
| `String(N)` | | Teks pendek |
| `Text` | | Teks panjang |
| `Integer` | | Angka |
| `Float` | `from sqlalchemy import Float` | Desimal (koordinat) |
| `Boolean` | | Flag |
| `DateTime(timezone=True)` | | Timestamp |
| `JSON` | | Data fleksibel (raw response AI) |

### 5.2 Migration Database

```bash
# Mode SQLite — auto create schema via create_demo_schema()
# Tapi untuk development tim, tetap pakai migration:

# 1. Buat migration file
uv run alembic revision --autogenerate -m "add my_new_models table"

# 2. Cek hasil di alembic/versions/
# 3. Apply migration
uv run alembic upgrade head

# 4. Rollback
uv run alembic downgrade -1
```

**Alembic auto-deteksi** perubahan dari `Base.metadata` (kumpulan semua model yang di-import di `models.py`).

### 5.3 Konvensi Naming

| Entity | Table name | Contoh |
|---|---|---|
| User | `users` | |
| Farm | `farms` | |
| PlantReport | `plant_reports` | |
| Diagnosis | `diagnoses` | |
| RefreshSession | `refresh_sessions` | |
| UserDevice | `user_devices` | |
| Notification | `notifications` | |
| PesticideOrder | `pesticide_orders` | |

---

## 6. Autentikasi & Authorisasi

### 6.1 Alur Login

```
POST /api/v1/auth/login
  → verify password (Argon2)
  → create access_token (JWT, 1 jam default)
  → create refresh_token (random 48 byte, SHA256 hash di DB)
  → return { access_token, refresh_token, user, expires_in }
```

### 6.2 Access Token (JWT)

```python
# app/security.py
payload = {
    "sub": str(user.id),          # subject = user UUID
    "role": user.role,             # "farmer" | "cooperative_admin"
    "type": "access",              # membedakan dengan token lain
    "iat": now,                    # issued at
    "exp": now + 3600,            # expiry
    "jti": secrets.token_hex(16), # unique ID
}
```

### 6.3 Refresh Token

- Disimpan sebagai `SHA256 hash` di tabel `refresh_sessions`
- Bisa di-revoke (logout → `revoked_at` diisi)
- Saat refresh → token lama di-revoke, token baru dibuat (**rotation**)

### 6.4 Endpoint Berdasarkan Role

| Dependency | Role | Akses |
|---|---|---|
| `CurrentUser` | farmer atau admin | Endpoint petani |
| `AdminUser` | cooperative_admin | Endpoint dashboard |

```python
@router.get("/dashboard/reports")
async def dashboard_reports(
    _admin: AdminUser,   # ← raise 403 kalau bukan admin
    ...
): ...
```

### 6.5 Pasword Hashing

Menggunakan **Argon2** via library `pwdlib`:

```python
password_hash = PasswordHash.recommended()  # → Argon2

def hash_password(password: str) -> str: ...
def verify_password(password: str, encoded_hash: str) -> bool: ...
```

---

## 7. Error Handling

### 7.1 AppError — Custom Exception

```python
from app.errors import AppError

# Pattern
raise AppError(status_code, code, message, details=[])

# Contoh
raise AppError(404, "NOT_FOUND", "Lahan tidak ditemukan.")
raise AppError(409, "EMAIL_ALREADY_REGISTERED", "Email sudah terdaftar.")
raise AppError(
    422, "VALIDATION_ERROR", "latitude dan longitude harus dikirim bersama.",
    [{"field": "coordinate", "message": "Koordinat harus lengkap."}],
)
```

### 7.2 Response Format Error

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Lahan tidak ditemukan.",
    "details": []
  }
}
```

### 7.3 HTTP Status Code yang Dipakai

| Code | Usage |
|---|---|
| 201 | Resource created |
| 204 | Delete success (no body) |
| 400 | Bad request |
| 401 | Token invalid / expired |
| 403 | Bukan milik user / bukan admin |
| 404 | Resource tidak ditemukan |
| 409 | Conflict status (sudah diverifikasi, dll) |
| 413 | Upload terlalu besar |
| 415 | MIME type tidak valid |
| 422 | Validasi request gagal |
| 500 | Internal server error |
| 503 | AI service unavailable |
| 504 | AI timeout |

---

## 8. Integrasi Layanan Eksternal

### 8.1 Service Container Pattern

Semua integrasi dibungkus dalam `ServiceContainer` — pilih implementasi berdasarkan `SERVICE_MODE`:

```python
# app/integrations.py
@dataclass(slots=True)
class ServiceContainer:
    storage: StorageService
    ai: AIService
    notifier: NotificationService

def create_services(settings: Settings) -> ServiceContainer:
    if settings.service_mode == "real":
        return ServiceContainer(
            storage=SupabaseStorage(settings),
            ai=GeminiAI(settings),
            notifier=FirebaseNotifier(settings),
        )
    return ServiceContainer(
        storage=LocalStorage(settings),
        ai=DemoAI(settings),
        notifier=DemoNotifier(),
    )
```

### 8.2 StorageService (Protocol)

```python
class StorageService(Protocol):
    async def upload(self, report_id: UUID, content: bytes, mime_type: str) -> StoredImage: ...
```

| Mode | Implementasi | Behavior |
|---|---|---|
| Demo | `LocalStorage` | Simpan ke `upload_dir` + akses via `public_base_url/media/` |
| Real | `SupabaseStorage` | Upload ke bucket private + return signed URL |

### 8.3 AIService

```python
class AIService(Protocol):
    async def analyze(self, image, mime_type, crop, symptom_notes) -> DiagnosisResult: ...
```

| Mode | Implementasi | Behavior |
|---|---|---|
| Demo | `DemoAI` | Return deterministic, bisa delay via `DEMO_AI_DELAY_SECONDS` |
| Real | `GeminiAI` | Gemini 2.5 Flash + JSON schema response |

### 8.4 NotificationService

```python
class NotificationService(Protocol):
    async def send(self, tokens, title, body, data) -> list[DeliveryResult]: ...
```

| Mode | Implementasi | Behavior |
|---|---|---|
| Demo | `DemoNotifier` | Return sukses semua |
| Real | `FirebaseNotifier` | FCM batch via `messaging.send_each()` |

### 8.5 Cara Akses Service di Endpoint

```python
@router.post("/plant-reports")
async def create_plant_report(
    request: Request,
    ...
) -> ...:
    services = request.app.state.services
    stored = await services.storage.upload(report_id, content, mime_type)
    result = await services.ai.analyze(...)
    await services.notifier.send(tokens, ...)
```

---

## 9. Testing

### 9.1 Setup Test

```python
# tests/conftest.py
@pytest.fixture
def client(tmp_path) -> Iterator[TestClient]:
    settings = Settings(
        _env_file=None,
        app_env="test",
        service_mode="demo",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'test.db'}",
        upload_dir=tmp_path / "uploads",
        jwt_secret="test-secret-with-enough-entropy-123456",
        ...
    )
    with TestClient(create_app(settings)) as test_client:
        yield test_client
```

**Penting:** Test selalu pakai `create_app(settings)` — inject setting kustom, bukan module-level `app`.

### 9.2 Pattern Test API

```python
def test_register_and_login(client):
    # Register
    res = client.post("/api/v1/auth/register", json={
        "name": "Petani", "email": "a@b.com",
        "password": "rahasia123",
    })
    assert res.status_code == 201
    data = res.json()["data"]
    token = data["access_token"]
    user_id = data["user"]["id"]

    # Gunakan token untuk request selanjutnya
    res = client.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
```

### 9.3 Menjalankan

```bash
uv run pytest                   # Semua test
uv run pytest -v                # Verbose
uv run pytest --cov=app         # Coverage
uv run pytest tests/test_api.py -k "test_register"  # Filter
```

---

## 10. CLI Tools

```bash
# Buat / update admin koperasi
uv run python -m app.cli create-admin \
  --email admin@koperasi.id \
  --password 'strong-pass-123' \
  --name 'Admin Koperasi' \
  --cooperative-name 'Koperasi Sejahtera'
```

Berguna untuk seeding admin tanpa perlu register lewat API.

---

## 11. Production Checklist

| Item | Config |
|---|---|
| Mode | `APP_ENV=production` + `SERVICE_MODE=real` |
| Database | `DATABASE_URL=postgresql+asyncpg://...` |
| JWT Secret | Minimal 32 byte, random |
| Photo storage | `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` |
| AI Analysis | `GEMINI_API_KEY` |
| Push notification | `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` |
| Base URL | `PUBLIC_BASE_URL` (untuk signed URL / media URL) |
| Swagger | Otomatis disabled saat production |
| Validation startup | Tolak startup jika provider tidak lengkap |

---

## 12. Daftar Lengkap Endpoint

Semua endpoint diprefix `/api/v1` — kecuali `/health` yang tersedia di kedua path.

### Authentication
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| POST | `/auth/register` | - | Daftar petani baru |
| POST | `/auth/login` | - | Login, dapat access + refresh token |
| POST | `/auth/refresh` | - | Rotate refresh token |
| POST | `/auth/logout` | User | Revoke semua refresh session |
| GET | `/me` | User | Profile user saat ini |

### Farms (Lahan)
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/farms` | User | List lahan (paginated) |
| POST | `/farms` | User | Tambah lahan baru |
| PATCH | `/farms/{id}` | User | Edit lahan |
| DELETE | `/farms/{id}` | User | Hapus lahan (gagal jika masih dipakai report) |

### Plant Reports (Laporan Tanaman)
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| POST | `/plant-reports` | User | Upload foto → AI diagnosis → report |
| GET | `/plant-reports` | User | List report sendiri (filter by category/status/farm) |
| GET | `/plant-reports/{id}` | User | Detail report sendiri |
| PATCH | `/plant-reports/{id}` | User | Edit report (sebelum diverifikasi) |
| DELETE | `/plant-reports/{id}` | User | Hapus report (sebelum diverifikasi) |
| POST | `/plant-diagnoses` | User | AI diagnosis standalone (tanpa report) |

### Radar Feed & Map
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/radar-feed/reports` | User | Report publik dalam radius (default 10 km) |
| GET | `/radar-feed/reports/{id}` | User | Detail laporan publik |
| GET | `/map/reports` | User | Report untuk peta (filter bounding box) |

### Dashboard Admin (role: cooperative_admin)
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/dashboard/reports` | Admin | Semua report (filter by status/kategori) |
| GET | `/dashboard/map-reports` | Admin | Semua report untuk peta dashboard |
| POST | `/dashboard/reports/{id}/verify-broadcast` | Admin | Verifikasi + broadcast notifikasi ke radius |
| POST | `/dashboard/reports/{id}/reject` | Admin | Tolak report dengan alasan |

### Notifications
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/notifications` | User | List notifikasi |
| PATCH | `/notifications/{id}/read` | User | Tandai satu notifikasi sudah dibaca |
| PATCH | `/notifications/read-all` | User | Tandai semua sudah dibaca |

### Pesticide Orders
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/pesticide-orders` | User | List order pestisida |
| POST | `/pesticide-orders` | User | Buat order pestisida |

### Devices (FCM)
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| POST | `/devices` | User | Daftar / update FCM token device |

### Health
| Method | Path | Auth | Fungsi |
|---|---|---|---|
| GET | `/health` | - | Health check |
| GET | `/api/v1/health` | - | Health check (sama, hidden dari schema) |

---

## Quick Reference: Flow Lengkap Aplikasi

```
Register/Login
  ↓
Buat Farm (lahan dengan koordinat + tanaman)
  ↓
Upload foto tanaman → create PlantReport (multipart)
  ├── Simpan gambar ke storage (local/Supabase)
  ├── Panggil AI analyze (Gemini/Demo)
  │   ├── Sukses → attach Diagnosis → status "Menunggu verifikasi"
  │   ├── Timeout → background task lanjut
  │   └── Gagal → status "Analisis gagal"
  └── Report masuk ke feed publik (jika publish_to_feed=true)
  ↓
Admin lihat di dashboard → Verify (dengan broadcast radius)
  ├── Status jadi "Terverifikasi"
  ├── Notifikasi FCM ke petani sekitar
  └── Notifikasi in-app tersimpan
  ↓
Petani lihat notifikasi → Order pestisida (pilihan)
```
