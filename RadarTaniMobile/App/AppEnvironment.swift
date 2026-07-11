import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let apiClient: APIClient
    let auth: AuthService
    let farms: FarmService
    let farmStore: FarmStore
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
        self.farmStore = FarmStore()
        self.reports = ReportService(client: client)
        self.feed = RadarFeedService(client: client)
        self.notifications = NotificationService(client: client)
        self.orders = OrderService(client: client)
        self.ai = AIService(client: client)
        self.session = session
    }
}
