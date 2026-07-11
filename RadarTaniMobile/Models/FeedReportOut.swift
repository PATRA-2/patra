import Foundation
import SwiftUI

nonisolated struct FeedReportOut: Identifiable, Hashable, Decodable, Sendable {
    let id: UUID
    let category: String
    let distance: String
    let distanceKm: Double
    let title: String
    let summary: String
    let status: String
    let farmName: String
    let coordinate: Coordinate
    let imageUrl: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, distance, title, summary, status
        case distanceKm = "distance_km"
        case farmName = "farm_name"
        case coordinate
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }

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