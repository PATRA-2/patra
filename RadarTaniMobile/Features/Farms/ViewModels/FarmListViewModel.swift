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
    func delete(_ id: UUID) async throws {
        try await farmService.delete(id)
        await load()
    }
}