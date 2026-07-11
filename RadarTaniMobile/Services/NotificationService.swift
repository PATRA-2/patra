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