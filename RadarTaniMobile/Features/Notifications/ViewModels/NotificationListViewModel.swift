import Foundation
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