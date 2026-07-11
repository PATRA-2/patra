import Foundation

nonisolated struct PesticideOrderOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let productName: String
    let quantity: Int
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productName = "product_name"
        case quantity, status
        case createdAt = "created_at"
    }
}

nonisolated struct PesticideOrderCreate: Encodable {
    let productName: String
    let quantity: Int
    let relatedReportId: UUID?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case quantity
        case relatedReportId = "related_report_id"
    }
}