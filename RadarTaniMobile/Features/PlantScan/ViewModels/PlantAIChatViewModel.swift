import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlantAIChatViewModel {
    var draftMessage = ""
    var selectedImage: UIImage?
    var diagnosisResult: DiagnosisOut?
    var isLoading = false
    var errorMessage: String?

    private let aiService: AIService
    init(env: AppEnvironment) { self.aiService = env.ai }

    func analyze(image: UIImage, crop: String?, symptomNotes: String?) async {
        isLoading = true; defer { isLoading = false }
        do {
            diagnosisResult = try await aiService.diagnose(image: image, crop: crop, symptomNotes: symptomNotes)
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal menganalisis."
        }
    }
}