import Foundation

nonisolated struct NotificationOut: Identifiable, Hashable, Codable, Sendable {
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