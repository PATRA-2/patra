import Foundation
import SwiftUI

struct Farm: Identifiable, Hashable {
    let id: UUID
    var name: String
    var crop: String
    var location: String
    var coordinate: Coordinate?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        crop: String,
        location: String,
        coordinate: Coordinate? = nil,
        isActive: Bool
    ) {
        self.id = id
        self.name = name
        self.crop = crop
        self.location = location
        self.coordinate = coordinate
        self.isActive = isActive
    }
}

struct RadarReport: Identifiable, Hashable {
    enum Category: String, CaseIterable, Hashable {
        case pest = "Hama"
        case seed = "Bibit"
        case labor = "Kerja Tani"

        var icon: String {
            switch self {
            case .pest: "exclamationmark.triangle.fill"
            case .seed: "leaf.fill"
            case .labor: "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .pest: RTDColor.warningRed
            case .seed: RTDColor.primaryGreen
            case .labor: RTDColor.infoBlue
            }
        }
    }

    let id = UUID()
    let category: Category
    let distance: String
    let title: String
    let summary: String
    let timeAgo: String
    let status: String
}
