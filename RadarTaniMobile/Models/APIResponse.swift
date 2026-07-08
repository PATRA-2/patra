struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    var data: T
    var message: String?
}
