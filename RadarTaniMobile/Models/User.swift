import Foundation

struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var email: String
    var cooperativeName: String?

    init(id: UUID = UUID(), name: String, email: String, cooperativeName: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.cooperativeName = cooperativeName
    }
}
