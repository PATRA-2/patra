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
}