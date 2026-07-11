import Foundation

nonisolated struct PlantReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let summary: String
    let description: String?
    let status: String
    let farmId: UUID
    let farmName: String
    let coordinate: Coordinate
    let imageUrl: String
    let diagnosis: DiagnosisOut?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, category, summary, description, status
        case farmId = "farm_id"
        case farmName = "farm_name"
        case coordinate
        case imageUrl = "image_url"
        case diagnosis
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}