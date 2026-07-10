# Radar Tani Backend

Backend FastAPI untuk aplikasi Radar Tani Desa. Semua endpoint mobile memakai prefix
`/api/v1`; health check deployment juga tersedia di `/health`.

## Menjalankan mode demo

Mode demo memakai SQLite, penyimpanan foto lokal, analisis AI deterministik, dan simulasi FCM.
Data SQLite serta foto disimpan di `backend/.data/` dan tidak masuk Git.

```bash
cd backend
cp .env.example .env
uv sync --all-groups
uv run alembic upgrade head
uv run fastapi dev app/main.py
```

Buka:

- Swagger: <http://127.0.0.1:8000/docs>
- ReDoc: <http://127.0.0.1:8000/redoc>
- Health: <http://127.0.0.1:8000/health>

Admin demo dibuat otomatis dari `DEMO_ADMIN_EMAIL` dan `DEMO_ADMIN_PASSWORD`.
Nilai default `.env.example` adalah `admin@radartani.id` / `admin123` dan hanya boleh
dipakai untuk development lokal.

## Production

Set `APP_ENV=production`, `SERVICE_MODE=real`, PostgreSQL `DATABASE_URL`, serta seluruh
credential Supabase, Gemini, dan Firebase pada environment deployment. Mode production
menonaktifkan `/docs`, `/redoc`, dan `/openapi.json`, serta menolak startup bila konfigurasi
provider belum lengkap.

Foto disimpan ke bucket private Supabase dan API mengembalikan signed URL. PostGIS migration
membuat generated `geography(Point, 4326)` serta GIST index untuk lahan dan laporan.

Untuk membuat atau merotasi admin koperasi:

```bash
uv run python -m app.cli create-admin \
  --email admin@example.com \
  --password 'replace-with-a-strong-password' \
  --name 'Admin Koperasi' \
  --cooperative-name 'Koperasi Sukamaju'
```

## Quality checks

```bash
uv run ruff check .
uv run pytest --cov=app
```

Kontrak utama berada di `../docs/api-contract-fastapi.md`.
