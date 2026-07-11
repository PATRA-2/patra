import Foundation

nonisolated struct APIResponse<T: Decodable>: Decodable {
    let data: T
}