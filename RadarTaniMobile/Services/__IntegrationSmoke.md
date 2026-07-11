# Integration Smoke Test Checklist

Pre-req: backend jalan dan simulator iPhone tersedia.

## Backend start
```bash
cd backend
uv run fastapi dev app/main.py
```
- [ ] `GET http://127.0.0.1:8000/health` → 200 `{"data":{"status":"ok",...}}`
- [ ] Swagger di `http://127.0.0.1:8000/docs` load

## Backend baseline (optional)
```bash
cd backend && uv run pytest --cov=app
```
- [ ] semua test pass (backend tidak diubah oleh update iOS ini)

## iOS Build
```bash
xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17' -skipMacroValidation build
```
- [ ] `BUILD SUCCEEDED`

## Flow (urut, di Simulator)
1. [ ] **Register petani baru** (tab belum auth → LoginView → "Daftar sebagai Petani") → isi form → submit → MainTabView muncul (hanya access/refresh token disimpan aman di Keychain; profil selalu dimuat dari `GET /me`).
2. [ ] **Tambah Farm** (tab Lahan → "Tambah Lahan") → isi nama/tanaman/lokasi → Simpan → farm muncul di list (reload dari `GET /farms`).
3. [ ] **Analisis dan laporan PlantScan** (tab Lapor → Ambil Foto → pilih kategori/judul/deskripsi) → `POST /plant-diagnoses` → hasil backend tampil → Tanya AI memakai `POST /plant-ai/chat` → konfirmasi Kirim Laporan memakai `POST /plant-reports`.
4. [ ] **Radar Feed** (tab Radar) → list `FeedReportOut` muncul + foto AsyncImage load + ganti kategori mengirim query `category` ke backend.
5. [ ] **Peta** (tab Peta) → annotations MapKit muncul; perubahan region mengirim batas min/max latitude/longitude ke backend.
6. [ ] **Notifikasi** (Profile → Notifikasi) → filter belum dibaca mengirim `unread_only`; tap card → markRead; tombol semua dibaca → markAllRead.
7. [ ] **Pesan Pestisida** (Profile → "Pesanan Pestisida") → tombol + → pilih laporan terkait opsional → Kirim → pesanan muncul di list.
8. [ ] **Logout** (Profile → Logout) → kembali LoginView; reopen app → session cleared (harus login lagi).

## Manual verify (admin flow opsional via Swagger)
- Admin demo: `admin@radartani.id` / `admin123`.
- Login admin di Swagger `/docs` `POST /auth/login` → dapat token → `POST /api/v1/dashboard/reports/{id}/verify-broadcast`.
- Lalu login petani → Notifikasi muncul (flow 6) setelah refresh.

## Offline (optional)
- [ ] Airplane mode → View menampilkan error "Tidak ada koneksi internet" dari `APIError.network`.

## Catatan integrasi
- Base URL app: `https://patra-api.kamil.my.id/api/v1` (`AppConstants.AppConfig.apiBaseURL`).
- ATS: `NSAllowsLocalNetworking = YES` (Info.plist generated via build setting).
- Token: Keychain (`com.hendrairawan.dev.RadarTaniMobile` service, keys `access_token`/`refresh_token`). Data profil tidak di-cache lokal.
- 401 refresh: single-flight di `APIClient.refreshOnce()` (rotasi refresh token).
- Multipart: `MultipartFormDataBuilder.appendFile` untuk plant-reports + plant-diagnoses.
- Category: String raw verbatim dari backend (bukan enum Swift).
- Image: `RTDAsyncImage` (SwiftUI.AsyncImage native, zero dep).
- Devices/FCM: tidak diaktifkan karena Firebase iOS belum memiliki konfigurasi valid; notifikasi in-app tetap memakai backend `GET/PATCH /notifications`.

## Verifikasi kontrak decode (sanity)
- [ ] Login response `AuthToken` (access_token/refresh_token/token_type/expires_in/user) ter-decode.
- [ ] `UserOut` dari `GET /me` cocok (id UUID, name, email, cooperative_name).
- [ ] `FarmOut` list `GET /farms` dengan coordinate + created_at/updated_at.
- [ ] `PlantReportOut` `POST /plant-reports` dengan `diagnosis` (null saat Analisis berjalan).
- [ ] `FeedReportOut` `GET /radar-feed/reports` dengan distance (string) + distance_km (double).
- [ ] `NotificationOut` `GET /notifications` dengan is_read + related_report_id.
- [ ] `PesticideOrderOut` `POST /pesticide-orders` dengan status "Diproses".
