import Foundation

nonisolated struct UserOut: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let cooperativeName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case cooperativeName = "cooperative_name"
    }
}

// Backwards-compat alias supaya referensi lama tetap compile.
typealias User = UserOut