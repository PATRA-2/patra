# Integrasi Backend ↔ iOS RadarTaniMobile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Full update app iOS RadarTaniMobile agar seluruh endpoint backend FastAPI terhubung nyata (8 area: auth, farms, reports, feed, map, notifications, orders; devices skip).

**Architecture:** Tetap MVVM `@Observable` yang sudah dibangun. Ganti isi Service yang mock → implementasi `APIClient` actor nyata (URLSession async/await, Keychain token, multipart upload, 401 single-flight refresh). Models jadi Codable + CodingKeys snake_case. Zero new SPM dependency — semua Apple stdlib.

**Tech Stack:** SwiftUI, Observation `@Observable`, URLSession async/await, Security.framework (Keychain), SwiftUI.AsyncImage, MapKit, UserNotifications, Xcode 16 file-system-synchronized groups.

## Global Constraints

- Target iOS 26.5; Swift 5.0; bundle `com.hendrairawan.dev.RadarTaniMobile`.
- Zero new SPM dependency. Semua Apple stdlib.
- Xcode 16 file-system-synchronized groups: tambah/hapus file `.swift` di filesystem otomatis masuk build — TIDAK perlu edit `project.pbxproj` untuk Swift files. Hanya build settings Info.plist yang diedit via pbxproj.
- Bahasa copy: Bahasa Indonesia, copy pendek.
- Backend base URL: `#if DEBUG` switch — Debug `http://127.0.0.1:8000/api/v1`, Release `https://api.radar-tani.id/api/v1`.
- Backend demo admin: `admin@radartani.id` / `admin123` (role `cooperative_admin`), tapi app sisi petani register akun baru.
- Backend response envelope: success `{"data": ...}`, error `{"error": {code, message, details}}`, list `{"data": {items, page, page_size, total}}`, 204 no body.
- Field JSON `snake_case`. Timestamp ISO 8601 UTC. ID UUID string.
- `category` sebagai `String` raw verbatim dari backend (bukan enum Swift).
- Auth: JWT HS256 Bearer. Access 3600s, refresh 30 hari (opaque, rotasi).
- Devices/FCM: skip. In-app notifications only.
- Build verification: `xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 16' build` sukses tiap task akhir.
- Not a git repo default branch issue — work on branch `spec/integration-design` (sudah dibuat) atau branch baru `feat/integration`.
- Commit hanya bila user minta (gitbutler rules). Tapi plan ini sediakan commit step sebagai placeholder — jalankan hanya bila user konfirmasi.

---

## File Structure

**NEW (filesystem-sync, auto masuk build):**
- `RadarTaniMobile/Core/Auth/KeychainTokenStore.swift` — Keychain wrapper access/refresh/cachedUser
- `RadarTaniMobile/Core/Networking/APIRoute.swift` — static endpoint factory
- `RadarTaniMobile/Core/Networking/APIErrorCode.swift` — backend error code string constants
- `RadarTaniMobile/Core/Networking/APIDecoder.swift` — shared JSONDecoder/Encoder ISO8601
- `RadarTaniMobile/Core/Image/RTDAsyncImage.swift` — AsyncImage wrapper + fallback
- `RadarTaniMobile/Models/ErrorResponse.swift` — ServerError + FieldError
- `RadarTaniMobile/Models/PaginatedList.swift` — generic PaginatedList<T>
- `RadarTaniMobile/Models/AuthToken.swift` — AuthToken (login/register) + TokenRefresh
- `RadarTaniMobile/Models/PlantReportOut.swift` — full backend plant report model
- `RadarTaniMobile/Models/FeedReportOut.swift` — radar feed item + distance_km
- `RadarTaniMobile/Models/MapReportOut.swift` — MapItemsOut
- `RadarTaniMobile/Models/OrderOut.swift` — PesticideOrderOut + Create
- `RadarTaniMobile/Services/RadarFeedService.swift` — feed + map endpoints
- `RadarTaniMobile/Services/OrderService.swift` — pesticide-orders
- `RadarTaniMobile/Features/Profile/ViewModels/OrderListViewModel.swift` — orders VM
- `RadarTaniMobile/Features/Profile/Views/OrderListView.swift` — orders list view
- `RadarTaniMobile/Services/__IntegrationSmoke.md` — smoke test checklist

**REWRITE (replace body):**
- `RadarTaniMobile/Core/Networking/APIClient.swift` — actor + auth + 401 refresh + body + upload
- `RadarTaniMobile/Core/Networking/APIEndpoint.swift` — +body/auth/accepts
- `RadarTaniMobile/Core/Networking/APIError.swift` — enum + ServerError mapping
- `RadarTaniMobile/Core/Networking/MultipartFormDataBuilder.swift` — +appendFile
- `RadarTaniMobile/Core/Auth/AuthSession.swift` — Keychain persist
- `RadarTaniMobile/App/AppConstants.swift` — #if DEBUG base URL
- `RadarTaniMobile/App/AppEnvironment.swift` — real DI container
- `RadarTaniMobile/App/ContentView.swift` — AuthSession gate + env inject
- `RadarTaniMobile/RadarTaniApp.swift` — init AppEnvironment
- `RadarTaniMobile/Models/APIResponse.swift` — generic envelope + ErrorResponse
- `RadarTaniMobile/Models/User.swift` — UserOut
- `RadarTaniMobile/Models/Farm.swift` — FarmOut + FarmCreate + FarmUpdate + delete RadarReport
- `RadarTaniMobile/Models/AIPlantDiagnosis.swift` — DiagnosisOut
- `RadarTaniMobile/Models/NotificationItem.swift` — NotificationOut
- `RadarTaniMobile/Models/PesticideOrder.swift` — typealias ke OrderOut
- `RadarTaniMobile/Models/ReportHistoryItem.swift` — factory init(from: PlantReportOut)
- `RadarTaniMobile/Services/AuthService.swift` — real login/register/refresh/logout/me
- `RadarTaniMobile/Services/FarmService.swift` — farms CRUD
- `RadarTaniMobile/Services/ReportService.swift` — plant-reports multipart + list
- `RadarTaniMobile/Services/AIService.swift` — diagnose standalone
- `RadarTaniMobile/Services/NotificationService.swift` — list + markRead + markAllRead
- `RadarTaniMobile/Features/Auth/ViewModels/LoginViewModel.swift`
- `RadarTaniMobile/Features/Auth/ViewModels/RegisterViewModel.swift`
- `RadarTaniMobile/Features/Home/ViewModels/HomeViewModel.swift`
- `RadarTaniMobile/Features/Farms/ViewModels/FarmListViewModel.swift`
- `RadarTaniMobile/Features/Farms/ViewModels/AddFarmViewModel.swift`
- `RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift` (submit only)
- `RadarTaniMobile/Features/RadarFeed/ViewModels/RadarFeedViewModel.swift`
- `RadarTaniMobile/Features/RadarFeed/ViewModels/ReportDetailViewModel.swift`
- `RadarTaniMobile/Features/Map/ViewModels/RadarMapViewModel.swift`
- `RadarTaniMobile/Features/Notifications/ViewModels/NotificationListViewModel.swift`
- `RadarTaniMobile/Features/Profile/ViewModels/ProfileViewModel.swift`
- `RadarTaniMobile/SupportingFiles/Config.xcconfig` — dokumentasi dua URL

**DELETE (filesystem, auto keluar build):**
- `RadarTaniMobile/Core/Auth/TokenStore.swift`
- `RadarTaniMobile/Core/Auth/AuthInterceptor.swift`
- `RadarTaniMobile/Models/Report.swift`
- `RadarTaniMobile/Services/UploadService.swift`
- `RadarTaniMobile/Services/ReportHistoryStore.swift`
- `RadarTaniMobile/App/AppState.swift` (bila ada & tidak terpakai)

**MODIFY (Views — ganti mock Image → RTDAsyncImage, mock data → vm prop):**
- `RadarTaniMobile/Features/RadarFeed/Views/RadarFeedView.swift` + item card views
- `RadarTaniMobile/Features/Map/Views/RadarMapView.swift`
- `RadarTaniMobile/Features/PlantScan/Views/PlantDiagnosisResultView.swift`
- `RadarTaniMobile/Features/Profile/Views/ReportHistoryView.swift`
- `RadarTaniMobile/Features/Home/Views/MainTabView.swift` (logout callback pakai env)
- `RadarTaniMobile/Features/Notifications/Views/*View.swift`

**BUILD SETTINGS (pbxproj):**
- `RadarTaniMobile.xcodeproj/project.pbxproj` — tambah `INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsLocalNetworking = YES` di Debug config block (dua: Debug + Release).

---

## Task 1: Config & Build Settings (base URL + ATS)

**Files:**
- Modify: `RadarTaniMobile/App/AppConstants.swift`
- Modify: `RadarTaniMobile/SupportingFiles/Config.xcconfig`
- Modify: `RadarTaniMobile.xcodeproj/project.pbxproj` (Debug + Debug-stub build setting blocks)

**Interfaces:**
- Produces: `AppConfig.apiBaseURL -> URL` (digunakan Task 6 APIClient init).

- [ ] **Step 1: Rewrite AppConstants.swift**

```swift
import Foundation

enum AppConstants {
    static let appName = "Radar Tani Desa"
}

enum AppConfig {
    static var apiBaseURL: URL {
        #if DEBUG
        URL(string: "http://127.0.0.1:8000/api/v1")!
        #else
        URL(string: "https://api.radar-tani.id/api/v1")!
        #endif
    }
}
```

- [ ] **Step 2: Update Config.xcconfig (dokumentasi)**

```
// Dev (Debug build): http://127.0.0.1:8000/api/v1
// Release build:        https://api.radar-tani.id/api/v1
// Aktif switch ada di AppConstants.AppConfig.apiBaseURL (#if DEBUG).
RTD_API_BASE_URL = http://127.0.0.1:8000/api/v1
```
(File ini dokumentasi; Swift baca `#if DEBUG`, bukan xcconfig. Ponytail: bila QA butuh override tanpa rebuild, baca Info.plist custom key via `Bundle.main.object(forInfoDictionaryKey:)`.)

- [ ] **Step 3: Tambah ATS build setting di pbxproj**

Cari blok `GENERATE_INFOPLIST_FILE = YES;` (ada 2: Debug + Release). Setelah baris `INFOPLIST_KEY_NSCameraUsageDescription = ...;` di tiap blok, tambah:

```
INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsLocalNetworking = YES;
```

Edit manual via `replace_content` Serena atau Edit tool — jangan regenerate pbxproj.

- [ ] **Step 4: Build verify**

Run: `xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 16' -skipMacroValidation build 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`.

---

## Task 2: KeychainTokenStore

**Files:**
- Create: `RadarTaniMobile/Core/Auth/KeychainTokenStore.swift`

**Interfaces:**
- Produces: `KeychainTokenStore` dengan `setAccess/ setRefresh/ setCachedUser/ access/ refresh/ cachedUser/ clear`. Digunakan AuthSession (Task 4) & APIClient (Task 6).

- [ ] **Step 1: Buat KeychainTokenStore.swift**

```swift
import Foundation
import Security

struct KeychainTokenStore {
    private let service = "com.hendrairawan.dev.RadarTaniMobile"
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"
    private let userKey = "cached_user"

    func setAccess(_ token: String) { set(token, account: accessKey) }
    func setRefresh(_ token: String) { set(token, account: refreshKey) }
    func setCachedUser(_ user: UserOut) {
        if let data = try? JSONEncoder().encode(user) { set(data, account: userKey) }
    }

    func access() -> String? { string(account: accessKey) }
    func refresh() -> String? { string(account: refreshKey) }
    func cachedUser() -> UserOut? {
        guard let data = data(account: userKey) else { return nil }
        return try? JSONDecoder().decode(UserOut.self, from: data)
    }

    func clear() {
        delete(account: accessKey); delete(account: refreshKey); delete(account: userKey)
    }

    private func set(_ token: String, account: String) {
        set(Data(token.utf8), account: account)
    }
    private func set(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
    private func data(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }
    private func string(account: String) -> String? {
        guard let data = data(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 2: Build verify**

Run: `xcodebuild ... build | tail -5`
Expected: `BUILD SUCCEEDED` (file belum direferensi, tapi compile OK).

---

## Task 3: Models rewire (Codable + snake_case)

**Files:**
- Create: `RadarTaniMobile/Models/ErrorResponse.swift`, `PaginatedList.swift`, `AuthToken.swift`, `PlantReportOut.swift`, `FeedReportOut.swift`, `MapReportOut.swift`, `OrderOut.swift`
- Modify: `RadarTaniMobile/Models/APIResponse.swift`, `User.swift`, `Farm.swift`, `AIPlantDiagnosis.swift`, `NotificationItem.swift`, `PesticideOrder.swift`, `ReportHistoryItem.swift`, `Coordinate.swift`
- Delete: `RadarTaniMobile/Models/Report.swift`

**Interfaces:**
- Consumes: `Coordinate` (sudah Codable).
- Produces: semua struct model untuk Service (Task 7+) & ViewModel.

- [ ] **Step 1: Rewrite APIResponse.swift + buat ErrorResponse.swift + PaginatedList.swift**

`RadarTaniMobile/Models/APIResponse.swift`:
```swift
import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let data: T
}
```

`RadarTaniMobile/Models/ErrorResponse.swift`:
```swift
import Foundation

struct ErrorResponse: Decodable {
    let error: ServerError
}
struct ServerError: Decodable {
    let code: String
    let message: String
    let details: [FieldError]?
}
struct FieldError: Decodable {
    let field: String?
    let message: String?
}
```

`RadarTaniMobile/Models/PaginatedList.swift`:
```swift
import Foundation

struct PaginatedList<T: Decodable>: Decodable {
    let items: [T]
    let page: Int
    let pageSize: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case items, page
        case pageSize = "page_size"
        case total
    }
}
```

- [ ] **Step 2: Buat AuthToken.swift**

```swift
import Foundation

struct AuthToken: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: UserOut?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
    }
}

struct TokenRefresh: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}
```

- [ ] **Step 3: Rewrite User.swift → UserOut**

```swift
import Foundation

struct UserOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let cooperativeName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case cooperativeName = "cooperative_name"
    }
}

// Backwards-compat alias supaya referensi lama tetap compile.
typealias User = UserOut
```

- [ ] **Step 4: Rewrite Farm.swift — FarmOut + FarmCreate + FarmUpdate + HAPUS RadarReport**

```swift
import Foundation
import SwiftUI

struct FarmOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let crop: String
    let location: String
    let coordinate: Coordinate
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, crop, location, coordinate
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FarmCreate: Encodable {
    let name: String
    let crop: String
    let location: String
    let coordinate: Coordinate?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name, crop, location, coordinate
        case isActive = "is_active"
    }
}

struct FarmUpdate: Encodable {
    let name: String?
    let crop: String?
    let location: String?
    let coordinate: Coordinate?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name, crop, location, coordinate
        case isActive = "is_active"
    }
}

// Backwards-compat alias.
typealias Farm = FarmOut
```

Note: `RadarReport` enum di lama Farm.swift dihapus. Typealias diganti FeedReportOut (Step 6).

- [ ] **Step 5: Rewrite AIPlantDiagnosis.swift → DiagnosisOut**

```swift
import Foundation

struct DiagnosisOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let prediction: String
    let confidence: Int
    let symptoms: String
    let recommendation: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, prediction, confidence, symptoms, recommendation
        case createdAt = "created_at"
    }
}

typealias AIPlantDiagnosis = DiagnosisOut
```

- [ ] **Step 6: Buat PlantReportOut.swift, FeedReportOut.swift, MapReportOut.swift**

`RadarTaniMobile/Models/PlantReportOut.swift`:
```swift
import Foundation

struct PlantReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let summary: String
    let description: String?
    let status: String
    let farmId: UUID
    let farmName: String
    let coordinate: Coordinate
    let imageUrl: String
    let diagnosis: DiagnosisOut?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, category, summary, description, status
        case farmId = "farm_id"
        case farmName = "farm_name"
        case coordinate
        case imageUrl = "image_url"
        case diagnosis
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

`RadarTaniMobile/Models/FeedReportOut.swift`:
```swift
import Foundation

struct FeedReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let category: String
    let distance: String
    let distanceKm: Double
    let title: String
    let summary: String
    let status: String
    let farmName: String
    let coordinate: Coordinate
    let imageUrl: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, distance, title, summary, status
        case distanceKm = "distance_km"
        case farmName = "farm_name"
        case coordinate
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }
}
```

`RadarTaniMobile/Models/MapReportOut.swift`:
```swift
import Foundation

struct MapReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let status: String
    let coordinate: Coordinate
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, category, status, coordinate
        case createdAt = "created_at"
    }
}

struct MapItemsOut: Decodable {
    let items: [MapReportOut]
}
```

- [ ] **Step 7: Buat OrderOut.swift + rewrite NotificationItem.swift + PesticideOrder.swift**

`RadarTaniMobile/Models/OrderOut.swift`:
```swift
import Foundation

struct PesticideOrderOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let productName: String
    let quantity: Int
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productName = "product_name"
        case quantity, status
        case createdAt = "created_at"
    }
}

struct PesticideOrderCreate: Encodable {
    let productName: String
    let quantity: Int
    let relatedReportId: UUID?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case quantity
        case relatedReportId = "related_report_id"
    }
}
```

`RadarTaniMobile/Models/PesticideOrder.swift`:
```swift
import Foundation
typealias PesticideOrder = PesticideOrderOut
```

`RadarTaniMobile/Models/NotificationItem.swift`:
```swift
import Foundation

struct NotificationOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let message: String
    let relatedReportId: UUID?
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, message
        case relatedReportId = "related_report_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

typealias NotificationItem = NotificationOut
```

- [ ] **Step 8: Rewrite ReportHistoryItem.swift (factory dari PlantReportOut)**

```swift
import Foundation
import SwiftUI

struct ReportHistoryItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: String
    let summary: String
    let status: String
    let farmName: String
    let submittedAt: Date

    init(id: UUID, title: String, category: String, summary: String,
         status: String, farmName: String, submittedAt: Date = .now) {
        self.id = id; self.title = title; self.category = category
        self.summary = summary; self.status = status
        self.farmName = farmName; self.submittedAt = submittedAt
    }

    init(from report: PlantReportOut) {
        self.id = report.id
        self.title = report.title
        self.category = report.category
        self.summary = report.summary
        self.status = report.status
        self.farmName = report.farmName
        self.submittedAt = report.createdAt
    }

    var submittedDateText: String { DateFormatter.rtdShortDate.string(from: submittedAt) }

    var categoryColor: Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        default: RTDColor.infoBlue
        }
    }
}
```

- [ ] **Step 9: Coordinate.swift tetap (sudah Codable). Delete Report.swift**

Hapus `RadarTaniMobile/Models/Report.swift` (isinya `typealias Report = RadarReport` — RadarReport sudah dihapus).

- [ ] **Step 10: Build verify**

Run: `xcodebuild ... build 2>&1 | tail -30`
Expected: build akan GAGAL karena banyak View/VM masih refer `RadarReport.Category` (`Farm.swift` lama) dan `Farm(...)` initializer lama. Catat error compile. Ini akan diperbaiki di task ViewModel wiring (Task 9+). Untuk lanjut: jangan commit. Jalankan task berikutnya sampai semua referensi diperbaiki, lalu build ulang di Task 10.

Catatan: bila ingin build sukses per-task, susun ulang: pindahkan hapus RadarReport ke Task 9 bersamaan dengan rewrite RadarFeedViewModel. Tapi karena sinkronisasi Swift file butuh semua referensi konsisten sekaligus,/update semua model dulu lalu VM — build sukses di Task 10 checkpoint.

---

## Task 4: AuthSession rewrite (Keychain persist)

**Files:**
- Rewrite: `RadarTaniMobile/Core/Auth/AuthSession.swift`

**Interfaces:**
- Consumes: `KeychainTokenStore` (Task 2), `UserOut`/`AuthToken` (Task 3).
- Produces: `AuthSession` (`currentUser`, `isAuthenticated`, `isRestoring`, `didAuthenticate`, `logout`) untuk AppEnvironment (Task 6) & ContentView (Task 10).

- [ ] **Step 1: Rewrite AuthSession.swift**

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AuthSession {
    private let tokenStore: KeychainTokenStore
    private(set) var currentUser: UserOut?
    private(set) var isRestoring: Bool = true

    var isAuthenticated: Bool { currentUser != nil }

    init(tokenStore: KeychainTokenStore) {
        self.tokenStore = tokenStore
        if let user = tokenStore.cachedUser(), tokenStore.access() != nil {
            currentUser = user
        }
        isRestoring = false
    }

    func didAuthenticate(_ token: AuthToken) {
        tokenStore.setAccess(token.accessToken)
        tokenStore.setRefresh(token.refreshToken)
        if let user = token.user {
            tokenStore.setCachedUser(user)
            currentUser = user
        }
    }

    func logout() {
        tokenStore.clear()
        currentUser = nil
    }
}
```

- [ ] **Step 2: Delete TokenStore.swift + AuthInterceptor.swift**

Hapus `RadarTaniMobile/Core/Auth/TokenStore.swift` dan `RadarTaniMobile/Core/Auth/AuthInterceptor.swift`. Logika pindah ke APIClient (Task 6).

- [ ] **Step 3: Build verify (akan gagal karena ContentView/MainTabView belum diupdate)**

Lewati build verify di task ini — akan sukses setelah Task 10.

---

## Task 5: APIError + APIErrorCode + APIDecoder + APIEndpoint + MultipartFormDataBuilder

**Files:**
- Rewrite: `RadarTaniMobile/Core/Networking/APIError.swift`, `APIEndpoint.swift`, `MultipartFormDataBuilder.swift`
- Create: `RadarTaniMobile/Core/Networking/APIErrorCode.swift`, `APIDecoder.swift`

**Interfaces:**
- Produces: `APIError` enum + `server(ServerError)` + `userMessage` extension; `APIErrorCode` constants; `APIDecoder.decoder/encoder`; `APIEndpoint` (+ body/auth/accepts); `MultipartFormDataBuilder.appendFile`.

- [ ] **Step 1: Rewrite APIError.swift**

```swift
import Foundation

enum APIError: Error, Sendable {
    case unauthenticated
    case server(ServerError)
    case network(URLError)
    case decoding(Error)
    case invalidURL
    case unknown

    var isAIError: Bool {
        if case .server(let s) = self {
            return s.code == APIErrorCode.aiTimeout || s.code == APIErrorCode.aiUnavailable
        }
        return false
    }

    var userMessage: String {
        switch self {
        case .unauthenticated: return "Sesi habis, silakan masuk kembali."
        case .server(let s):
            switch s.code {
            case APIErrorCode.invalidCredentials: return "Email atau password salah."
            case APIErrorCode.emailAlreadyRegistered: return "Email sudah terdaftar."
            case APIErrorCode.farmInUse: return "Lahan masih digunakan laporan, tidak bisa dihapus."
            case APIErrorCode.reportAlreadyVerified: return "Laporan sudah diverifikasi, tidak bisa diubah."
            case APIErrorCode.reportAlreadyRejected: return "Laporan sudah ditolak."
            case APIErrorCode.validationError:
                return s.details?.compactMap { "\($0.field ?? "") \($0.message ?? "")" }
                    .joined(separator: "\n") ?? "Data tidak valid."
            case APIErrorCode.farmRequired: return "Pilih lahan aktif dulu."
            case APIErrorCode.locationRequired: return "Aktifkan lokasi atau pilih lahan aktif."
            case APIErrorCode.aiTimeout: return "Analisis AI melebihi batas waktu, coba lagi."
            case APIErrorCode.aiUnavailable: return "Layanan AI sedang tidak tersedia."
            case APIErrorCode.invalidRefreshToken: return "Sesi habis, silakan masuk kembali."
            default: return s.message
            }
        case .network: return "Tidak ada koneksi internet."
        case .decoding: return "Data response tidak terbaca."
        case .invalidURL: return "URL tidak valid."
        case .unknown: return "Terjadi kesalahan."
        }
    }
}
```

- [ ] **Step 2: Buat APIErrorCode.swift**

```swift
import Foundation

enum APIErrorCode {
    static let invalidCredentials = "INVALID_CREDENTIALS"
    static let emailAlreadyRegistered = "EMAIL_ALREADY_REGISTERED"
    static let invalidRefreshToken = "INVALID_REFRESH_TOKEN"
    static let forbidden = "FORBIDDEN"
    static let notFound = "NOT_FOUND"
    static let farmInUse = "FARM_IN_USE"
    static let reportAlreadyVerified = "REPORT_ALREADY_VERIFIED"
    static let reportAlreadyRejected = "REPORT_ALREADY_REJECTED"
    static let reportNotReady = "REPORT_NOT_READY"
    static let validationError = "VALIDATION_ERROR"
    static let farmRequired = "FARM_REQUIRED"
    static let locationRequired = "LOCATION_REQUIRED"
    static let payloadTooLarge = "PAYLOAD_TOO_LARGE"
    static let unsupportedMedia = "UNSUPPORTED_MEDIA_TYPE"
    static let aiTimeout = "AI_TIMEOUT"
    static let aiUnavailable = "AI_UNAVAILABLE"
}
```

- [ ] **Step 3: Buat APIDecoder.swift**

```swift
import Foundation

enum APICoder {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = formatter.date(from: raw) { return date }
            // fallback tanpa fractional
            let f2 = ISO8601DateFormatter()
            if let date = f2.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(raw)")
        }
        return d
    }()
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        return e
    }()
}
```

- [ ] **Step 4: Rewrite APIEndpoint.swift**

```swift
import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

enum AuthRequirement: Sendable { case required, optional, public_ }
enum AcceptsType: Sendable { case json, multipart }

struct APIEndpoint: Sendable {
    var path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var jsonBody: Data? = nil
    var auth: AuthRequirement = .required
    var accepts: AcceptsType = .json
}
```

(HTPMethod.swift duplikat — hapus file `RadarTaniMobile/Core/Networking/HTTPMethod.swift` lama atau biarkan typealias. Karena sudah ada di sini, DELETE file lama supaya tidak redeclare.)

Hapus `RadarTaniMobile/Core/Networking/HTTPMethod.swift`.

- [ ] **Step 5: Rewrite MultipartFormDataBuilder.swift**

```swift
import Foundation

struct MultipartFormDataBuilder {
    let boundary: String
    private(set) var body = Data()

    init() { boundary = "----RTDBoundary" + UUID().uuidString }

    mutating func append(_ name: String, _ value: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    mutating func appendFile(_ name: String, data: Data, filename: String, mimeType: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    var httpBody: Data {
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }
}

private extension Data {
    mutating func appendString(_ string: String) { append(Data(string.utf8)) }
}
```

- [ ] **Step 6: Build verify**

Build belum bisa sukses (APIClient+VM belum update). Status: lanjut Task 6.

---

## Task 6: APIClient + APIRoute

**Files:**
- Rewrite: `RadarTaniMobile/Core/Networking/APIClient.swift`
- Create: `RadarTaniMobile/Core/Networking/APIRoute.swift`

**Interfaces:**
- Consumes: `APIEndpoint`, `APIError`, `APICoder`, `KeychainTokenStore`, `MultipartFormDataBuilder`, `ErrorResponse`, `APIResponse`.
- Produces: `APIClient` actor (`request<T>`, `upload<T>`, custom decode via `_ type: T.Type`). Dipakai semua Service (Task 7).

- [ ] **Step 1: Rewrite APIClient.swift**

```swift
import Foundation

actor APIClient {
    let baseURL: URL
    let tokenStore: KeychainTokenStore
    let session: URLSession
    private var refreshTask: Task<TokenRefresh, Error>?
    weak var sessionRef: AuthSession?

    init(baseURL: URL, tokenStore: KeychainTokenStore, session: AuthSession? = nil) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = URLSession.shared
        self.sessionRef = session
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let (_, status) = try await rawSend(endpoint)
        guard (200..<300).contains(status) else { throw await decodeError(status: status, cacheKey: nil) }
    }

    func request<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T {
        var (data, status) = try await rawSend(endpoint)

        // 401 retry
        if status == 401, endpoint.path != "/auth/refresh", tokenStore.refresh() != nil {
            _ = try await refreshOnce()
            (data, status) = try await rawSend(endpoint)
            if status == 401 { await logoutAndClear(); throw APIError.unauthenticated }
        }

        guard (200..<300).contains(status) else {
            throw try await decodeError(status: status, cacheKey: nil, data: data)
        }
        if status == 204 || data.isEmpty {
            // Expect T untuk no-body tidak umum; caller pakai requestVoid.
            return try APICoder.decoder.decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
        }
        let wrapped = try APICoder.decoder.decode(APIResponse<T>.self, from: data)
        return wrapped.data
    }

    func upload<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint,
                                         body: Data, contentType: String) async throws -> T {
        var (data, status) = try await rawSend(endpoint, body: body, contentType: contentType)
        if status == 401, endpoint.path != "/auth/refresh", tokenStore.refresh() != nil {
            _ = try await refreshOnce()
            (data, status) = try await rawSend(endpoint, body: body, contentType: contentType)
            if status == 401 { await logoutAndClear(); throw APIError.unauthenticated }
        }
        guard (200..<300).contains(status) else {
            throw try await decodeError(status: status, cacheKey: nil, data: data)
        }
        let wrapped = try APICoder.decoder.decode(APIResponse<T>.self, from: data)
        return wrapped.data
    }

    func refreshOnce() async throws -> TokenRefresh {
        if let task = refreshTask { return try await task.value }
        guard let refresh = tokenStore.refresh() else { throw APIError.unauthenticated }
        let task = Task { () throws -> TokenRefresh in
            let body = try APICoder.encoder.encode(RefreshRequest(refreshToken: refresh))
            let endpoint = APIEndpoint(path: "/auth/refresh", method: .post,
                                       jsonBody: body, auth: .public_)
            var (data, status) = try await self.rawSend(endpoint)
            guard (200..<300).contains(status) else {
                await self.logoutAndClear()
                throw APIError.unauthenticated
            }
            let wrapped = try APICoder.decoder.decode(APIResponse<TokenRefresh>.self, from: data)
            self.tokenStore.setAccess(wrapped.data.accessToken)
            self.tokenStore.setRefresh(wrapped.data.refreshToken)
            return wrapped.data
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func rawSend(_ endpoint: APIEndpoint, body: Data? = nil,
                         contentType: String? = nil) async throws -> (Data, Int) {
        guard var components = URLComponents(url: baseURL.appending(path: endpoint.path),
                                            resolvingAgainstBaseURL: false)
        else { throw APIError.invalidURL }
        components.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let body = body {
            request.httpBody = body
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        } else if let json = endpoint.jsonBody {
            request.httpBody = json
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.auth != .public_ {
            if let token = tokenStore.access() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if endpoint.auth == .required {
                throw APIError.unauthenticated
            }
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
            return (data, http.statusCode)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }
    }

    private func decodeError(status: Int, cacheKey: String?, data: Data = Data()) async throws -> APIError {
        if let err = try? APICoder.decoder.decode(ErrorResponse.self, from: data) {
            return .server(err.error)
        }
        return .server(ServerError(code: "HTTP_\(status)", message: "Kesalahan server (\(status)).", details: nil))
    }

    private func logoutAndClear() async {
        tokenStore.clear()
        await MainActor.run { [weak self] in
            self?.sessionRef?.logout()
        }
    }
}

struct RefreshRequest: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}
```

Note: `sessionRef` weak — perlu dependency cycle. Karena AuthSession `@MainActor`, butuh MainActor.run. Ponytail: bila weak ref bermasalah, ganti closure callback `onLogout: () -> Void`.

- [ ] **Step 2: Buat APIRoute.swift**

```swift
import Foundation

enum APIRoute {
    // Health
    static let health = APIEndpoint(path: "/health", method: .get, auth: .public_)

    // Auth
    static let login = APIEndpoint(path: "/auth/login", method: .post, auth: .public_)
    static let register = APIEndpoint(path: "/auth/register", method: .post, auth: .public_)
    static let refresh = APIEndpoint(path: "/auth/refresh", method: .post, auth: .public_)
    static let logout = APIEndpoint(path: "/auth/logout", method: .post, auth: .required)
    static let me = APIEndpoint(path: "/me", method: .get, auth: .required)

    // Farms
    static func farms(page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        .init(path: "/farms", method: .get, auth: .required,
              query: [.init(name: "page", value: "\(page)"),
                      .init(name: "page_size", value: "\(pageSize)")])
    }
    static let farmsCreate = APIEndpoint(path: "/farms", method: .post, auth: .required)
    static func farmUpdate(_ id: UUID) -> APIEndpoint { .init(path: "/farms/\(id)", method: .patch, auth: .required) }
    static func farmDelete(_ id: UUID) -> APIEndpoint { .init(path: "/farms/\(id)", method: .delete, auth: .required) }

    // Plant reports
    static let reportsCreate = APIEndpoint(path: "/plant-reports", method: .post, auth: .required, accepts: .multipart)
    static func reports(page: Int = 1, pageSize: Int = 20, category: String? = nil,
                        status: String? = nil, farmId: UUID? = nil) -> APIEndpoint {
        var query: [URLQueryItem] = [.init(name: "page", value: "\(page)"),
                                     .init(name: "page_size", value: "\(pageSize)")]
        if let category { query.append(.init(name: "category", value: category)) }
        if let status { query.append(.init(name: "status", value: status)) }
        if let farmId { query.append(.init(name: "farm_id", value: farmId.uuidString)) }
        return .init(path: "/plant-reports", method: .get, auth: .required, query: query)
    }
    static func report(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .get, auth: .required) }
    static func reportUpdate(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .patch, auth: .required) }
    static func reportDelete(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .delete, auth: .required) }
    static let diagnose = APIEndpoint(path: "/plant-diagnoses", method: .post, auth: .required, accepts: .multipart)

    // Radar feed + map
    static func radarFeed(lat: Double? = nil, long: Double? = nil, radiusKm: Double = 10,
                          category: String? = nil, page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        var query: [URLQueryItem] = [.init(name: "radius_km", value: "\(radiusKm)"),
                                     .init(name: "page", value: "\(page)"),
                                     .init(name: "page_size", value: "\(pageSize)")]
        if let lat, let long {
            query.append(.init(name: "latitude", value: "\(lat)"))
            query.append(.init(name: "longitude", value: "\(long)"))
        }
        if let category { query.append(.init(name: "category", value: category)) }
        return .init(path: "/radar-feed/reports", method: .get, auth: .required, query: query)
    }
    static func feedDetail(_ id: UUID) -> APIEndpoint { .init(path: "/radar-feed/reports/\(id)", method: .get, auth: .required) }
    static func mapReports(minLat: Double? = nil, maxLat: Double? = nil,
                           minLong: Double? = nil, maxLong: Double? = nil,
                           category: String? = nil) -> APIEndpoint {
        var query: [URLQueryItem] = []
        if let minLat { query.append(.init(name: "min_latitude", value: "\(minLat)")) }
        if let maxLat { query.append(.init(name: "max_latitude", value: "\(maxLat)")) }
        if let minLong { query.append(.init(name: "min_longitude", value: "\(minLong)")) }
        if let maxLong { query.append(.init(name: "max_longitude", value: "\(maxLong)")) }
        if let category { query.append(.init(name: "category", value: category)) }
        return .init(path: "/map/reports", method: .get, auth: .required, query: query)
    }

    // Notifications
    static func notifications(page: Int = 1, pageSize: Int = 20, unreadOnly: Bool = false) -> APIEndpoint {
        APIEndpoint(path: "/notifications", method: .get, auth: .required,
            query: [.init(name: "page", value: "\(page)"),
                    .init(name: "page_size", value: "\(pageSize)"),
                    .init(name: "unread_only", value: "\(unreadOnly)")])
    }
    static func notificationRead(_ id: UUID) -> APIEndpoint { .init(path: "/notifications/\(id)/read", method: .patch, auth: .required) }
    static let notificationsReadAll = APIEndpoint(path: "/notifications/read-all", method: .patch, auth: .required)

    // Orders
    static func orders(page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        .init(path: "/pesticide-orders", method: .get, auth: .required,
              query: [.init(name: "page", value: "\(page)"),
                      .init(name: "page_size", value: "\(pageSize)")])
    }
    static let ordersCreate = APIEndpoint(path: "/pesticide-orders", method: .post, auth: .required)
}
```

- [ ] **Step 3: Build verify**

Masih akan gagal karena AppEnvironment/VM belum update. Lanjut Task 7.

---

## Task 7: Services rewrite (real API calls)

**Files:**
- Rewrite: `RadarTaniMobile/Services/AuthService.swift`, `FarmService.swift`, `ReportService.swift`, `AIService.swift`, `NotificationService.swift`
- Create: `RadarTaniMobile/Services/RadarFeedService.swift`, `OrderService.swift`
- Delete: `RadarTaniMobile/Services/UploadService.swift`, `ReportHistoryStore.swift`

**Interfaces:**
- Consumes: `APIClient`, `APIRoute`, semua models.
- Produces: semua Service struct async untuk ViewModel (Task 9).

- [ ] **Step 1: AuthService.swift**

```swift
import Foundation

struct AuthService: Sendable {
    let client: APIClient

    func login(email: String, password: String) async throws -> AuthToken {
        let body = try APICoder.encoder.encode(LoginRequest(email: email, password: password))
        return try await client.request(AuthToken.self,
            endpoint: APIRoute.login.withBody(body))
    }

    func register(name: String, email: String, password: String,
                  cooperativeName: String?, farmLocation: String?) async throws -> AuthToken {
        let body = try APICoder.encoder.encode(RegisterRequest(
            name: name, email: email, password: password,
            cooperativeName: cooperativeName, farmLocation: farmLocation))
        return try await client.request(AuthToken.self,
            endpoint: APIRoute.register.withBody(body))
    }

    func logout() async throws {
        try await client.requestVoid(APIRoute.logout)
    }

    func me() async throws -> UserOut {
        try await client.request(UserOut.self, endpoint: APIRoute.me)
    }
}

struct LoginRequest: Encodable { let email: String; let password: String }
struct RegisterRequest: Encodable {
    let name: String; let email: String; let password: String
    let cooperativeName: String?; let farmLocation: String?
    enum CodingKeys: String, CodingKey {
        case name, email, password
        case cooperativeName = "cooperative_name"
        case farmLocation = "farm_location"
    }
}

extension APIEndpoint {
    func withBody(_ data: Data) -> APIEndpoint {
        var e = self; e.jsonBody = data; return e
    }
}
```

- [ ] **Step 2: FarmService.swift**

```swift
import Foundation

struct FarmService: Sendable {
    let client: APIClient

    func farms(page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<FarmOut> {
        try await client.request(PaginatedList<FarmOut>.self, endpoint: APIRoute.farms(page: page, pageSize: pageSize))
    }
    func create(_ farm: FarmCreate) async throws -> FarmOut {
        let body = try APICoder.encoder.encode(farm)
        return try await client.request(FarmOut.self, endpoint: APIRoute.farmsCreate.withBody(body))
    }
    func update(_ id: UUID, _ farm: FarmUpdate) async throws -> FarmOut {
        let body = try APICoder.encoder.encode(farm)
        return try await client.request(FarmOut.self, endpoint: APIRoute.farmUpdate(id).withBody(body))
    }
    func delete(_ id: UUID) async throws {
        try await client.requestVoid(APIRoute.farmDelete(id))
    }
}
```

- [ ] **Step 3: ReportService.swift (multipart)**

```swift
import Foundation
import UIKit

struct ReportService: Sendable {
    let client: APIClient

    func create(image: UIImage, title: String, category: String, description: String?,
                farmId: UUID?, latitude: Double?, longitude: Double?,
                publishToFeed: Bool) async throws -> PlantReportOut {
        // Konversi UIImage → JPEG Data (HEIC tidak dijamin di simulator; JPEG aman).
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.unknown
        }
        var builder = MultipartFormDataBuilder()
        builder.appendFile("image", data: jpegData, filename: "report.jpg", mimeType: "image/jpeg")
        builder.append("title", title)
        builder.append("category", category)
        if let description { builder.append("description", description) }
        if let farmId { builder.append("farm_id", farmId.uuidString) }
        if let latitude, let longitude {
            builder.append("latitude", "\(latitude)")
            builder.append("longitude", "\(longitude)")
        }
        builder.append("publish_to_feed", publishToFeed ? "true" : "false")
        return try await client.upload(PlantReportOut.self,
            endpoint: APIRoute.reportsCreate,
            body: builder.httpBody, contentType: builder.contentType)
    }

    func list(page: Int = 1, pageSize: Int = 20, category: String? = nil,
              status: String? = nil, farmId: UUID? = nil) async throws -> PaginatedList<PlantReportOut> {
        try await client.request(PaginatedList<PlantReportOut>.self,
            endpoint: APIRoute.reports(page: page, pageSize: pageSize, category: category, status: status, farmId: farmId))
    }

    func detail(_ id: UUID) async throws -> PlantReportOut {
        try await client.request(PlantReportOut.self, endpoint: APIRoute.report(id))
    }

    func delete(_ id: UUID) async throws {
        try await client.requestVoid(APIRoute.reportDelete(id))
    }
}
```

- [ ] **Step 4: AIService.swift**

```swift
import Foundation
import UIKit

struct AIService: Sendable {
    let client: APIClient

    func diagnose(image: UIImage, crop: String?, symptomNotes: String?) async throws -> DiagnosisOut {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else { throw APIError.unknown }
        var builder = MultipartFormDataBuilder()
        builder.appendFile("image", data: jpegData, filename: "scan.jpg", mimeType: "image/jpeg")
        if let crop { builder.append("crop", crop) }
        if let symptomNotes { builder.append("symptom_notes", symptomNotes) }
        return try await client.upload(DiagnosisOut.self,
            endpoint: APIRoute.diagnose, body: builder.httpBody, contentType: builder.contentType)
    }
}
```

- [ ] **Step 5: RadarFeedService.swift + NotificationService.swift + OrderService.swift**

`RadarFeedService.swift`:
```swift
import Foundation

struct RadarFeedService: Sendable {
    let client: APIClient

    func feed(lat: Double? = nil, long: Double? = nil, radiusKm: Double = 10,
              category: String? = nil, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<FeedReportOut> {
        try await client.request(PaginatedList<FeedReportOut>.self,
            endpoint: APIRoute.radarFeed(lat: lat, long: long, radiusKm: radiusKm, category: category, page: page, pageSize: pageSize))
    }

    func detail(_ id: UUID) async throws -> PlantReportOut {
        try await client.request(PlantReportOut.self, endpoint: APIRoute.feedDetail(id))
    }

    func mapReports(minLat: Double? = nil, maxLat: Double? = nil,
                    minLong: Double? = nil, maxLong: Double? = nil,
                    category: String? = nil) async throws -> MapItemsOut {
        try await client.request(MapItemsOut.self,
            endpoint: APIRoute.mapReports(minLat: minLat, maxLat: maxLat, minLong: minLong, maxLong: maxLong, category: category))
    }
}
```

`NotificationService.swift`:
```swift
import Foundation

struct NotificationService: Sendable {
    let client: APIClient

    func list(page: Int = 1, pageSize: Int = 20, unreadOnly: Bool = false) async throws -> PaginatedList<NotificationOut> {
        try await client.request(PaginatedList<NotificationOut>.self,
            endpoint: APIRoute.notifications(page: page, pageSize: pageSize, unreadOnly: unreadOnly))
    }
    func markRead(_ id: UUID) async throws -> NotificationOut {
        try await client.request(NotificationOut.self, endpoint: APIRoute.notificationRead(id))
    }
    func markAllRead() async throws {
        try await client.requestVoid(APIRoute.notificationsReadAll)
    }
}
```

`OrderService.swift`:
```swift
import Foundation

struct OrderService: Sendable {
    let client: APIClient

    func list(page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<PesticideOrderOut> {
        try await client.request(PaginatedList<PesticideOrderOut>.self, endpoint: APIRoute.orders(page: page, pageSize: pageSize))
    }
    func create(_ order: PesticideOrderCreate) async throws -> PesticideOrderOut {
        let body = try APICoder.encoder.encode(order)
        return try await client.request(PesticideOrderOut.self, endpoint: APIRoute.ordersCreate.withBody(body))
    }
}
```

- [ ] **Step 6: Delete UploadService.swift + ReportHistoryStore.swift**

Karena fungsi upload masuk ke ReportService, history via ReportService.list.

- [ ] **Step 7: Build verify**

Masih gagal karena AppEnvironment + VM refer lama. Lanjut Task 8.

---

## Task 8: AppEnvironment + RadarTaniApp + ContentView wiring dasar

**Files:**
- Rewrite: `RadarTaniMobile/App/AppEnvironment.swift`, `RadarTaniMobile/RadarTaniApp.swift`
- Modify: `RadarTaniMobile/App/ContentView.swift`

**Interfaces:**
- Consumes: semua Service + AuthSession + APIClient.
- Produces: `AppEnvironment` (`@Observable`, injected via `.environment`) untuk semua View/VM.

- [ ] **Step 1: Rewrite AppEnvironment.swift**

```swift
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let apiClient: APIClient
    let auth: AuthService
    let farms: FarmService
    let reports: ReportService
    let feed: RadarFeedService
    let notifications: NotificationService
    let orders: OrderService
    let ai: AIService
    let session: AuthSession

    init(baseURL: URL = AppConfig.apiBaseURL) {
        let tokenStore = KeychainTokenStore()
        let session = AuthSession(tokenStore: tokenStore)
        let client = APIClient(baseURL: baseURL, tokenStore: tokenStore, session: session)
        self.apiClient = client
        self.auth = AuthService(client: client)
        self.farms = FarmService(client: client)
        self.reports = ReportService(client: client)
        self.feed = RadarFeedService(client: client)
        self.notifications = NotificationService(client: client)
        self.orders = OrderService(client: client)
        self.ai = AIService(client: client)
        self.session = session
    }
}
```

- [ ] **Step 2: Rewrite RadarTaniApp.swift**

```swift
import SwiftUI

@main
struct RadarTaniApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(environment)
        }
    }
}
```

- [ ] **Step 3: Modify ContentView.swift (minimal — auth gate via AuthSession)**

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.session.isRestoring {
                RTDLoadingView()
            } else if env.session.isAuthenticated {
                MainTabView(onLogout: { Task { await logout() } })
            } else {
                NavigationStack {
                    LoginView()
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .registerFarmer: RegisterView()
                            }
                        }
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: env.session.isAuthenticated)
    }

    private func logout() async {
        try? await env.auth.logout()   // best-effort
        env.session.logout()
    }
}

enum AuthRoute: Hashable { case registerFarmer }
```

Note: `MainTabView` signature sementara dibuat `init(onLogout:)`. Child tab view akan baca `@Environment(AppEnvironment.self)` sendiri. Update `MainTabView` di task view wiring.

- [ ] **Step 4: Build verify**

Build masih gagal karena `MainTabView` + semua VM merujuk mock API lama. Lanjut Task 9-10 yang bersamaan memperbaiki semua — bangun kembali sukses di Task 10.

---

## Task 9: ViewModel wiring (8 area)

**Files:**
- Rewrite semua: `Features/*/ViewModels/*.swift` (lihat daftar di File Structure)
- Create: `Features/Profile/ViewModels/OrderListViewModel.swift`

**Interfaces:**
- Consumes: AppEnvironment (via @Environment di View, lewat ke VM init) + semua Service.
- Produces: VM method async untuk View panggil.

Implementasi detail per VM. Pattern seragam: `@MainActor @Observable final class`, init `(env: AppEnvironment)` simpan service, method async `load/submit`.

- [ ] **Step 1: LoginViewModel.swift**

```swift
import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage: String?
    var isLoading = false

    private let auth: AuthService
    private let session: AuthSession

    init(env: AppEnvironment) {
        self.auth = env.auth; self.session = env.session
    }

    func login() async -> Bool {
        guard !isLoading else { return false }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { errorMessage = "Masukkan email terlebih dahulu."; return false }
        guard !password.isEmpty else { errorMessage = "Masukkan password terlebih dahulu."; return false }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.login(email: trimmedEmail, password: password)
            session.didAuthenticate(token)
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal masuk."
            return false
        }
    }
}
```

- [ ] **Step 2: RegisterViewModel.swift** (mirip — panggil `auth.register`, on success `didAuthenticate`)

```swift
import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var cooperativeName = ""
    var farmLocation = ""
    var errorMessage: String?
    var isLoading = false

    private let auth: AuthService
    private let session: AuthSession
    init(env: AppEnvironment) { self.auth = env.auth; self.session = env.session }

    func register() async -> Bool {
        guard !isLoading else { return false }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "Nama wajib diisi."; return false }
        guard !trimmedEmail.isEmpty else { errorMessage = "Email wajib diisi."; return false }
        guard password.count >= 6 else { errorMessage = "Password minimal 6 karakter."; return false }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.register(
                name: name, email: trimmedEmail, password: password,
                cooperativeName: cooperativeName.isEmpty ? nil : cooperativeName,
                farmLocation: farmLocation.isEmpty ? nil : farmLocation)
            session.didAuthenticate(token)
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal mendaftar."
            return false
        }
    }
}
```

- [ ] **Step 3: HomeViewModel.swift**

```swift
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var farmCount = 0
    private(set) var recentReports: [FeedReportOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let farms: FarmService
    private let feed: RadarFeedService
    init(env: AppEnvironment) { self.farms = env.farms; self.feed = env.feed }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            async let farmPage = farms.farms(page: 1, pageSize: 1)
            async let feedPage = feed.feed(radiusKm: 5, page: 1, pageSize: 3)
            let (f, r) = try await (farmPage, feedPage)
            farmCount = f.total
            recentReports = r.items
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat data."
        }
    }
}
```

- [ ] **Step 4: FarmListViewModel.swift + AddFarmViewModel.swift**

`FarmListViewModel.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
final class FarmListViewModel {
    private(set) var farms: [FarmOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let farmService: FarmService
    init(env: AppEnvironment) { self.farmService = env.farms }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do { farms = try await farmService.farms().items } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat lahan."
        }
    }
    func delete(_ id: UUID) async {
        do { try await farmService.delete(id); await load() } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal menghapus lahan."
        }
    }
}
```

`AddFarmViewModel.swift` (rewrite — ganti empty form state jadi create):
```swift
import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class AddFarmViewModel {
    var name = ""; var crop = ""; var location = ""
    var coordinate: Coordinate?
    var isActive = true
    var isLoading = false
    var errorMessage: String?

    private let farmService: FarmService
    init(env: AppEnvironment) { self.farmService = env.farms }

    func save() async -> Bool {
        guard !name.isEmpty, !crop.isEmpty, !location.isEmpty else {
            errorMessage = "Nama, tanaman, dan lokasi wajib diisi."; return false
        }
        isLoading = true; defer { isLoading = false }
        do {
            _ = try await farmService.create(FarmCreate(
                name: name, crop: crop, location: location,
                coordinate: coordinate, isActive: isActive))
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal menambah lahan."
            return false
        }
    }
}
```

- [ ] **Step 5: PlantScanViewModel.swift (tambah submit) — sisanya tetap**

Tambah properti + method submit. Sisanya (camera/picker logic) tetap.

Di class `PlantScanViewModel`, hapus `activeFarm` hardcoded, tambah:
```swift
private(set) var createdReport: PlantReportOut?
private(set) var isLoading = false
private(set) var errorMessage: String?
private let reportService: ReportService
private let farmService: FarmService
init(env: AppEnvironment) {
    self.reportService = env.reports
    self.farmService = env.farms
}

func submitReport(title: String, category: String, description: String?, farmId: UUID?,
                  latitude: Double?, longitude: Double?) async {
    guard let image = selectedImage else { errorMessage = "Pilih foto dulu."; return }
    isLoading = true; defer { isLoading = false }
    do {
        createdReport = try await reportService.create(
            image: image, title: title, category: category, description: description,
            farmId: farmId, latitude: latitude, longitude: longitude, publishToFeed: true)
    } catch {
        errorMessage = (error as? APIError)?.userMessage ?? "Gagal mengirim laporan."
    }
}

var activeFarm: FarmOut?
func loadActiveFarm() async {
    let page = try? await farmService.farms(page: 1, pageSize: 100)
    activeFarm = page?.items.first { $0.isActive } ?? page?.items.first
}
```

Step ini juga: update init VM lama tanpa params → bila View pakai `@State private var viewModel = PlantScanViewModel()` harus jadi `@Environment(AppEnvironment.self) var env; @State var viewModel: PlantScanViewModel` dengan `.init(env: env)`. Lihat Task 10 wiring View.

- [ ] **Step 6: RadarFeedViewModel.swift + ReportDetailViewModel.swift**

`RadarFeedViewModel.swift`:
```swift
import Observation

@MainActor
@Observable
final class RadarFeedViewModel {
    private(set) var reports: [FeedReportOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var selectedCategory: String?
    private(set) var availableCategories: [String] = []
    private let feed: RadarFeedService
    let feedRadius = "10 km"
    init(env: AppEnvironment) { self.feed = env.feed }

    var filteredReports: [FeedReportOut] {
        guard let selectedCategory else { return reports }
        return reports.filter { $0.category == selectedCategory }
    }
    var selectedCategoryTitle: String { selectedCategory ?? "Semua Laporan" }

    func load(lat: Double? = nil, long: Double? = nil) async {
        isLoading = true; defer { isLoading = false }
        do {
            let page = try await feed.feed(lat: lat, long: long, radiusKm: 10,
                                           category: selectedCategory, page: 1, pageSize: 20)
            reports = page.items
            availableCategories = Array(Set(page.items.map(\.category))).sorted()
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat feed."
        }
    }
    func refresh(lat: Double? = nil, long: Double? = nil) async {
        selectedCategory = nil; await load(lat: lat, long: long)
    }
}
```

`ReportDetailViewModel.swift`:
```swift
import Observation

@MainActor
@Observable
final class ReportDetailViewModel {
    private(set) var report: PlantReportOut?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let feed: RadarFeedService
    init(env: AppEnvironment) { self.feed = env.feed }

    func load(id: UUID) async {
        isLoading = true; defer { isLoading = false }
        do { report = try await feed.detail(id) } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat detail."
        }
    }
}
```

- [ ] **Step 7: RadarMapViewModel.swift**

```swift
import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class RadarMapViewModel {
    private(set) var reports: [MapReportOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let feed: RadarFeedService

    let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.7956, longitude: 110.3695),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

    init(env: AppEnvironment) { self.feed = env.feed }

    func load(region: MKCoordinateRegion? = nil) async {
        isLoading = true; defer { isLoading = false }
        let minLat: Double? = region.map { $0.center.latitude - $0.span.latitudeDelta/2 }
        let maxLat: Double? = region.map { $0.center.latitude + $0.span.latitudeDelta/2 }
        let minLong: Double? = region.map { $0.center.longitude - $0.span.longitudeDelta/2 }
        let maxLong: Double? = region.map { $0.center.longitude + $0.span.longitudeDelta/2 }
        do {
            let items = try await feed.mapReports(minLat: minLat, maxLat: maxLat, minLong: minLong, maxLong: maxLong)
            reports = items.items
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat peta."
        }
    }
}
```

Note: `RadarMapReport` struct lama di file ini dihapus — pakai `MapReportOut` langsung di View (Task 10).

- [ ] **Step 8: NotificationListViewModel.swift**

```swift
import Observation

@MainActor
@Observable
final class NotificationListViewModel {
    private(set) var items: [NotificationOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let notifications: NotificationService
    init(env: AppEnvironment) { self.notifications = env.notifications }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do { items = try await notifications.list().items } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat notifikasi."
        }
    }
    func markRead(_ id: UUID) async { _ = try? await notifications.markRead(id); await load() }
    func markAllRead() async { try? await notifications.markAllRead(); await load() }
}
```

- [ ] **Step 9: ProfileViewModel.swift + OrderListViewModel.swift**

`ProfileViewModel.swift`:
```swift
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let session: AuthSession
    var notificationsEnabled = true
    init(env: AppEnvironment) { self.session = env.session }

    var name: String { session.currentUser?.name ?? "Petani" }
    var cooperative: String { session.currentUser?.cooperativeName ?? "Koperasi" }
    var email: String { session.currentUser?.email ?? "" }
}
```

`RadarTaniMobile/Features/Profile/ViewModels/OrderListViewModel.swift` (new):
```swift
import Foundation
import Observation

@MainActor
@Observable
final class OrderListViewModel {
    private(set) var orders: [PesticideOrderOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let ordersService: OrderService
    init(env: AppEnvironment) { self.ordersService = env.orders }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do { orders = try await ordersService.list().items } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat pesanan."
        }
    }
    func create(productName: String, quantity: Int, relatedReportId: UUID? = nil) async -> Bool {
        do {
            _ = try await ordersService.create(PesticideOrderCreate(
                productName: productName, quantity: quantity, relatedReportId: relatedReportId))
            await load(); return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal membuat pesanan."
            return false
        }
    }
}
```

- [ ] **Step 10: Build verify (checkpoint besar)**

Jalankan build sekarang. Akan banyak error terkait View yang belum update signature VM init. Lanjut Task 10 — perbaiki View wiring semua. Lakukan di satu siklus; setelah Task 10 build harus sukses.

---

## Task 10: View wiring (construct VM with env, ganti mock Image → RTDAsyncImage)

**Files:**
- Create: `RadarTaniMobile/Core/Image/RTDAsyncImage.swift`
- Modify: View files terkait (lihat File Structure).

Pattern VM init via env:
```swift
struct SomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: SomeViewModel
    init() { _viewModel = State(initialValue: SomeViewModel(env: <placeholder>)) }
    var body: some View { ... }
}
```
Tapi `@Environment` tidak tersedia di init. Workaround iOS 17+: pakai struct holder atau init lazily. Pattern yang dianjurkan: View terima ViewModel via `.onAppear` atau pakai helper environment override. Sederhana: baca env di `body` pertama lewat custom init dengan `EnvironmentValues` — tidak trivial.

**Pendekatan lazy (rekomendasi):** View pakai `@Environment(AppEnvironment.self) var env` + VM jadi optional sampai pertama diakses. Karena `@Observable` & `@MainActor`, gunakan pattern `@State` + `init(env:)` via `.onAppear`:

```swift
struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = FarmListViewModelHolder()

    var body: some View {
        Content(farms: viewModel.farms, isLoading: viewModel.isLoading, error: viewModel.errorMessage)
            .task(id: "init") {
                if viewModel.service == nil { viewModel.attach(env: env) }
                if viewModel.farms.isEmpty { await viewModel.loadIfAttached() }
            }
    }
}
```
Terlalu ribet. **Pilih pendekatan paling simpel:** bungkus VM factory via environment dengan closure.

Definisikan di AppEnvironment extension method helper:
```swift
extension AppEnvironment {
    func makeFarmListVM() -> FarmListViewModel { FarmListViewModel(env: self) }
    // ... untuk setiap VM
}
```
View pakai `.task` untuk construct:
```swift
@State private var viewModel: FarmListViewModel?
var body: some View {
    if let viewModel { ContentViewBody(vm: viewModel) }
    .task { if viewModel == nil { viewModel = env.makeFarmListVM(); await viewModel.load() } }
}
```
Pendekatan `@State` optional + `.task` construct adalah idiomatik untuk inject environment async. Pakai ini di semua View.

- [ ] **Step 1: Buat RTDAsyncImage.swift**

`RadarTaniMobile/Core/Image/RTDAsyncImage.swift`:
```swift
import SwiftUI

struct RTDAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty: RTDLoadingView()
                case .success(let img): img.resizable().aspectRatio(contentMode: contentMode)
                case .failure: placeholder
                @unknown default: placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Color(.secondarySystemBackground))
            Image(systemName: "photo").foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 2: Update MainTabView.swift**

`MainTabView` signature jadi `init(onLogout: () -> Void)`. Hapus `userEmail` dan `reportHistoryStore`. Child view (`HomeView`, `FarmListView`, `PlantScanView`, `RadarFeedView`, `RadarMapView`) baca `@Environment(AppEnvironment.self)` sendiri. Profile sheet juga baca env. Tombol logout:
```swift
Button { onLogout() } label: { ... }
```
Passing: `MainTabView(onLogout: { Task { try? await env.auth.logout(); env.session.logout() } })` dari ContentView (sudah di Task 8). Atau di MainTabView panggil env langsung.

Karena setiap child tab ambil env dari environment, MainTabView hanya:
```swift
struct MainTabView: View {
    let onLogout: () -> Void
    @State private var selectedTab: MainTab = .home
    @State private var isShowingProfileSheet = false
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(selectedTab: $selectedTab).toolbar { ... } }
                .tabItem { Label("Beranda", systemImage: "house.fill") }.tag(MainTab.home)
            NavigationStack { FarmListView() }
                .tabItem { Label("Lahan", systemImage: "leaf.fill") }.tag(MainTab.farms)
            NavigationStack { PlantScanView() }
                .tabItem { Label("Lapor", systemImage: "camera.fill") }.tag(MainTab.plantScan)
            NavigationStack { RadarFeedView() }
                .tabItem { Label("Radar", systemImage: "antenna.radiowaves.left.and.right") }.tag(MainTab.radarFeed)
            NavigationStack { RadarMapView() }
                .tabItem { Label("Peta", systemImage: "map.fill") }.tag(MainTab.map)
        }
        .sheet(isPresented: $isShowingProfileSheet) { ProfileView(onLogout: onLogout) }
    }
}
```
Edit file `MainTabView.swift` sesuai. Hapus parameter `userEmail`/`reportHistoryStore` dari call site (`PlantScanView(reportHistoryStore:)` jadi `PlantScanView()`).

- [ ] **Step 3: Update HomeView.swift + HomeViewModel usage**

`HomeViewModel` punya `farmCount`, `recentReports: [FeedReportOut]`. HomeView pakai pattern `.task` construct + `.task { await viewModel.load() }`. Untuk mock UI yang masih pakai `RadarReport` (category icon/color), map ke `FeedReportOut` (category String raw, hardcode icon fallback bila perlu — gunakan extension `FeedReportOut.categoryIcon`/`categoryColor`).

Tambah extension:
```swift
extension FeedReportOut {
    var categoryColor: Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        case "Bibit": RTDColor.primaryGreen
        case "Kerja Tani": RTDColor.infoBlue
        default: RTDColor.infoBlue
        }
    }
}
```
Tempatkan extension di file `FeedReportOut.swift`.

- [ ] **Step 4: Update FarmListView + AddFarmView + EditFarmView**

`FarmListView` construct `FarmListViewModel` via `.task`, call `load()`, list `FarmOut` (.Field: name/crop/location/isActive). AddFarmView construct `AddFarmViewModel`, call `save()` bila sukses `.dismiss()`.

- [ ] **Step 5: Update PlantScanView + CreatePlantReportView + PlantDiagnosisResultView**

`PlantScanView` construct VM via `.task`, `loadActiveFarm()`. Kamera logic (sudah ada, tetap). Setelah `selectedImage` set + navigate ke `CreatePlantReportView`.

`CreatePlantReportView` construct `PlantScanViewModel` (atau bawa via navigation), form `PlantReportDraft` (category enum input tetap `PlantReportCategory` — rawValue "Penyakit/Hama/Lainnya" sebagai string), tombol Kirim → `viewModel.submitReport(...)` → tunggu 5-10s → show loading → bila `createdReport` non-nil → `PlantDiagnosisResultView(report: createdReport)`.

`PlantDiagnosisResultView` terima `PlantReportOut`, tampilkan `diagnosis` (bila null → "Analisis sedang berjalan"), pakai `RTDAsyncImage(url: report.imageUrl)`.

- [ ] **Step 6: Update RadarFeedView + item card views**

Ganti mock `reports: [RadarReport]` → `viewModel.reports: [FeedReportOut]`. Category filter chip pakai `viewModel.availableCategories` (String). Ganti mock `Image(...)` → `RTDAsyncImage(url: item.imageUrl)`. WaktuAgo: format dari `item.createdAt` via `DateFormatter`.

Hapus `CreateLaborReportViewModel` + `CreateSeedReportViewModel` draf lokal (bukan scope backend — backend hanya plant-reports 3 kategori). Bila tetap mau UI, redirect ke CreatePlantReportView dengan category `Lainnya`. Decision MVP: hapus dua file ini + dua View terkait (`CreateLaborReportView`, `CreateSeedReportView`), dan dari MainTabView/navigation jika ada.

- [ ] **Step 7: Update RadarMapView**

Ganti mock `reports: [RadarMapReport]` → `viewModel.reports: [MapReportOut]`. MapKit `Annotation` per `MapReportOut.coordinate`. Color per `category` via helper extension serupa FeedReportOut.

- [ ] **Step 8: Update NotificationListView + NotificationDetailView**

Construct `NotificationListViewModel` via `.task`, `load()`. List `NotificationOut`. Tombol "Tandai Semua Dibaca" → `markAllRead()`. Tap item → markRead + navigate detail.

- [ ] **Step 9: Update ProfileView + ReportHistoryView**

`ProfileView` construct `ProfileViewModel`, baca `name/cooperative/email`. Tombol Logout → panggil `onLogout` closure (dari MainTabView → ContentView logout flow). Sheet/menu "Pesanan Pestisida" → `OrderListView`.

`ReportHistoryView` construct `ReportService` via env, load via `reportService.list()`, tampilkan `[PlantReportOut]` → map ke `ReportHistoryItem(from:)` untuk view yang ada (atau langsung pakai `PlantReportOut`).

- [ ] **Step 10: Buat OrderListView.swift**

`RadarTaniMobile/Features/Profile/Views/OrderListView.swift`:
```swift
import SwiftUI

struct OrderListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: OrderListViewModel?

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.orders) { order in
                    VStack(alignment: .leading) {
                        Text(order.productName).font(.headline)
                        Text("\(order.quantity) unit").font(.subheadline)
                        Text(order.status).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Pesanan Pestisida")
        .task {
            if viewModel == nil { viewModel = env.makeOrderListVM() }
            await viewModel?.load()
        }
        .overlay { if let viewModel, viewModel.isLoading { RTDLoadingView() } }
    }
}
```
Tambah `makeOrderListVM()` di AppEnvironment extension (Task 11 helper — sebenarnya dipakai Step ini, jadi tambah sekarang di file AppEnvironment atau file helper). Untuk konsisten, buat extension `AppEnvironment` factory semua VM di file `RadarTaniMobile/App/AppEnvironment+VMFactory.swift`:
```swift
import Foundation
extension AppEnvironment {
    func makeLoginVM() -> LoginViewModel { .init(env: self) }
    func makeRegisterVM() -> RegisterViewModel { .init(env: self) }
    func makeHomeVM() -> HomeViewModel { .init(env: self) }
    func makeFarmListVM() -> FarmListViewModel { .init(env: self) }
    func makeAddFarmVM() -> AddFarmViewModel { .init(env: self) }
    func makePlantScanVM() -> PlantScanViewModel { .init(env: self) }
    func makeRadarFeedVM() -> RadarFeedViewModel { .init(env: self) }
    func makeReportDetailVM() -> ReportDetailViewModel { .init(env: self) }
    func makeRadarMapVM() -> RadarMapViewModel { .init(env: self) }
    func makeNotificationListVM() -> NotificationListViewModel { .init(env: self) }
    func makeProfileVM() -> ProfileViewModel { .init(env: self) }
    func makeOrderListVM() -> OrderListViewModel { .init(env: self) }
}
```
Buat file ini pada Step 10 (sebelum build). Semua View pakai factory ini di `.task { if viewModel == nil { viewModel = env.makeXxxVM() } }`.

- [ ] **Step 11: Delete file yang sudah ditinggal**

- Hapus `RadarTaniMobile/Services/ReportHistoryStore.swift` (sudah di Task 7, pastikan).
- Hapus `Features/RadarFeed/ViewModels/CreateLaborReportViewModel.swift`, `CreateSeedReportViewModel.swift` + view `CreateLaborReportView.swift`, `CreateSeedReportView.swift` bila ada.
- Hapus `RadarTaniMobile/App/AppState.swift` bila tidak terpakai.

- [ ] **Step 12: Build verify (CHECKPOINT FINAL)**

Run: `xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 16' -skipMacroValidation build 2>&1 | tail -40`
Expected: `BUILD SUCCEEDED`.

Bila gagal: perbaiki error satu per satu (kategori besar: type mismatch `RadarReport`→`FeedReportOut`, init signature VM, missing env). Ulang build.

---

## Task 11: Smoke Test Manual + Smoke Doc

**Files:**
- Create: `RadarTaniMobile/Services/__IntegrationSmoke.md`

**Interfaces:**
- Produces: checklist verifikasi end-to-end.

- [ ] **Step 1: Start backend demo**

Terminal backend: `cd backend && uv run fastapi dev app/main.py`. Verify `http://127.0.0.1:8000/docs` load + `GET /health` 200.

- [ ] **Step 2: Run backend pytest (baseline)**

Run: `cd backend && uv run pytest --cov=app 2>&1 | tail -20`
Expected: all pass (backend tidak diubah, harus tetap hijau).

- [ ] **Step 3: Build & run iOS Simulator**

Run dari Xcode: Run target RadarTaniMobile ke "iPhone 16" Simulator.

- [ ] **Step 4: Smoke flow 1 — Register petani baru**

Form register: isi nama/email/password/cooperative/farm-location → submit. Expect: loading → sukses → MainTabView muncul (session AuthSession terisi, keychain tersimpan).

- [ ] **Step 5: Smoke flow 2 — Add Farm**

Tab Lahan → tambah (nama "Sawah Uji", tanaman "Padi", lokasi "Desa Uji", isActive true) → submit. Expect: farm muncul di list (reload dari backend `GET /farms`).

- [ ] **Step 6: Smoke flow 3 — Upload laporan (PlantScan)**

Tab Lapor → Ambil Foto (kamera/galeri simulator pakai galeri) → isi judul "Daun cabai uji", category "Hama", deskripsi → Kirim. Expect: loading 5-10s → PlantDiagnosisResultView muncul dengan diagnosis (confidence int, recommendation), foto thumbnail via `RTDAsyncImage` load dari `http://127.0.0.1:8000/media/...`.

- [ ] **Step 7: Smoke flow 4 — Radar Feed**

Tab Radar → list muncul (FeedReportOut), AsyncImage load, filter category chip muncul dari loaded items.

- [ ] **Step 8: Smoke flow 5 — Peta**

Tab Peta → annotations marker MapKit muncul (MapReportOut) di sekitar Yogyakarta default region.

- [ ] **Step 9: Smoke flow 6 — Notifikasi**

Profile/menu atau tab → Notifikasi → list (mungkin kosong walau admin belum verify — OK). Bila admin verify laporan dari backend Swagger `/dashboard/reports/{id}/verify-broadcast`, notifikasi muncul setelah refresh. Tap → markRead.

- [ ] **Step 10: Smoke flow 7 — Pesan Pestisida**

Dari ReportDetail atau Profile menu "Pesanan Pestisida" → OrderListView. Form/tombol buat order (product_name, quantity, related_report_id) → submit → muncul di list.

- [ ] **Step 11: Smoke flow 8 — Logout**

Profile → Logout → kembali ke LoginView (keychain cleared). Buka ulang app → session hilang → harus login lagi.

- [ ] **Step 12: Tulis __IntegrationSmoke.md**

`RadarTaniMobile/Services/__IntegrationSmoke.md`:
```markdown
# Integration Smoke Test Checklist

Pre-req: backend demo jalan (`cd backend && uv run fastapi dev app/main.py`), simulator iPhone 16, Debug build.

## Backend baseline
- [ ] `GET http://127.0.0.1:8000/health` → 200 {"status":"ok"}
- [ ] `cd backend && uv run pytest --cov=app` → all pass

## Build
- [ ] `xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 16' build` → BUILD SUCCEEDED

## Flow (urut)
1. [ ] Register petani baru → MainTabView muncul
2. [ ] Tambah Farm → list reload dari backend
3. [ ] Upload laporan PlantScan → diagnosis muncul + foto AsyncImage
4. [ ] Radar Feed list muncul + foto load
5. [ ] Peta annotations muncul
6. [ ] Notifikasi list (mark read works)
7. [ ] Pesan pestisida → list orders
8. [ ] Logout → login screen; reopen → session cleared

## Offline (optional)
- [ ] Airplane mode → RTDErrorView "Tidak ada koneksi internet"
```

- [ ] **Step 13: Final build verify**

Run: `xcodebuild ... build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 14: Commit (HANYA bila user konfirmasi)**

```bash
git add -A
git commit -m "feat: full integrasi backend-iOS (auth, farms, reports, feed, map, notifications, orders)

- APIClient actor + KeychainTokenStore + 401 single-flight refresh
- MultipartFormDataBuilder file upload untuk plant-reports + diagnose
- Models Codable snake_case (PlantReportOut, FeedReportOut, MapReportOut, dst)
- Services rewrite real API calls; AppEnvironment DI container
- ViewModel wiring 8 area; RTDAsyncImage native; AI sync wait
- ATS NSAllowsLocalNetworking untuk localhost dev

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Self-Review Checklist (jalankan setelah semua task)

- [ ] Spec coverage: 8 area (auth ✓ farm ✓ report ✓ feed ✓ map ✓ notif ✓ orders ✓ devices-skip ✓) — semua ada task.
- [ ] No placeholder: semua code block lengkap, no TBD/TODO.
- [ ] Type consistency: `AuthToken`, `TokenRefresh`, `UserOut`, `FarmOut`/`FarmCreate`/`FarmUpdate`, `PlantReportOut`, `DiagnosisOut`, `FeedReportOut`, `MapReportOut`/`MapItemsOut`, `NotificationOut`, `PesticideOrderOut`/`PesticideOrderCreate`, `PaginatedList<T>`, `APIResponse<T>`, `ErrorResponse`/`ServerError`/`FieldError` — nama konsisten lintas task.
- [ ] Build checkpoint di Task 10 & 11.

## Notes untuk Eksekusi

- Tugas 1-9 fokus rewrite file per layer. Build tidak akan sukses sampai Task 10 (karena type references lintas file). Eksekutor: jalankan Task 1-10 sebagai satu blok, lalu build di Task 10 Step 12. Bila ingin checkpoint per task, susun ulang: lakukan semua type deletion di task yang sama dengan VM rewrite — tapi ini lebih rapuh.
- Pendekatan `.task { if viewModel == nil { viewModel = env.makeXxxVM() } }` adalah idiomatik untuk inject environment ke `@Observable` VM tanpa `init(env:)` di View init (yang tidak punya akses `@Environment`).
- Bila `xcodebuild` simulator "iPhone 16" tidak ada, cek `xcrun simctl list devices available | grep iPhone` dan ganti nama.
- Bila ATS exception via build setting tidak jalan, alternatif: buat file `RadarTaniMobile/SupportingFiles/Info.plist` manual dengan `NSAppTransportSecurity: { NSAllowsLocalNetworking: true }` dan set `INFOPLIST_FILE` di pbxproj (override `GENERATE_INFOPLIST_FILE`). Tapi pertahankan `GENERATE_INFOPLIST_FILE = YES` + build setting bila memungkinkan.