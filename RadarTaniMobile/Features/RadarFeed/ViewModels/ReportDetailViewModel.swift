import Foundation
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
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            report = try await feed.detail(id)
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat detail."
        }
    }
}
