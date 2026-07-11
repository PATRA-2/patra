import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var farmCount = 0
    private(set) var recentReports: [FeedReportOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    let feedRadius = "5 km"

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