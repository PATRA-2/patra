# RadarTaniMobile API Contract for FastAPI

Version: `v1`  
Target backend: FastAPI  
Client: RadarTaniMobile iOS app  
Base URL local: `https://api.radar-tani.local/api/v1`

## 1. Tujuan

Dokumen ini menjadi kontrak awal antara aplikasi RadarTaniMobile dan backend FastAPI. Scope utama backend adalah:

- Auth email + password untuk petani.
- Manajemen profil petani dan lahan.
- Upload foto gejala tanaman dari tab `Lapor`.
- Analisis awal AI untuk penyakit/hama tanaman.
- Publikasi laporan ke Radar Feed dan peta laporan sekitar.
- Riwayat laporan, notifikasi, dan pesanan pestisida dasar.

Kontrak ini sengaja mengikuti model yang sudah muncul di iOS app: `User`, `Farm`, `AIPlantDiagnosis`, `ReportHistoryItem`, `NotificationItem`, `Coordinate`, dan `PesticideOrder`.

## 2. Konvensi Umum

### Transport

- Semua endpoint berada di bawah prefix `/api/v1`.
- Semua request dan response menggunakan `application/json`, kecuali endpoint upload foto yang menggunakan `multipart/form-data`.
- Semua timestamp menggunakan ISO 8601 UTC, contoh: `2026-07-10T08:30:00Z`.
- Semua ID memakai UUID string.
- Field JSON menggunakan `snake_case`.
- Response list wajib mendukung pagination dengan `page`, `page_size`, `total`, dan `items`.

### FastAPI Compatibility Notes

- Gunakan Pydantic response model untuk setiap endpoint agar OpenAPI otomatis lengkap dan output terfilter sesuai schema.
- Endpoint upload foto memakai `UploadFile` + `File(...)`.
- Field metadata upload foto memakai `Form(...)`.
- Untuk menerima upload file/form-data di FastAPI, backend perlu dependency `python-multipart`.
- Auth menggunakan bearer token, sehingga OpenAPI FastAPI dapat menampilkan security scheme via `OAuth2PasswordBearer` atau HTTP bearer dependency.
- Dokumentasi otomatis diharapkan aktif di `/docs` dan `/redoc` untuk environment non-production.

Referensi FastAPI:

- Response model: <https://fastapi.tiangolo.com/tutorial/response-model/>
- Bearer auth: <https://fastapi.tiangolo.com/tutorial/security/first-steps/>
- Upload file: <https://fastapi.tiangolo.com/tutorial/request-files/>
- Form + file upload: <https://fastapi.tiangolo.com/tutorial/request-forms-and-files/>
- Error handling: <https://fastapi.tiangolo.com/tutorial/handling-errors/>
- Status code: <https://fastapi.tiangolo.com/tutorial/response-status-code/>

## 3. Authentication

Semua endpoint selain health check, login, dan register membutuhkan header:

```http
Authorization: Bearer <access_token>
```

Token type: `Bearer`  
Access token format: JWT disarankan, tetapi mobile client hanya menganggap token sebagai opaque string.  
Refresh token: disimpan di client hanya jika backend memilih strategi refresh-token.

## 4. Standard Response Shapes

### Success Object

```json
{
  "data": {}
}
```

### Success List

```json
{
  "data": {
    "items": [],
    "page": 1,
    "page_size": 20,
    "total": 0
  }
}
```

### Error Object

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request tidak valid.",
    "details": [
      {
        "field": "email",
        "message": "Email wajib diisi."
      }
    ]
  }
}
```

### Common Error Codes

| HTTP | Code | Kapan Dipakai |
| --- | --- | --- |
| `400` | `BAD_REQUEST` | Request syntactically valid tapi tidak bisa diproses. |
| `401` | `UNAUTHORIZED` | Token tidak ada, expired, atau invalid. |
| `403` | `FORBIDDEN` | User valid tetapi tidak punya akses ke resource. |
| `404` | `NOT_FOUND` | Resource tidak ditemukan. |
| `409` | `CONFLICT` | Email sudah dipakai atau status resource tidak sesuai. |
| `413` | `PAYLOAD_TOO_LARGE` | Foto melebihi batas upload. |
| `415` | `UNSUPPORTED_MEDIA_TYPE` | File bukan `image/jpeg`, `image/png`, atau `image/heic`. |
| `422` | `VALIDATION_ERROR` | Field request gagal validasi. |
| `429` | `RATE_LIMITED` | Terlalu banyak request. |
| `500` | `INTERNAL_SERVER_ERROR` | Error tidak terduga di server. |

## 5. Shared Schemas

### User

```json
{
  "id": "a2e4a32c-7a9d-4d77-9b8a-5728d0f2e8f1",
  "name": "Petani RTD",
  "email": "petani@radartani.id",
  "cooperative_name": "Koperasi Desa Sukamaju"
}
```

### Coordinate

```json
{
  "latitude": -7.7956,
  "longitude": 110.3695
}
```

### Farm

```json
{
  "id": "f4d3665e-3ad9-4aa8-9511-645c308755b2",
  "name": "Sawah Utara",
  "crop": "Cabai",
  "location": "Desa Sukamaju",
  "coordinate": {
    "latitude": -7.7956,
    "longitude": 110.3695
  },
  "is_active": true,
  "created_at": "2026-07-10T08:30:00Z",
  "updated_at": "2026-07-10T08:30:00Z"
}
```

### Plant Report Category

Nilai yang diterima client:

- `Penyakit`
- `Hama`
- `Lainnya`

Backend boleh menyimpan canonical enum internal seperti `disease`, `pest`, `other`, tetapi response ke mobile harus tetap mengirim label di atas selama UI masih memakai label tersebut.

### AIPlantDiagnosis

```json
{
  "id": "9e7d3f8e-18c9-46f4-b68d-dc0b4a65a152",
  "prediction": "Kemungkinan penyakit bercak daun",
  "confidence": 82,
  "symptoms": "Daun menunjukkan bercak cokelat pada beberapa area.",
  "recommendation": "Pisahkan tanaman terdampak, pangkas daun rusak, dan konsultasikan pestisida sesuai rekomendasi penyuluh.",
  "created_at": "2026-07-10T08:32:00Z"
}
```

`confidence` adalah integer `0...100`.

### PlantReport

```json
{
  "id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
  "title": "Daun cabai mengeriting",
  "category": "Hama",
  "summary": "Gejala daun mengeriting muncul di beberapa petak.",
  "description": "Daun cabai mengeriting sejak dua hari lalu.",
  "status": "Menunggu verifikasi",
  "farm_id": "f4d3665e-3ad9-4aa8-9511-645c308755b2",
  "farm_name": "Sawah Utara",
  "coordinate": {
    "latitude": -7.7956,
    "longitude": 110.3695
  },
  "image_url": "https://cdn.radar-tani.local/reports/d3c886c1.jpg",
  "diagnosis": {
    "id": "9e7d3f8e-18c9-46f4-b68d-dc0b4a65a152",
    "prediction": "Kemungkinan serangan trips",
    "confidence": 76,
    "symptoms": "Daun mengeriting dan beberapa pucuk tampak rusak.",
    "recommendation": "Pantau 2-3 hari, gunakan perangkap kuning, dan hubungi penyuluh bila menyebar.",
    "created_at": "2026-07-10T08:32:00Z"
  },
  "created_at": "2026-07-10T08:31:00Z",
  "updated_at": "2026-07-10T08:32:00Z"
}
```

### Notification

```json
{
  "id": "30df599c-4255-4419-ae92-4109171dd840",
  "title": "Laporan diverifikasi",
  "message": "Laporan Daun cabai mengeriting sudah masuk Radar Feed.",
  "related_report_id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
  "is_read": false,
  "created_at": "2026-07-10T09:00:00Z"
}
```

### PesticideOrder

```json
{
  "id": "1f1b5ddc-cf4e-403b-8d10-a84960bf2975",
  "product_name": "Pestisida Nabati",
  "quantity": 2,
  "status": "Diproses",
  "created_at": "2026-07-10T09:10:00Z"
}
```

## 6. Endpoints

## 6.1 Health

### GET `/health`

Public endpoint untuk monitoring.

Response `200`:

```json
{
  "data": {
    "status": "ok",
    "service": "radar-tani-api",
    "version": "1.0.0"
  }
}
```

## 6.2 Auth

### POST `/auth/register`

Mendaftarkan petani baru.

Request:

```json
{
  "name": "Petani RTD",
  "email": "petani@radartani.id",
  "password": "secret123",
  "cooperative_name": "Koperasi Desa Sukamaju",
  "farm_location": "Desa Sukamaju"
}
```

Validation:

- `name`: required, min 2 chars.
- `email`: required, valid email, unique.
- `password`: required, min 6 chars.
- `cooperative_name`: optional.
- `farm_location`: optional.

Response `201`:

```json
{
  "data": {
    "user": {
      "id": "a2e4a32c-7a9d-4d77-9b8a-5728d0f2e8f1",
      "name": "Petani RTD",
      "email": "petani@radartani.id",
      "cooperative_name": "Koperasi Desa Sukamaju"
    },
    "access_token": "jwt-or-opaque-token",
    "refresh_token": "refresh-token",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

Errors:

- `409 EMAIL_ALREADY_REGISTERED`
- `422 VALIDATION_ERROR`

### POST `/auth/login`

Login email + password.

Request:

```json
{
  "email": "petani@radartani.id",
  "password": "secret123"
}
```

Response `200`:

```json
{
  "data": {
    "user": {
      "id": "a2e4a32c-7a9d-4d77-9b8a-5728d0f2e8f1",
      "name": "Petani RTD",
      "email": "petani@radartani.id",
      "cooperative_name": "Koperasi Desa Sukamaju"
    },
    "access_token": "jwt-or-opaque-token",
    "refresh_token": "refresh-token",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

Errors:

- `401 INVALID_CREDENTIALS`
- `422 VALIDATION_ERROR`

### POST `/auth/refresh`

Request:

```json
{
  "refresh_token": "refresh-token"
}
```

Response `200`:

```json
{
  "data": {
    "access_token": "new-access-token",
    "refresh_token": "new-refresh-token",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

### POST `/auth/logout`

Requires auth. Invalidasi refresh token/session aktif.

Response `204`: no body.

### GET `/me`

Requires auth.

Response `200`:

```json
{
  "data": {
    "id": "a2e4a32c-7a9d-4d77-9b8a-5728d0f2e8f1",
    "name": "Petani RTD",
    "email": "petani@radartani.id",
    "cooperative_name": "Koperasi Desa Sukamaju"
  }
}
```

## 6.3 Farms

### GET `/farms`

Requires auth. Mengambil daftar lahan milik user.

Query:

| Name | Type | Default |
| --- | --- | --- |
| `page` | integer | `1` |
| `page_size` | integer | `20` |

Response `200`:

```json
{
  "data": {
    "items": [
      {
        "id": "f4d3665e-3ad9-4aa8-9511-645c308755b2",
        "name": "Sawah Utara",
        "crop": "Cabai",
        "location": "Desa Sukamaju",
        "coordinate": {
          "latitude": -7.7956,
          "longitude": 110.3695
        },
        "is_active": true,
        "created_at": "2026-07-10T08:30:00Z",
        "updated_at": "2026-07-10T08:30:00Z"
      }
    ],
    "page": 1,
    "page_size": 20,
    "total": 1
  }
}
```

### POST `/farms`

Requires auth. Membuat lahan baru.

Request:

```json
{
  "name": "Sawah Utara",
  "crop": "Cabai",
  "location": "Desa Sukamaju",
  "coordinate": {
    "latitude": -7.7956,
    "longitude": 110.3695
  },
  "is_active": true
}
```

Response `201`: `Farm`.

### PATCH `/farms/{farm_id}`

Requires auth. Update sebagian data lahan.

Request:

```json
{
  "name": "Sawah Barat",
  "crop": "Padi",
  "location": "Desa Sukamaju",
  "coordinate": {
    "latitude": -7.795,
    "longitude": 110.37
  },
  "is_active": false
}
```

Response `200`: `Farm`.

### DELETE `/farms/{farm_id}`

Requires auth.

Response `204`: no body.

## 6.4 Plant Reports

### POST `/plant-reports`

Requires auth. Endpoint utama untuk tab `Lapor`: upload foto tanaman + metadata laporan.

Content-Type: `multipart/form-data`

Form fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `image` | file | yes | `image/jpeg`, `image/png`, atau `image/heic`. Max 10 MB. |
| `title` | string | yes | Min 3 chars. |
| `category` | string | yes | `Penyakit`, `Hama`, atau `Lainnya`. |
| `description` | string | no | Gejala dan konteks dari petani. |
| `farm_id` | UUID string | no | Jika kosong, backend boleh pakai lahan aktif/default user. |
| `latitude` | decimal | no | Dikirim jika lokasi tersedia. |
| `longitude` | decimal | no | Dikirim jika lokasi tersedia. |
| `publish_to_feed` | boolean | no | Default `true`. |

FastAPI handler shape yang diharapkan:

```python
async def create_plant_report(
    image: UploadFile = File(...),
    title: str = Form(...),
    category: str = Form(...),
    description: str | None = Form(default=None),
    farm_id: UUID | None = Form(default=None),
    latitude: float | None = Form(default=None),
    longitude: float | None = Form(default=None),
    publish_to_feed: bool = Form(default=True),
):
    ...
```

Response `201`:

```json
{
  "data": {
    "id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
    "title": "Daun cabai mengeriting",
    "category": "Hama",
    "summary": "Gejala daun mengeriting muncul di beberapa petak.",
    "description": "Daun cabai mengeriting sejak dua hari lalu.",
    "status": "Menunggu verifikasi",
    "farm_id": "f4d3665e-3ad9-4aa8-9511-645c308755b2",
    "farm_name": "Sawah Utara",
    "coordinate": {
      "latitude": -7.7956,
      "longitude": 110.3695
    },
    "image_url": "https://cdn.radar-tani.local/reports/d3c886c1.jpg",
    "diagnosis": {
      "id": "9e7d3f8e-18c9-46f4-b68d-dc0b4a65a152",
      "prediction": "Kemungkinan serangan trips",
      "confidence": 76,
      "symptoms": "Daun mengeriting dan beberapa pucuk tampak rusak.",
      "recommendation": "Pantau 2-3 hari, gunakan perangkap kuning, dan hubungi penyuluh bila menyebar.",
      "created_at": "2026-07-10T08:32:00Z"
    },
    "created_at": "2026-07-10T08:31:00Z",
    "updated_at": "2026-07-10T08:32:00Z"
  }
}
```

Notes:

- Jika AI diagnosis berjalan async, response boleh mengembalikan `diagnosis: null` dan `status: "Analisis berjalan"`.
- Jika backend menjalankan AI sync, response harus tetap selesai dalam target maksimal 10 detik.
- `summary` boleh dibuat dari `description`, hasil AI, atau moderator backend.

### GET `/plant-reports`

Requires auth. Riwayat laporan user.

Query:

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `page` | integer | `1` |  |
| `page_size` | integer | `20` | Max `100`. |
| `category` | string | optional | `Penyakit`, `Hama`, `Lainnya`. |
| `status` | string | optional | Filter status. |
| `farm_id` | UUID string | optional | Filter lahan. |

Response `200`: paginated `PlantReport`.

### GET `/plant-reports/{report_id}`

Requires auth. Detail laporan milik user.

Response `200`: `PlantReport`.

### PATCH `/plant-reports/{report_id}`

Requires auth. Update laporan sebelum diverifikasi.

Request:

```json
{
  "title": "Daun cabai mengeriting",
  "category": "Hama",
  "description": "Update deskripsi gejala.",
  "publish_to_feed": true
}
```

Response `200`: `PlantReport`.

Errors:

- `403 FORBIDDEN`
- `404 NOT_FOUND`
- `409 REPORT_ALREADY_VERIFIED`

### DELETE `/plant-reports/{report_id}`

Requires auth. Hapus laporan milik user jika status masih draft/menunggu.

Response `204`: no body.

## 6.5 AI Diagnosis

### POST `/plant-diagnoses`

Requires auth. Endpoint opsional jika mobile perlu meminta diagnosis tanpa membuat laporan final.

Content-Type: `multipart/form-data`

Form fields:

| Field | Type | Required |
| --- | --- | --- |
| `image` | file | yes |
| `crop` | string | no |
| `symptom_notes` | string | no |

Response `200`:

```json
{
  "data": {
    "id": "9e7d3f8e-18c9-46f4-b68d-dc0b4a65a152",
    "prediction": "Kemungkinan penyakit bercak daun",
    "confidence": 82,
    "symptoms": "Daun menunjukkan bercak cokelat pada beberapa area.",
    "recommendation": "Pisahkan tanaman terdampak, pangkas daun rusak, dan konsultasikan pestisida sesuai rekomendasi penyuluh.",
    "created_at": "2026-07-10T08:32:00Z"
  }
}
```

## 6.6 Radar Feed

### GET `/radar-feed/reports`

Requires auth. Mengambil laporan sekitar untuk Beranda/Radar Feed.

Query:

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `latitude` | decimal | optional | Jika ada, backend hitung jarak. |
| `longitude` | decimal | optional | Jika ada, backend hitung jarak. |
| `radius_km` | decimal | `10` | Radius laporan sekitar. |
| `category` | string | optional | `Hama`, `Bibit`, `Kerja Tani`, `Penyakit`, `Lainnya`. |
| `page` | integer | `1` |  |
| `page_size` | integer | `20` | Max `100`. |

Response `200`:

```json
{
  "data": {
    "items": [
      {
        "id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
        "category": "Hama",
        "distance": "4.6 km",
        "distance_km": 4.6,
        "title": "Serangan trips pada cabai",
        "summary": "Gejala daun mengeriting muncul di beberapa petak.",
        "status": "Terverifikasi",
        "farm_name": "Sawah Utara",
        "coordinate": {
          "latitude": -7.7956,
          "longitude": 110.3695
        },
        "image_url": "https://cdn.radar-tani.local/reports/d3c886c1.jpg",
        "created_at": "2026-07-10T08:31:00Z"
      }
    ],
    "page": 1,
    "page_size": 20,
    "total": 1
  }
}
```

### GET `/radar-feed/reports/{report_id}`

Requires auth. Detail laporan publik.

Response `200`: `PlantReport`.

## 6.7 Map Reports

### GET `/map/reports`

Requires auth. Data marker untuk tab Peta.

Query:

| Name | Type | Required |
| --- | --- | --- |
| `min_latitude` | decimal | no |
| `max_latitude` | decimal | no |
| `min_longitude` | decimal | no |
| `max_longitude` | decimal | no |
| `category` | string | no |

Response `200`:

```json
{
  "data": {
    "items": [
      {
        "id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
        "title": "Serangan trips pada cabai",
        "category": "Hama",
        "status": "Terverifikasi",
        "coordinate": {
          "latitude": -7.7956,
          "longitude": 110.3695
        },
        "created_at": "2026-07-10T08:31:00Z"
      }
    ]
  }
}
```

## 6.8 Notifications

### GET `/notifications`

Requires auth.

Query:

| Name | Type | Default |
| --- | --- | --- |
| `page` | integer | `1` |
| `page_size` | integer | `20` |
| `unread_only` | boolean | `false` |

Response `200`: paginated `Notification`.

### PATCH `/notifications/{notification_id}/read`

Requires auth. Tandai satu notifikasi sebagai sudah dibaca.

Response `200`:

```json
{
  "data": {
    "id": "30df599c-4255-4419-ae92-4109171dd840",
    "title": "Laporan diverifikasi",
    "message": "Laporan Daun cabai mengeriting sudah masuk Radar Feed.",
    "related_report_id": "d3c886c1-95c4-4402-953a-c8121ac76c5d",
    "is_read": true,
    "created_at": "2026-07-10T09:00:00Z"
  }
}
```

### PATCH `/notifications/read-all`

Requires auth.

Response `204`: no body.

## 6.9 Pesticide Orders

### GET `/pesticide-orders`

Requires auth.

Response `200`: paginated `PesticideOrder`.

### POST `/pesticide-orders`

Requires auth.

Request:

```json
{
  "product_name": "Pestisida Nabati",
  "quantity": 2,
  "related_report_id": "d3c886c1-95c4-4402-953a-c8121ac76c5d"
}
```

Response `201`:

```json
{
  "data": {
    "id": "1f1b5ddc-cf4e-403b-8d10-a84960bf2975",
    "product_name": "Pestisida Nabati",
    "quantity": 2,
    "status": "Diproses",
    "created_at": "2026-07-10T09:10:00Z"
  }
}
```

## 7. Client Integration Requirements

Backend perlu menjaga hal berikut agar tidak memecahkan iOS client:

- `category` untuk laporan tanaman harus menerima dan mengembalikan label Bahasa Indonesia: `Penyakit`, `Hama`, `Lainnya`.
- `confidence` harus integer `0...100`.
- `image_url` harus absolute URL yang dapat diakses app.
- `distance` di Radar Feed dikirim sebagai display string seperti `4.6 km`, dan `distance_km` dikirim sebagai numeric value untuk sorting/filtering.
- Jika `farm_id` tidak dikirim saat upload laporan, backend harus memilih lahan aktif/default atau mengembalikan `422 FARM_REQUIRED`.
- Response `204` tidak boleh punya body.
- Semua endpoint protected harus mengembalikan `401` jika bearer token tidak valid.

## 8. Suggested FastAPI Routers

```text
app/api/v1/
  auth.py
  users.py
  farms.py
  plant_reports.py
  plant_diagnoses.py
  radar_feed.py
  map_reports.py
  notifications.py
  pesticide_orders.py
```

Suggested schema modules:

```text
app/schemas/
  auth.py
  users.py
  farms.py
  reports.py
  diagnoses.py
  notifications.py
  pagination.py
  errors.py
```

## 9. Example Multipart Request

```bash
curl -X POST "https://api.radar-tani.local/api/v1/plant-reports" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "image=@/path/to/plant.jpg;type=image/jpeg" \
  -F "title=Daun cabai mengeriting" \
  -F "category=Hama" \
  -F "description=Daun cabai mengeriting sejak dua hari lalu." \
  -F "farm_id=f4d3665e-3ad9-4aa8-9511-645c308755b2" \
  -F "latitude=-7.7956" \
  -F "longitude=110.3695" \
  -F "publish_to_feed=true"
```

## 10. Open Questions for Backend

- Apakah AI diagnosis berjalan sync saat laporan dibuat, atau async dengan polling/status update?
- Apakah refresh token diperlukan untuk MVP, atau access token saja cukup?
- Apakah laporan publik perlu moderation manual sebelum tampil di Radar Feed?
- Batas ukuran foto final: kontrak ini mengusulkan 10 MB.
- Penyimpanan foto memakai object storage/CDN apa?
- Apakah kategori `Bibit` dan `Kerja Tani` di Radar Feed dibuat dari fitur laporan terpisah atau berasal dari backend/koperasi?

