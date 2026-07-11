import Foundation
import UIKit

struct AIService: Sendable {
    let client: APIClient

    func diagnose(image: UIImage, crop: String?, symptomNotes: String?) async throws -> DiagnosisOut {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else { throw APIError.unknown }
        var builder = MultipartFormDataBuilder()
        builder.appendFile("image", data: jpegData, filename: "scan.jpg", mimeType: "image/jpeg")
        if let crop { builder.append("crop", crop) }
        if let symptomNotes { builder.append("symptom_notes", symptomNotes) }
        return try await client.upload(DiagnosisOut.self,
            endpoint: APIRoute.diagnose, body: builder.httpBody, contentType: builder.contentType)
    }

    func chat(message: String, diagnosis: DiagnosisOut) async throws -> String {
        let body = try APICoder.encoder.encode(PlantAIChatRequest(
            message: message,
            diagnosis: PlantAIChatDiagnosis(
                prediction: diagnosis.prediction,
                confidence: diagnosis.confidence,
                symptoms: diagnosis.symptoms,
                recommendation: diagnosis.recommendation
            )
        ))
        let response = try await client.request(
            PlantAIChatResponse.self,
            endpoint: APIRoute.plantAIChat.withBody(body)
        )
        return response.reply
    }
}

nonisolated private struct PlantAIChatRequest: Encodable {
    let message: String
    let diagnosis: PlantAIChatDiagnosis
}

nonisolated private struct PlantAIChatDiagnosis: Encodable {
    let prediction: String
    let confidence: Int
    let symptoms: String
    let recommendation: String
}

nonisolated private struct PlantAIChatResponse: Decodable, Sendable {
    let reply: String
}
