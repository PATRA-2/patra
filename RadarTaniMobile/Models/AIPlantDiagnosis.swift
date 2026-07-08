import Foundation

struct AIPlantDiagnosis: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var prediction: String
    var confidence: Int
    var symptoms: String
    var recommendation: String

    init(id: UUID = UUID(), prediction: String, confidence: Int, symptoms: String, recommendation: String) {
        self.id = id
        self.prediction = prediction
        self.confidence = confidence
        self.symptoms = symptoms
        self.recommendation = recommendation
    }
}
