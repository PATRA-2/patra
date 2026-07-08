import Foundation

struct NotificationItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var message: String
    var relatedReportID: UUID?

    init(id: UUID = UUID(), title: String, message: String, relatedReportID: UUID? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.relatedReportID = relatedReportID
    }
}
