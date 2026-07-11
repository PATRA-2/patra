import Foundation
import SwiftUI

nonisolated struct ReportHistoryItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: String
    let summary: String
    let status: String
    let farmName: String
    let submittedAt: Date

    init(id: UUID = UUID(), title: String, category: String, summary: String,
         status: String, farmName: String, submittedAt: Date = .now) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.status = status
        self.farmName = farmName
        self.submittedAt = submittedAt
    }

    init(from report: PlantReportOut) {
        self.id = report.id
        self.title = report.title
        self.category = report.category
        self.summary = report.summary
        self.status = report.status
        self.farmName = report.farmName
        self.submittedAt = report.createdAt
    }

    var submittedDateText: String {
        DateFormatter.rtdShortDate.string(from: submittedAt)
    }

    var categoryColor: Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        default: RTDColor.infoBlue
        }
    }
}