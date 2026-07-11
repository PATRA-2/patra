import Foundation
import SwiftUI

nonisolated struct FarmOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let crop: String
    let location: String
    let coordinate: Coordinate
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, crop, location, coordinate
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct FarmCreate: Encodable {
    let name: String
    let crop: String
    let location: String
    let coordinate: Coordinate?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name, crop, location, coordinate
        case isActive = "is_active"
    }
}

nonisolated struct FarmUpdate: Encodable {
    let name: String?
    let crop: String?
    let location: String?
    let coordinate: Coordinate?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name, crop, location, coordinate
        case isActive = "is_active"
    }
}

// Backwards-compat alias.
typealias Farm = FarmOut