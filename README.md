# 🌾 Radar Tani Desa

> **Deteksi dini penyakit tanaman berbasis AI, terhubung langsung dengan koperasi dan petani sekitar.**

Radar Tani Desa adalah platform mobile-first yang memberdayakan petani Indonesia untuk mendeteksi, melaporkan, dan menyebarkan peringatan dini penyakit tanaman secara real-time. Dengan kecerdasan buatan (Google Gemini), laporan petani diverifikasi oleh koperasi desa dan disiarkan ke petani di sekitar radius — menciptakan jaringan pertahanan komunitas terhadap wabah hama dan penyakit.

---

## ✨ Kenapa Radar Tani?

Setiap tahun, ribuan hektar lahan pertanian Indonesia rusak akibat keterlambatan deteksi penyakit. Petani sering kali tidak memiliki akses cepat ke ahli pertanian, dan informasi wabah menyebar lambat.

**Radar Tani menyelesaikan ini dengan:**

- 📸 **Foto → Diagnosis AI dalam hitungan detik** — Cukup foto daun yang bermasalah, AI memberikan perkiraan penyakit, tingkat keyakinan, gejala, dan rekomendasi penanganan awal.
- 🗺️ **Peta interaktif laporan sekitar** — Lihat laporan penyakit tanaman yang terverifikasi di sekitar lokasi Anda.
- 🔔 **Peringatan dini push notification** — Koperasi memverifikasi laporan dan menyebarkan peringatan ke petani dalam radius tertentu.
- 🏪 **Pemesanan pestisida terintegrasi** — Langsung pesan pestisida yang direkomendasikan melalui koperasi.
- 🤝 **Kolaborasi petani & koperasi** — Jembatan komunikasi langsung antara petani di lapangan dan admin koperasi desa.

---

## 🏗️ Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│                    RadarTaniMobile (iOS)                     │
│  SwiftUI · MVVM · MapKit · AVFoundation · CoreLocation      │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST API (JSON + Multipart)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Radar Tani API (FastAPI)                   │
│  SQLAlchemy Async · JWT + Argon2 · Pydantic v2              │
├──────────┬──────────┬───────────────────────────────────────┤
│ Google   │ Supabase │ Firebase Cloud Messaging              │
│ Gemini   │ Storage  │ (Push Notifications)                  │
│ AI       │          │                                       │
└──────────┴──────────┴───────────────────────────────────────┘
                           │
              PostgreSQL / SQLite (dev)
```

---

## 📱 Fitur Aplikasi Mobile

### 🏠 Home
Dashboard personal petani dengan ringkasan lahan aktif, laporan terbaru, dan notifikasi penting.

### 📷 Lapor (PlantScan)
Alur pelaporan lengkap:
1. Pilih lahan aktif
2. Ambil foto dari kamera atau galeri
3. Isi informasi gejala (kategori, judul, deskripsi)
4. AI menganalisis foto dan memberikan diagnosis awal
5. Konfirmasi dan kirim laporan ke koperasi

### 🗺️ Peta (Map)
Tampilan peta interaktif menggunakan MapKit yang menampilkan laporan penyakit tanaman terverifikasi di sekitar lokasi petani. Filter berdasarkan bounding box untuk performa optimal.

### 📡 Radar Feed
Feed publik berisi laporan tanaman yang sudah diverifikasi koperasi dalam radius tertentu (default 10 km). Setiap laporan menampilkan foto, diagnosis AI, confidence score, dan lokasi.

### 🔔 Notifikasi
Push notification real-time ketika koperasi memverifikasi laporan penyakit di sekitar lahan petani. Didukung oleh Firebase Cloud Messaging.

### 🌿 Manajemen Lahan (Farms)
CRUD lengkap untuk lahan pertanian: nama, jenis tanaman, lokasi, dan koordinat GPS. Satu petani dapat mengelola banyak lahan.

### 👤 Profil (Profile)
Manajemen profil petani termasuk nama, email, dan nama koperasi.

### 🛒 Pesanan Pestisida (Orders)
Petani dapat memesan pestisida berdasarkan rekomendasi dari hasil diagnosis AI.

---

## 🖥️ Fitur Dashboard Koperasi

Admin koperasi memiliki akses ke dashboard khusus:

| Fitur | Deskripsi |
|-------|-----------|
| **Daftar Laporan** | Lihat semua laporan masuk dengan filter status dan kategori |
| **Peta Dashboard** | Visualisasi semua laporan pada peta untuk analisis sebaran |
| **Verifikasi & Siarkan** | Verifikasi laporan valid dan broadcast peringatan ke petani sekitar |
| **Tolak Laporan** | Tolak laporan tidak valid dengan alasan penolakan |

---

## 🔄 Alur Kerja Laporan

```
Petani foto tanaman → AI diagnosis → Kirim laporan
                                         │
                                         ▼
                              Koperasi menerima laporan
                                         │
                          ┌──────────────┼──────────────┐
                          ▼                             ▼
                     ✅ Verifikasi                 ❌ Tolak
                          │                             │
                          ▼                             ▼
              Broadcast notifikasi             Petani lihat alasan
              ke petani sekitar                penolakan di riwayat
                          │
                          ▼
              Petani sekitar menerima
              peringatan dini + opsi
              pesan pestisida
```

### Status Laporan

| Status | Arti |
|--------|------|
| `Analisis berjalan` | AI sedang memproses foto |
| `Menunggu verifikasi` | Laporan masuk ke koperasi, menunggu review |
| `Terverifikasi` | Laporan valid, peringatan disebarkan |
| `Ditolak` | Laporan tidak valid, ditolak koperasi |
| `Analisis gagal` | AI tidak dapat menganalisis foto |

---

## 🛠️ Tech Stack

### Mobile (iOS)
| Teknologi | Penggunaan |
|-----------|------------|
| **SwiftUI** | UI framework declarative |
| **MVVM** | Arsitektur aplikasi |
| **MapKit** | Peta interaktif |
| **AVFoundation** | Akses kamera |
| **CoreLocation** | GPS dan geolokasi |
| **URLSession** | Networking layer |

### Backend
| Teknologi | Penggunaan |
|-----------|------------|
| **FastAPI** | REST API framework |
| **SQLAlchemy 2.0 (Async)** | ORM dan database abstraction |
| **Alembic** | Database migration |
| **Pydantic v2** | Validasi dan serialisasi data |
| **JWT (PyJWT)** | Authentication tokens |
| **Argon2 (pwdlib)** | Password hashing |
| **Google Gemini** | AI plant disease analysis |
| **Supabase Storage** | Cloud image storage (production) |
| **Firebase Admin** | Push notifications (FCM) |
| **PostgreSQL** | Production database |
| **SQLite** | Development database |

---

## 🚀 Quick Start

### Prasyarat

- **iOS:** Xcode 16+, iOS 17+ deployment target
- **Backend:** Python 3.12+, [uv](https://docs.astral.sh/uv/) package manager

### Menjalankan Backend (Mode Demo)

Mode demo menggunakan SQLite, penyimpanan foto lokal, dan AI simulasi — cocok untuk development dan testing.

```bash
cd backend
cp .env.example .env
uv sync --all-groups
uv run alembic upgrade head
uv run fastapi dev app/main.py
```

Server akan berjalan di `http://127.0.0.1:8000`.

| URL | Deskripsi |
|-----|-----------|
| [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) | Swagger UI |
| [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc) | ReDoc |
| [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health) | Health check |

Admin demo otomatis dibuat dengan kredensial default:
- **Email:** `admin@radartani.id`
- **Password:** `admin123`

### Menjalankan Aplikasi iOS

1. Buka `RadarTaniMobile.xcodeproj` di Xcode
2. Pilih simulator atau device target (iOS 17+)
3. Build & Run (`Cmd + R`)

> **Catatan:** Secara default, aplikasi terhubung ke `https://patra-api.kamil.my.id/api/v1`. Ubah `AppConfig.apiBaseURL` di `AppConstants.swift` untuk mengarahkan ke server lokal.

---

## ⚙️ Konfigurasi Environment

### Mode Demo (Development)

```env
APP_ENV=development
SERVICE_MODE=demo
DATABASE_URL=sqlite+aiosqlite:///./.data/radar_tani.db
JWT_SECRET=development-only-change-me-at-least-32-bytes
```

### Mode Production

```env
APP_ENV=production
SERVICE_MODE=real
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/radartani
JWT_SECRET=<minimal-32-byte-random-string>

# Supabase Storage
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
SUPABASE_BUCKET_NAME=plant-reports

# Google Gemini AI
GEMINI_API_KEY=<gemini-api-key>
GEMINI_MODEL=gemini-2.5-flash

# Firebase Cloud Messaging
FIREBASE_PROJECT_ID=<project-id>
FIREBASE_CLIENT_EMAIL=<client-email>
FIREBASE_PRIVATE_KEY=<private-key>
```

---

## 📡 API Endpoints

Semua endpoint berada di bawah prefix `/api/v1`.

### Authentication
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/auth/register` | — | Registrasi petani baru |
| POST | `/auth/login` | — | Login (access + refresh token) |
| POST | `/auth/refresh` | — | Rotasi refresh token |
| POST | `/auth/logout` | ✅ | Revokasi semua refresh session |
| GET | `/me` | ✅ | Profil user saat ini |

### Farms (Lahan)
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/farms` | ✅ | Daftar lahan (paginated) |
| POST | `/farms` | ✅ | Tambah lahan baru |
| PATCH | `/farms/{id}` | ✅ | Edit lahan |
| DELETE | `/farms/{id}` | ✅ | Hapus lahan |

### Plant Reports (Laporan Tanaman)
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/plant-reports` | ✅ | Upload foto + AI diagnosis + buat laporan |
| GET | `/plant-reports` | ✅ | Daftar laporan sendiri (filter category/status/farm) |
| GET | `/plant-reports/{id}` | ✅ | Detail laporan |
| PATCH | `/plant-reports/{id}` | ✅ | Edit laporan (sebelum verifikasi) |
| DELETE | `/plant-reports/{id}` | ✅ | Hapus laporan (sebelum verifikasi) |
| POST | `/plant-diagnoses` | ✅ | AI diagnosis standalone (tanpa buat laporan) |

### Radar Feed & Map
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/radar-feed/reports` | ✅ | Laporan publik dalam radius |
| GET | `/radar-feed/reports/{id}` | ✅ | Detail laporan publik |
| GET | `/map/reports` | ✅ | Laporan untuk peta (bounding box filter) |

### Dashboard Koperasi (Admin)
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/dashboard/reports` | 🔑 Admin | Semua laporan (filter status/kategori) |
| GET | `/dashboard/map-reports` | 🔑 Admin | Laporan untuk peta dashboard |
| POST | `/dashboard/reports/{id}/verify-broadcast` | 🔑 Admin | Verifikasi + broadcast notifikasi |
| POST | `/dashboard/reports/{id}/reject` | 🔑 Admin | Tolak laporan dengan alasan |

### Notifications
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/notifications` | ✅ | Daftar notifikasi |
| PATCH | `/notifications/{id}/read` | ✅ | Tandai notifikasi dibaca |
| PATCH | `/notifications/read-all` | ✅ | Tandai semua notifikasi dibaca |

### Pesticide Orders
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/pesticide-orders` | ✅ | Daftar pesanan pestisida |
| POST | `/pesticide-orders` | ✅ | Buat pesanan pestisida baru |

### Devices (FCM)
| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/devices` | ✅ | Daftarkan/update FCM token device |

---

## 🧪 Testing & Quality

```bash
cd backend

# Linting
uv run ruff check .

# Testing dengan coverage
uv run pytest --cov=app

# Format code
uv run ruff format .
```

---

## 📂 Struktur Proyek

```
Radartani2.0/
├── RadarTaniMobile/              # iOS App (SwiftUI)
│   ├── App/                      # Entry point, router, environment
│   ├── Core/                     # Networking, Auth, Location, Image, Notification
│   ├── DesignSystem/             # Colors, Typography, Components, Spacing
│   ├── Features/                 # Feature modules (MVVM)
│   │   ├── Auth/                 # Login & Register
│   │   ├── Farms/                # Manajemen lahan
│   │   ├── Home/                 # Dashboard home
│   │   ├── Map/                  # Peta laporan
│   │   ├── Notifications/        # Notifikasi
│   │   ├── PlantScan/            # Scan & lapor tanaman
│   │   ├── Profile/              # Profil user
│   │   └── RadarFeed/            # Feed laporan publik
│   ├── Models/                   # Data models (Codable)
│   ├── Services/                 # API service layer
│   └── Resources/                # Assets, images, icons
│
├── backend/                      # FastAPI Backend
│   ├── app/
│   │   ├── main.py               # Entry point, create_app()
│   │   ├── config.py             # Settings (pydantic-settings)
│   │   ├── database.py           # Database engine & session
│   │   ├── models.py             # SQLAlchemy models
│   │   ├── schemas.py            # Pydantic schemas
│   │   ├── security.py           # JWT, Argon2 hashing
│   │   ├── errors.py             # Error handling
│   │   ├── dependencies.py       # FastAPI dependencies
│   │   ├── services.py           # Business logic
│   │   ├── integrations.py       # AI, Storage, FCM providers
│   │   ├── cli.py                # CLI tools (create-admin)
│   │   └── routers/              # API route handlers
│   │       ├── auth.py           # Authentication
│   │       ├── farms.py          # Farm CRUD
│   │       ├── reports.py        # Plant reports + AI
│   │       ├── feed.py           # Radar feed & map
│   │       ├── notifications.py  # In-app notifications
│   │       ├── orders.py         # Pesticide orders
│   │       ├── devices.py        # FCM device tokens
│   │       └── dashboard.py      # Admin dashboard
│   ├── alembic/                  # Database migrations
│   ├── tests/                    # Pytest test suite
│   └── pyproject.toml            # Python project config
│
└── docs/                         # Documentation
    ├── api-contract-fastapi.md   # API contract specification
    ├── backend-development-guide.md  # Backend dev guide
    └── user-flow-lapor-tanaman-penyakit.md  # User flow documentation
```

---

## 🤖 AI Diagnosis

Radar Tani menggunakan **Google Gemini** untuk analisis foto tanaman:

- **Input:** Foto tanaman (JPEG, PNG, HEIC, maks 10 MB) + metadata lahan
- **Output:** Perkiraan penyakit, confidence score (0-100), gejala terdeteksi, rekomendasi penanganan, dan disclaimer
- **Timeout:** 10 detik untuk analisis sinkron; jika melebihi, analisis dilanjutkan sebagai background task
- **Disclaimer:** Hasil AI adalah perkiraan awal dan bukan pengganti pemeriksaan langsung oleh penyuluh atau ahli pertanian

Mode demo menyediakan `DemoAI` yang mengembalikan diagnosis deterministik untuk testing tanpa API key.

---

## 🔐 Keamanan

- **Password hashing:** Argon2id (via pwdlib)
- **Authentication:** JWT Bearer token dengan access + refresh token pair
- **Refresh token rotation:** Setiap refresh menghasilkan token baru dan merevokasi yang lama
- **Upload validation:** Validasi MIME type dan ukuran file di server
- **Production hardening:** Swagger/ReDoc dimatikan, validasi konfigurasi ketat, JWT secret wajib diganti

---

## 📄 Lisensi

Proyek ini dikembangkan untuk mendukung petani Indonesia melalui teknologi.

---

## 👨‍💻 Kontributor

Dikembangkan dengan ❤️ untuk pertanian Indonesia.

---

<p align="center">
  <strong>Radar Tani Desa</strong> — Deteksi Dini, Lindungi Panen, Selamatkan Petani.
</p>
