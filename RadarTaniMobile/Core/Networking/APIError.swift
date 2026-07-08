import Foundation

enum APIError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case offline
}
