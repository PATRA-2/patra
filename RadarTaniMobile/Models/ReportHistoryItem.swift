import Foundation
import SwiftUI

struct ReportHistoryItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: String
    let summary: String
    let status: String
    let farmName: String
    let submittedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        summary: String,
        status: String,
        farmName: String,
        submittedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.status = status
        self.farmName = farmName
        self.submittedAt = submittedAt
    }

    var submittedDateText: String {
        DateFormatter.rtdShortDate.string(from: submittedAt)
    }

    var categoryColor: Color {
        switch category {
        case PlantReportCategory.pest.rawValue:
            RTDColor.warningRed
        case PlantReportCategory.disease.rawValue:
            RTDColor.warningOrange
        default:
            RTDColor.infoBlue
        }
    }
}
