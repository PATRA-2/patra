import Foundation

struct PesticideOrder: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var productName: String
    var quantity: Int
    var status: String

    init(id: UUID = UUID(), productName: String, quantity: Int, status: String) {
        self.id = id
        self.productName = productName
        self.quantity = quantity
        self.status = status
    }
}
