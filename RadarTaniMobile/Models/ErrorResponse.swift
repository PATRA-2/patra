import Foundation

nonisolated struct ErrorResponse: Decodable {
    let error: ServerError
}

nonisolated struct ServerError: Decodable {
    let code: String
    let message: String
    let details: [FieldError]?
}

nonisolated struct FieldError: Decodable {
    let field: String?
    let message: String?
}