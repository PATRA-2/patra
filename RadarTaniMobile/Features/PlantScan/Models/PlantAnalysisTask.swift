import Foundation
import UIKit

enum PlantAnalysisStatus: String, Hashable {
    case queued
    case uploading
    case analyzing
    case completed
    case failed
    case reported

    var title: String {
        switch self {
        case .queued: "Menunggu"
        case .uploading: "Mengunggah foto"
        case .analyzing: "Analisis berjalan"
        case .completed: "Analisis selesai"
        case .failed: "Analisis gagal"
        case .reported: "Menunggu verifikasi"
        }
    }

    var systemImage: String {
        switch self {
        case .queued: "clock.fill"
        case .uploading: "arrow.up.circle.fill"
        case .analyzing: "sparkles"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .reported: "building.2.crop.circle.fill"
        }
    }

    var isRunning: Bool {
        self == .queued || self == .uploading || self == .analyzing
    }
}

struct PlantAnalysisTask: Identifiable {
    let id: UUID
    let image: UIImage
    let farm: Farm
    let createdAt: Date
    var draft: PlantReportDraft
    var status: PlantAnalysisStatus
    var stageTitle: String
    var progress: Double
    var diagnosis: AIPlantDiagnosis?
    var errorMessage: String?
    var updatedAt: Date
    var attempt: Int
    var chatMessages: [PlantChatMessage]

    init(
        id: UUID = UUID(),
        image: UIImage,
        farm: Farm,
        draft: PlantReportDraft,
        status: PlantAnalysisStatus = .queued,
        stageTitle: String = "Menyiapkan foto tanaman",
        progress: Double = 0.05,
        diagnosis: AIPlantDiagnosis? = nil,
        errorMessage: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        attempt: Int = 0,
        chatMessages: [PlantChatMessage] = []
    ) {
        self.id = id
        self.image = image
        self.farm = farm
        self.draft = draft
        self.status = status
        self.stageTitle = stageTitle
        self.progress = progress
        self.diagnosis = diagnosis
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attempt = attempt
        self.chatMessages = chatMessages
    }
}
