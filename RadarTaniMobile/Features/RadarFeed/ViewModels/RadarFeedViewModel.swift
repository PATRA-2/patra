import Foundation
import Observation

@MainActor
@Observable
final class RadarFeedViewModel {
    private(set) var reports: [FeedReportOut] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    var selectedCategory: String?
    private(set) var availableCategories: [String] = []

    let feedRadius = "10 km"
    private let feed: RadarFeedService
    init(env: AppEnvironment) { self.feed = env.feed }

    var filteredReports: [FeedReportOut] {
        guard let selectedCategory else { return reports }
        return reports.filter { $0.category == selectedCategory }
    }

    var selectedCategoryTitle: String {
        selectedCategory ?? "Semua Laporan"
    }

    func reportCount(for category: String?) -> Int {
        guard let category else { return reports.count }
        return reports.filter { $0.category == category }.count
    }

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
        guard !isRefreshing else { return }
        isRefreshing = true; defer { isRefreshing = false }
        await load(lat: lat, long: long)
    }
}