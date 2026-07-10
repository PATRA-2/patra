import Foundation
import Observation

@MainActor
@Observable
final class ReportHistoryStore {
    private(set) var reports: [ReportHistoryItem]

    init(reports: [ReportHistoryItem]? = nil) {
        self.reports = reports ?? Self.sampleReports
    }

    func submit(draft: PlantReportDraft, farmName: String = "Sawah Utara") {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)

        reports.insert(
            ReportHistoryItem(
                title: title,
                category: draft.category.rawValue,
                summary: summary.isEmpty ? "Laporan dikirim dari hasil foto tanaman." : summary,
                status: "Terkirim",
                farmName: farmName
            ),
            at: 0
        )
    }

    static let sampleReports: [ReportHistoryItem] = [
        ReportHistoryItem(
            title: "Waspada hawar daun pada padi",
            category: PlantReportCategory.disease.rawValue,
            summary: "Daun menguning dan bercak cokelat muncul di beberapa petak sawah.",
            status: "Terverifikasi",
            farmName: "Sawah Utara",
            submittedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        ),
        ReportHistoryItem(
            title: "Serangan trips pada cabai",
            category: PlantReportCategory.pest.rawValue,
            summary: "Daun cabai mulai mengeriting dan perlu dipantau oleh petani sekitar.",
            status: "Terkirim",
            farmName: "Kebun Barat",
            submittedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
        )
    ]
}
