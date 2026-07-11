import Foundation

nonisolated struct PaginatedList<T: Decodable>: Decodable {
    let items: [T]
    let page: Int
    let pageSize: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case items, page
        case pageSize = "page_size"
        case total
    }
}