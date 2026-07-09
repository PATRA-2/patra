import UIKit

enum PlantReportCategory: String, CaseIterable, Identifiable {
    case disease = "Penyakit"
    case pest = "Hama"
    case other = "Lainnya"

    var id: String { rawValue }
}

struct PlantReportDraft {
    var title: String = ""
    var description: String = ""
    var category: PlantReportCategory = .disease
    var image: UIImage?
}
