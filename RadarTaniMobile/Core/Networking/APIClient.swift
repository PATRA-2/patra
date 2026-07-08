import Foundation

protocol APIClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T
}

struct APIClient: APIClientProtocol {
    let baseURL: URL
    var session: URLSession = .shared

    func request<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else { throw APIError.httpStatus(httpResponse.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
