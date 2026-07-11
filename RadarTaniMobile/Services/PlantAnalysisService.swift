import Foundation

struct PlantAnalysisRequest: Sendable {
    let title: String
    let description: String
    let category: String
    let crop: String
    let attempt: Int
}

protocol PlantAnalysisService: Sendable {
    func analyze(_ request: PlantAnalysisRequest) async throws -> AIPlantDiagnosis
}

enum PlantAnalysisServiceError: LocalizedError, Sendable {
    case unavailable

    var errorDescription: String? {
        "Analisis AI belum berhasil. Periksa koneksi lalu coba lagi."
    }
}

struct MockPlantAnalysisService: PlantAnalysisService {
    func analyze(_ request: PlantAnalysisRequest) async throws -> AIPlantDiagnosis {
        try await Task.sleep(for: .milliseconds(550))

        if request.attempt == 0 && request.title.localizedCaseInsensitiveContains("simulasi gagal") {
            throw PlantAnalysisServiceError.unavailable
        }

        let prediction: String
        switch request.category {
        case PlantReportCategory.pest.rawValue:
            prediction = "Kemungkinan serangan hama trips"
        case PlantReportCategory.other.rawValue:
            prediction = "Gejala tanaman memerlukan pemeriksaan lanjutan"
        default:
            prediction = "Kemungkinan penyakit bercak daun"
        }

        let symptoms = request.description.trimmingCharacters(in: .whitespacesAndNewlines)

        return AIPlantDiagnosis(
            id: UUID(),
            prediction: prediction,
            confidence: 82,
            symptoms: symptoms.isEmpty
                ? "Daun menunjukkan perubahan warna dan bercak pada beberapa area."
                : symptoms,
            recommendation: "Pisahkan tanaman terdampak, pantau selama 2–3 hari, dan konsultasikan dengan koperasi atau penyuluh bila gejala menyebar pada tanaman (request.crop).",
            createdAt: .now
        )
    }
}
