import Foundation

nonisolated struct DiagnosisOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let prediction: String
    let confidence: Int
    let symptoms: String
    let recommendation: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, prediction, confidence, symptoms, recommendation
        case createdAt = "created_at"
    }
}

typealias AIPlantDiagnosis = DiagnosisOut