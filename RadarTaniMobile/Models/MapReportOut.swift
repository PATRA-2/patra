import Foundation

nonisolated struct MapReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let status: String
    let coordinate: Coordinate
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, category, status, coordinate
        case createdAt = "created_at"
    }
}

#if canImport(SwiftUI)
import SwiftUI
nonisolated extension MapReportOut {
    var categoryColor: Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        case "Bibit": RTDColor.primaryGreen
        case "Kerja Tani": RTDColor.infoBlue
        default: RTDColor.infoBlue
        }
    }
    var categoryIcon: String {
        switch category {
        case "Hama": "exclamationmark.triangle.fill"
        case "Penyakit": "leaf.fill"
        case "Bibit": "leaf.fill"
        case "Kerja Tani": "person.2.fill"
        default: "mappin.circle.fill"
        }
    }
}
#endif

nonisolated struct MapItemsOut: Decodable {
    let items: [MapReportOut]
}