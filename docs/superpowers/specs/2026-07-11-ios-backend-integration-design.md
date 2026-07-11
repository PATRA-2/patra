# Full Integrasi Backend ↔ iOS RadarTaniMobile

**Status:** Draft — awaiting implementation plan.
**Date:** 2026-07-11
**Scope:** Full update app iOS `RadarTaniMobile` agar seluruh endpoint backend FastAPI terhubung nyata (bukan mock). 8 area: Auth, Farms, Plant Reports, Radar Feed, Map, Notifications, Orders, (Devices skip per keputusan).

## Konteks

Backend FastAPI `patra/backend/` sudah production-grade: JWT HS256, 8 router, multipart upload, AI Gemini, Supabase storage, FCM push. Prefix `/api/v1`. Mode demo (SQLite + `/media/` lokal + AI deterministik) di `http://127.0.0.1:8000`. Kontrak resmi: `docs/api-contract-fastapi.md`.

App iOS `RadarTaniMobile/` saat ini: UI ~90% built dengan **mock data**. Networking di-scaffold (`APIClient`, `APIEndpoint`, `AuthInterceptor`, `TokenStore`, `MultipartFormDataBuilder`) tapi **zero API call**. Semua Service return hardcoded/empty. Models non-Codable. `TokenStore` in-memory. Zero SPM dependency. Base URL `https://api.radar-tani.local` placeholder. Target iOS 26.5. Bundle `com.hendrairawan.dev.RadarTaniMobile`.

## Keputusan (brainstorming)

1. **Lingkup**: Full 8 area sekaligus.
2. **Backend target**: `#if DEBUG` switch — Debug `http://127.0.0.1:8000/api/v1`, Release `https://api.radar-tani.id/api/v1`.
3. **Token storage**: Keychain (Security.framework).
4. **FCM Push**: Skip. In-app notifications only (`GET /notifications` + mark read). Endpoint `/devices` tidak dipanggil. `FCMTokenService` stub tetap. Ponytail: tambah SPM `firebase-ios-sdk` bila push real diperlukan.
5. **Image loader**: `SwiftUI.AsyncImage` native (zero dep). Wrapper `RTDAsyncImage`.
6. **AI diagnosis flow**: Sync tunggu ≤10s. Mode demo deterministik cepat.
7. **Category**: `String` raw verbatim dari backend (bukan enum). Plant-reports input picker hardcoded 3 nilai (Penyakit/Hama/Lainnya); Radar Feed kategori ditampilkan apa adanya.
8. **Testing**: Smoke manual 8 flow di simulator + backend `pytest --cov=app` existing. No XCTest framework baru.
9. **Strategy**: Backend mode demo + ATS exception `NSAllowsLocalNetworking`.

## 1. Arsitektur & Stack

Tetap MVVM `@Observable` yang sudah dibangun. Ganti isi Service yang mock → implementasi `APIClient` nyata. **Zero new SPM dependency** — semua Apple stdlib.

```
RadarTaniMobile/
├── Core/
│   ├── Networking/
│   │   ├── APIClient.swift           (UPGRADE)
│   │   ├── APIEndpoint.swift         (UPGRADE)
│   │   ├── APIError.swift            (REWRITE)
│   │   ├── APIErrorCode.swift        (NEW)
│   │   ├── APIRoute.swift            (NEW: static endpoint factory)
│   │   ├── MultipartFormDataBuilder.swift (REWRITE)
│   │   ├── HTTPMethod.swift          (keep)
│   │   └── NetworkMonitor.swift      (keep)
│   ├── Auth/
│   │   ├── KeychainTokenStore.swift  (NEW)
│   │   ├── AuthSession.swift         (REWRITE)
│   │   ├── AuthInterceptor.swift     (DELETE — logika pindah ke APIClient)
│   │   └── TokenStore.swift          (DELETE — replaced KeychainTokenStore)
│   ├── Image/
│   │   └── RTDAsyncImage.swift       (NEW)
│   ├── Location/ ...                 (keep)
│   └── Utils/ ...                    (keep)
├── Models/                           (REWRITE 9 + new)
│   ├── APIResponse.swift            (REWRITE: generic envelope)
│   ├── ErrorResponse.swift          (NEW)
│   ├── PaginatedList.swift          (NEW)
│   ├── AuthToken.swift              (NEW)
│   ├── TokenRefresh.swift           (NEW)
│   ├── User.swift                   (REWRITE → UserOut)
│   ├── FarmOut.swift                 (NEW: ganti Farm.swift)
│   ├── PlantReport.swift            (NEW)
│   ├── FeedReport.swift             (NEW)
│   ├── MapReport.swift              (NEW)
│   ├── DiagnosisOut.swift           (REWRITE: ganti AIPlantDiagnosis)
│   ├── Coordinate.swift             (keep)
│   ├── NotificationItem.swift       (REWRITE → NotificationOut)
│   ├── PesticideOrder.swift         (REWRITE → PesticideOrderOut)
│   └── ReportHistoryItem.swift      (REWRITE → display factory dari PlantReportOut)
├── Services/
│   ├── AuthService.swift            (NEW)
│   ├── FarmService.swift            (REWRITE)
│   ├── ReportService.swift          (REWRITE)
│   ├── AIService.swift               (REWRITE)
│   ├── RadarFeedService.swift       (NEW)
│   ├── NotificationService.swift    (REWRITE)
│   ├── OrderService.swift           (NEW)
│   ├── UploadService.swift          (DELETE — merged ke ReportService)
│   └── ReportHistoryStore.swift     (DELETE — merged ke ReportService.list)
├── App/
│   ├── AppConstants.swift           (REWRITE: #if DEBUG base URL)
│   ├── AppEnvironment.swift         (REWRITE: real DI container)
│   ├── AppState.swift               (DELETE bila AuthSession cukup)
│   ├── AppRouter.swift              (keep)
│   ├── ContentView.swift            (REWRITE: AuthSession gate + env inject)
│   └── RadarTaniApp.swift           (MODIFY: init env)
├── SupportingFiles/
│   ├── Config.xcconfig             (UPDATE: dokumentasi dua URL)
│   └── GoogleService-Info.plist     (keep placeholder — FCM skip)
├── Resources/ ...                   (keep)
└── Features/                        (MODIFY 8 area)
```

**Stack final**: SwiftUI + Observation `@Observable` + URLSession async/await + Keychain Services (Security.framework) + SwiftUI.AsyncImage + MapKit + UserNotifications (in-app only). **0 SPM package**.

## 2. Networking & Data Flow

### APIClient (actor)

```swift
actor APIClient {
    let baseURL: URL
    let tokenStore: KeychainTokenStore
    let session: URLSession
    private var refreshTask: Task<TokenRefresh, Error>?

    func request<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T
    func upload<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint,
                                         body: Data, contentType: String) async throws -> T
}
```

Flow `request`:
1. Bangun `URLRequest` dari `APIEndpoint` (baseURL + path + query).
2. Bila `auth == .required|.optional`: baca `tokenStore.access()`, set `Authorization: Bearer <token>`. Bila nil dan `.required` → `throw APIError.unauthenticated`.
3. Encode body bila ada (`.json` → `JSONEncoder`, `.multipart` → caller sudah bangun).
4. Kirim `async` via `URLSession`.
5. Decode body:
   - 200–299 + body → `APIResponse<T>.data`.
   - 204 → Void/empty.
   - 4xx/5xx → decode `ErrorResponse` → `throw APIError.server(ServerError)`.
6. Bila 401 dan endpoint punya refresh token dan `endpoint.path != "/auth/refresh"` → single-flight refresh, retry sekali.
7. Bila refresh gagal → `tokenStore.clear()` + `session.logout()` + `throw APIError.unauthenticated`.

### APIEndpoint (upgrade)

```swift
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    var query: [URLQueryItem] = []
    var body: RequestBody?    // .json(Encodable) | .none
    var auth: AuthRequirement // .required | .optional | .public
    var accepts: AcceptsType   // .json | .multipart
}
enum AuthRequirement { case required, optional, public_ }
enum RequestBody { case json(Data) }
enum AcceptsType { case json, multipart }
```

### APIError + ServerError + APIErrorCode

```swift
enum APIError: Error {
    case unauthenticated
    case server(ServerError)
    case network(URLError)
    case decoding(Error)
    case unknown
}
struct ServerError: Decodable {
    let code: String
    let message: String
    let details: [FieldError]?
}
struct FieldError: Decodable { let field: String?; let message: String? }
```
`APIErrorCode` mirror literal backend: `invalidCredentials = "INVALID_CREDENTIALS"`, `emailAlreadyRegistered`, `farmInUse`, `reportAlreadyVerified`, `validationError`, `farmRequired`, `locationRequired`, `aiTimeout`, `aiUnavailable`, dst.

### MultipartFormDataBuilder (rewrite, RFC 7578)

```swift
struct MultipartFormDataBuilder {
    let boundary: String
    private var body = Data()
    init() { boundary = "----RTDBoundary" + UUID().uuidString }
    mutating func append(_ name: String, _ value: String)
    mutating func appendFile(_ name: String, data: Data, filename: String, mimeType: String)
    var httpBody: Data   // body + closing boundary
    var contentType: String  // "multipart/form-data; boundary=..."
}
```

## 3. Models — Codable & Snake-Case Mapping

Tidak pakai `.convertFromSnakeCase` (rapuh untuk nested field). `CodingKeys` eksplisit per model. `JSONDecoder` ISO8601 dengan `[.withInternetDateTime, .withFractionalSeconds]` (safety bila backend kirim nanosec).

### Envelope

```swift
struct APIResponse<T: Decodable>: Decodable { let data: T }
struct ErrorResponse: Decodable { let error: ServerError }
struct PaginatedList<T: Decodable>: Decodable {
    let items: [T]; let page: Int; let pageSize: Int; let total: Int
}
```

### Entitas

```swift
struct AuthToken: Decodable {
    let accessToken: String; let refreshToken: String
    let tokenType: String; let expiresIn: Int
    let user: UserOut?    // ada di login/register, null di refresh
}
struct TokenRefresh: Decodable {
    let accessToken: String; let refreshToken: String
    let tokenType: String; let expiresIn: Int
}
struct UserOut: Decodable, Equatable {
    let id: UUID; let name: String; let email: String; let cooperativeName: String?
}
struct Coordinate: Codable { let latitude: Double; let longitude: Double }
struct FarmOut: Codable, Identifiable {
    let id: UUID; let name: String; let crop: String; let location: String
    let coordinate: Coordinate; let isActive: Bool
    let createdAt: Date; let updatedAt: Date
}
struct FarmCreate: Encodable { let name: String; let crop: String; let location: String
    let coordinate: Coordinate?; let isActive: Bool? }
struct FarmUpdate: Encodable { let name: String?; let crop: String?; let location: String?
    let coordinate: Coordinate?; let isActive: Bool? }
struct PlantReportOut: Decodable, Identifiable {
    let id: UUID; let title: String; let category: String; let summary: String
    let description: String?; let status: String; let farmId: UUID; let farmName: String
    let coordinate: Coordinate; let imageUrl: String; let diagnosis: DiagnosisOut?
    let createdAt: Date; let updatedAt: Date
}
struct DiagnosisOut: Decodable, Identifiable {
    let id: UUID; let prediction: String; let confidence: Int
    let symptoms: String; let recommendation: String; let createdAt: Date
}
struct FeedReportOut: Decodable, Identifiable {
    let id: UUID; let category: String; let distance: String; let distanceKm: Double
    let title: String; let summary: String; let status: String; let farmName: String
    let coordinate: Coordinate; let imageUrl: String; let createdAt: Date
}
struct MapReportOut: Decodable, Identifiable {
    let id: UUID; let title: String; let category: String; let status: String
    let coordinate: Coordinate; let createdAt: Date
}
struct MapItemsOut: Decodable { let items: [MapReportOut] }
struct NotificationOut: Decodable, Identifiable {
    let id: UUID; let title: String; let message: String
    let relatedReportId: UUID?; let isRead: Bool; let createdAt: Date
}
struct PesticideOrderOut: Decodable, Identifiable {
    let id: UUID; let productName: String; let quantity: Int; let status: String; let createdAt: Date
}
struct PesticideOrderCreate: Encodable {
    let productName: String; let quantity: Int; let relatedReportId: UUID?
}
```

Semua pakai `CodingKeys` eksplisit (`is_active`, `created_at`, `image_url`, `farm_id`, `farm_name`, `related_report_id`, `is_read`, `distance_km`, `product_name`, `access_token`, `refresh_token`, `token_type`, `expires_in`, `cooperative_name`).

### Display model factory

Old `ReportHistoryItem` & `RadarReport` tetap sebagai display model `init(from: PlantReportOut)` / `init(from: FeedReportOut)`. Views lama tidak rewrite, cuma pakai factory.

### Category

`category: String` raw. Enum `RadarReportCategory` lama (pest/seed/labor) di-discard. Filter chip RadarFeedView baca distinct values dari loaded items.

## 4. Service Layer & Endpoint Definitions

### APIRoute (static factory di `Core/Networking/APIRoute.swift`)

Semua path terpusat, compiler cek typo:
```swift
enum APIRoute {
    static let health = APIEndpoint(path: "/health", method: .get, auth: .public_)
    static let login = APIEndpoint(path: "/auth/login", method: .post, auth: .public_)
    static let register = APIEndpoint(path: "/auth/register", method: .post, auth: .public_)
    static let refresh = APIEndpoint(path: "/auth/refresh", method: .post, auth: .public_)
    static let logout = APIEndpoint(path: "/auth/logout", method: .post, auth: .required)
    static let me = APIEndpoint(path: "/me", method: .get, auth: .required)
    static func farms(page:Int, pageSize:Int) -> APIEndpoint { ... }
    static let farmsCreate = APIEndpoint(path: "/farms", method: .post, auth: .required)
    static func farmUpdate(_ id: UUID) -> APIEndpoint { ... }
    static func farmDelete(_ id: UUID) -> APIEndpoint { ... }
    static let reportsCreate = APIEndpoint(path: "/plant-reports", method: .post, auth: .required, accepts: .multipart)
    static func reports(...) -> APIEndpoint { ... }
    static func report(_ id: UUID) -> APIEndpoint { ... }
    static func reportUpdate(_ id: UUID) -> APIEndpoint { ... }
    static func reportDelete(_ id: UUID) -> APIEndpoint { ... }
    static let diagnose = APIEndpoint(path: "/plant-diagnoses", method: .post, auth: .required, accepts: .multipart)
    static func radarFeed(...) -> APIEndpoint { ... }
    static func feedDetail(_ id: UUID) -> APIEndpoint { ... }
    static func mapReports(...) -> APIEndpoint { ... }
    static func notifications(...) -> APIEndpoint { ... }
    static func notificationRead(_ id: UUID) -> APIEndpoint { ... }
    static let notificationsReadAll = APIEndpoint(path: "/notifications/read-all", method: .patch, auth: .required)
    static func orders(...) -> APIEndpoint { ... }
    static let ordersCreate = APIEndpoint(path: "/pesticide-orders", method: .post, auth: .required)
}
```

### Services (async, thin, no UI state)

```swift
struct AuthService { let client: APIClient
    func login(email:String, password:String) async throws -> AuthToken
    func register(name:String, email:String, password:String, cooperativeName:String?, farmLocation:String?) async throws -> AuthToken
    func refresh(refreshToken:String) async throws -> TokenRefresh
    func logout() async throws
    func me() async throws -> UserOut
}
struct FarmService { let client: APIClient
    func farms(page:Int=1, pageSize:Int=20) async throws -> PaginatedList<FarmOut>
    func create(_ farm: FarmCreate) async throws -> FarmOut
    func update(_ id: UUID, _ farm: FarmUpdate) async throws -> FarmOut
    func delete(_ id: UUID) async throws
}
struct ReportService { let client: APIClient
    func create(image:Data, filename:String, mimeType:String, title:String, category:String,
                 description:String?, farmId:UUID?, latitude:Double?, longitude:Double?,
                 publishToFeed:Bool) async throws -> PlantReportOut
    func list(...) async throws -> PaginatedList<PlantReportOut>
    func detail(_ id: UUID) async throws -> PlantReportOut
    func update(_ id: UUID, ...) async throws -> PlantReportOut
    func delete(_ id: UUID) async throws
}
struct AIService { let client: APIClient
    func diagnose(image:Data, filename:String, mimeType:String, crop:String?,
                  symptomNotes:String?) async throws -> DiagnosisOut
}
struct RadarFeedService { let client: APIClient
    func feed(lat:Double?, long:Double?, radiusKm:Double=10, category:String?,
              page:Int=1, pageSize:Int=20) async throws -> PaginatedList<FeedReportOut>
    func detail(_ id: UUID) async throws -> PlantReportOut
    func mapReports(minLat:Double?, maxLat:Double?, minLong:Double?, maxLong:Double?,
                    category:String?) async throws -> MapItemsOut
}
struct NotificationService { let client: APIClient
    func list(page:Int=1, pageSize:Int=20, unreadOnly:Bool=false) async throws -> PaginatedList<NotificationOut>
    func markRead(_ id: UUID) async throws -> NotificationOut
    func markAllRead() async throws
}
struct OrderService { let client: APIClient
    func list(page:Int=1, pageSize:Int=20) async throws -> PaginatedList<PesticideOrderOut>
    func create(_ order: PesticideOrderCreate) async throws -> PesticideOrderOut
}
```

### AppEnvironment (real DI container)

```swift
@Observable @MainActor
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
    init(config: AppConfig = .current) {
        let tokenStore = KeychainTokenStore()
        let client = APIClient(baseURL: config.apiBaseURL, tokenStore: tokenStore)
        // initialize all services with client
        self.session = AuthSession(tokenStore: tokenStore)
    }
}
```
Inject ke View via `.environment(...)`. ViewModel init `(env: AppEnvironment)`.

## 5. Auth Session & 401 Refresh Handling

### KeychainTokenStore

```swift
struct KeychainTokenStore {
    private let service = "com.hendrairawan.dev.RadarTaniMobile"
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"
    private let userKey = "cached_user"
    func setAccess(_ token: String)
    func setRefresh(_ token: String)
    func setCachedUser(_ user: UserOut)   // encode JSON
    func access() -> String?
    func refresh() -> String?
    func cachedUser() -> UserOut?         // decode JSON
    func clear()
}
```

API Keychain: `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` dengan `kSecClassGenericPassword`, `kSecAttrService=service`, `kSecAttrAccount=key`, `kSecAttrAccessible=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Sinkron. Ponytail: no app group → single device. Upgrade: app group bila perlu share ke widget.

### AuthSession (`@Observable`)

```swift
@MainActor @Observable
final class AuthSession {
    private let tokenStore: KeychainTokenStore
    private(set) var currentUser: UserOut?
    private(set) var isAuthenticated: Bool = false
    private(set) var isRestoring: Bool = true
    init(tokenStore: KeychainTokenStore) {
        self.tokenStore = tokenStore
        if let user = tokenStore.cachedUser(), tokenStore.access() != nil {
            currentUser = user; isAuthenticated = true
        }
        isRestoring = false
    }
    func didAuthenticate(_ token: AuthToken) {
        tokenStore.setAccess(token.accessToken)
        tokenStore.setRefresh(token.refreshToken)
        if let user = token.user { tokenStore.setCachedUser(user); currentUser = user }
        isAuthenticated = true
    }
    func logout() { tokenStore.clear(); currentUser = nil; isAuthenticated = false }
}
```

### 401 single-flight refresh

Di `APIClient`, bila response 401 dan `endpoint.path != "/auth/refresh"` dan `tokenStore.refresh() != nil`:
1. Cek `refreshTask`. Bila ada → `await` task sama, retry request pakai token baru.
2. Bila belum → buat `Task { try await auth.refresh(refreshToken) }`, simpan `refreshTask`.
3. Sukses → `tokenStore.setAccess` + `setRefresh` (rotasi token), retry request original.
4. Gagal → `tokenStore.clear()` + `session.logout()` + `throw APIError.unauthenticated`.
Endpoint `/auth/refresh` sendiri bila 401 → langsung logout, no meta-refresh.

### App launch flow

```
RadarTaniApp @main
  → @State AppEnvironment = AppEnvironment()
  → ContentView observe env.session.isAuthenticated
    → isRestoring == true → RTDLoadingView (splash, ~10ms sinkron)
    → isAuthenticated == false → AuthLandingView/LoginView
    → isAuthenticated == true → MainTabView
```

### Logout flow

`ProfileView` tap logout → `AuthService.logout()` (best-effort, ignore network error) → `AuthSession.logout()` → ContentView re-render LoginView.

## 6. Per-Feature ViewModel Wiring

Pattern seragam: `@MainActor @Observable final class`, state `isLoading/error/data`, method `async`.

- **Auth** — `LoginViewModel` panggil `auth.login(...)`, `RegisterViewModel` panggil `auth.register(...)`. Map `APIError.userMessage` ke `errorMessage`.
- **Farms** — `FarmListViewModel.load()` → `farmService.farms()`. `AddFarmViewModel` collect → `FarmCreate`. `EditFarmView` → `FarmUpdate` partial.
- **PlantScan** — `PlantScanViewModel.submitReport()` → `reportService.create(...)` (multipart, sync tunggu 5–10s). `PlantAIChatViewModel` → `aiService.diagnose(...)`.
- **RadarFeed** — `RadarFeedViewModel.load()` → `feedService.feed(lat:long:radiusKm:category:)`. `availableCategories` derived dari loaded items.
- **Map** — `RadarMapViewModel.load(boundingBox:)` → `feedService.mapReports(...)`.
- **Notifications** — `NotificationListViewModel.load/markRead/markAllRead` → `notificationService`.
- **Orders** — `OrderListViewModel` baru → `orderService.list/create`. Akses dari Profile menu + sheet dari ReportDetail.
- **Devices** — Skip. `FCMTokenService` stub tetap.
- **Home** — `HomeViewModel.load()` panggil `farmService.farms(page:1,pageSize:1)` + `feedService.feed(radiusKm:5,pageSize:3)`.
- **Profile** — `ProfileViewModel` pakai `session.currentUser`. Logout → `auth.logout()` + `session.logout()`.

### AppConstants (`#if DEBUG`)

```swift
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
`Config.xcconfig` dokumentasi dua URL. Ponytail: bila perlu override tanpa rebuild (QA), pakai Info.plist custom key + baca via `Bundle.main.object(forInfoDictionaryKey:)`.

### Info.plist ATS (generated, `GENERATE_INFOPLIST_FILE = YES`)

Build settings: `INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsLocalNetworking = YES`. Izinkan HTTP ke localhost cuma. HTTPS wajib untuk domain lain.

### RTDAsyncImage

```swift
struct RTDAsyncImage: View {
    let url: String?
    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty: RTDLoadingView()
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                case .failure: ImagePlaceholder()
                @unknown default: ImagePlaceholder()
                }
            }
        } else { ImagePlaceholder() }
    }
}
```
Gantikan semua mock `Image("...")` di FeedReport/PlantReport/item card.

## 7. Error Handling UX, Testing & Migration Checklist

### APIError.userMessage (Indonesia)

Map kode backend → pesan Indonesia. `INVALID_CREDENTIALS` → "Email atau password salah.", `EMAIL_ALREADY_REGISTERED` → "Email sudah terdaftar.", `FARM_IN_USE` → "Lahan masih digunakan laporan.", `REPORT_ALREADY_VERIFIED` → "Laporan sudah diverifikasi.", `VALIDATION_ERROR` → details per field, `FARM_REQUIRED` → "Pilih lahan aktif dulu.", `LOCATION_REQUIRED` → "Aktifkan lokasi atau pilih lahan aktif.", `AI_TIMEOUT` → "Analisis AI melebihi batas waktu, coba lagi.", `AI_UNAVAILABLE` → "Layanan AI sedang tidak tersedia.", fallback `s.message`. `.network` → "Tidak ada koneksi internet."

ViewModel `errorMessage: String?` → bind `RTDErrorView(message:) { retry }`. Loading → `RTDLoadingView`. Empty → `RTDEmptyStateView`. Ketiga komponen sudah ada di DesignSystem.

### Testing

- Backend: `uv run pytest --cov=app` existing (kontrak verify). Tidak tambah test backend.
- iOS: no XCTest. Verify:
  1. `xcodebuild -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 16' build` sukses.
  2. Backend demo jalan: `cd backend && uv run fastapi dev app/main.py`.
  3. Smoke manual simulator 8 flow: login admin demo → tambah farm → upload foto PlantScan (sync diagnosis) → Radar Feed (AsyncImage) → Peta annotations → Notifikasi → pesan pestisida → logout.
  4. `NetworkMonitor` existing → offline state RTDErrorView "Tidak ada koneksi".
- Catat langkah smoke di `Services/__IntegrationSmoke.md`.

### Build verification

`xcodebuild build` sukses sebelum commit. Gitbutler rules: commit hanya bila diminta user.

### Migration checklist — file-by-file

**NEW:**
- `Core/Auth/KeychainTokenStore.swift`
- `Core/Networking/APIRoute.swift`
- `Core/Networking/APIErrorCode.swift`
- `Core/Image/RTDAsyncImage.swift`
- `Models/ErrorResponse.swift`, `PaginatedList.swift`, `AuthToken.swift`, `TokenRefresh.swift`, `PlantReport.swift`, `FeedReport.swift`, `MapReport.swift`
- `Services/AuthService.swift`, `RadarFeedService.swift`, `OrderService.swift`
- `Services/__IntegrationSmoke.md`

**REWRITE:**
- `Core/Networking/APIClient.swift`, `APIEndpoint.swift`, `APIError.swift`, `MultipartFormDataBuilder.swift`
- `Core/Auth/AuthSession.swift`
- `App/AppConstants.swift`, `AppEnvironment.swift`, `ContentView.swift`, `RadarTaniApp.swift`
- `Models/User.swift`, `Farm.swift`→`FarmOut`, `NotificationItem.swift`→`NotificationOut`, `PesticideOrder.swift`→`PesticideOrderOut`, `AIPlantDiagnosis.swift`→`DiagnosisOut`, `ReportHistoryItem.swift` (factory), `APIResponse.swift`
- `Services/FarmService.swift`, `ReportService.swift`, `NotificationService.swift`, `AIService.swift`
- `Features/*/...ViewModel.swift` (8 area)

**DELETE:**
- `Core/Auth/AuthInterceptor.swift`, `Core/Auth/TokenStore.swift`
- `Models/Report.swift`
- `Services/UploadService.swift`, `Services/ReportHistoryStore.swift`
- `App/AppState.swift` (bila AuthSession cukup)

**MODIFY (View):**
- `Features/RadarFeed/*View.swift` (ganti Image → RTDAsyncImage, mock data → ViewModel prop)
- `Features/Map/RadarMapView.swift`
- `Features/PlantScan/PlantDiagnosisResultView.swift`
- `Features/Profile/ReportHistoryView.swift`
- `Features/Notifications/*View.swift`

**CONFIG:**
- `SupportingFiles/Config.xcconfig` (dokumentasi dua URL)
- `project.pbxproj` build settings: `INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsLocalNetworking = YES`, hapus file yang di-delete dari build phase, tambah file baru.

## Non-Goals

- Dashboard admin (router `/dashboard/*`) — app ini sisi petani, bukan admin koperasi.
- FCM push real & `/devices` register — skip per keputusan.
- XCTest framework baru — smoke manual cukup.
- Backend changes — backend sudah production-grade, hanya konsumsi.
- Refactor DesignSystem — pakai komponen yang ada.

## Risiko & Mitigasi

- **Keychain access di simulator**: kadang flaky pertama kali. Mitigasi: fallback UserDefaults bila `SecItemAdd` return `errSecNotAvailable` (ponytail comment).
- **ISO8601 nanosec**: backend SQLAlchemy datetime bisa kirim microsecond. Mitigasi: `ISO8601DateFormatter` dengan `[.withInternetDateTime, .withFractionalSeconds]`.
- **Multipart HEIC**: backend terima `image/heic`+`image/heif`. iOS `UIImage` HEIC encode via `UIGraphicsImageRenderer` JPEG bila HEIC tidak didukung. Default konversi ke JPEG (mimeType `image/jpeg`) — simpel, backend terima.
- **Map bounding box besar**: `mapReports` tanpa bounding box bisa return dataset besar. Mitigasi: default region Yogyakarta, kirim bounding box saat user pan/zoom.

## Selanjutnya

Spec ini → writing-plans skill untuk buat implementation plan task-by-task.