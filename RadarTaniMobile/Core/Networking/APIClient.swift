import Foundation

actor APIClient {
    let baseURL: URL
    let tokenStore: KeychainTokenStore
    let session: URLSession
    private var refreshTask: Task<TokenRefresh, Error>?
    private weak var sessionRef: AuthSession?

    init(baseURL: URL, tokenStore: KeychainTokenStore, session: AuthSession? = nil) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = URLSession.shared
        self.sessionRef = session
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let (data, status) = try await sendWithRefresh(endpoint)
        guard (200..<300).contains(status) else {
            throw decodeError(status: status, data: data)
        }
    }

    func request<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T {
        let (data, status) = try await sendWithRefresh(endpoint)

        guard (200..<300).contains(status) else {
            throw decodeError(status: status, data: data)
        }
        if status == 204 || data.isEmpty {
            return try APICoder.decoder.decode(T.self, from: data.isEmpty ? Data("{}".utf8) : data)
        }
        let wrapped = try APICoder.decoder.decode(APIResponse<T>.self, from: data)
        return wrapped.data
    }

    func upload<T: Decodable & Sendable>(_ type: T.Type, endpoint: APIEndpoint,
                                          body: Data, contentType: String) async throws -> T {
        let (data, status) = try await sendWithRefresh(
            endpoint,
            body: body,
            contentType: contentType
        )
        guard (200..<300).contains(status) else {
            throw decodeError(status: status, data: data)
        }
        let wrapped = try APICoder.decoder.decode(APIResponse<T>.self, from: data)
        return wrapped.data
    }

    func refreshOnce() async throws -> TokenRefresh {
        if let task = refreshTask { return try await task.value }
        guard let refresh = tokenStore.refresh() else { throw APIError.unauthenticated }
        let task = Task { () throws -> TokenRefresh in
            let body = try APICoder.encoder.encode(RefreshRequest(refreshToken: refresh))
            let endpoint = APIEndpoint(path: "/auth/refresh", method: .post,
                                       jsonBody: body, auth: .public_)
            let (data, status) = try await self.rawSend(endpoint)
            guard (200..<300).contains(status) else {
                await self.logoutAndClear()
                throw APIError.unauthenticated
            }
            let wrapped = try APICoder.decoder.decode(APIResponse<TokenRefresh>.self, from: data)
            self.tokenStore.setAccess(wrapped.data.accessToken)
            self.tokenStore.setRefresh(wrapped.data.refreshToken)
            return wrapped.data
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func sendWithRefresh(
        _ endpoint: APIEndpoint,
        body: Data? = nil,
        contentType: String? = nil
    ) async throws -> (Data, Int) {
        if endpoint.auth == .required,
           tokenStore.access() == nil,
           tokenStore.refresh() != nil {
            _ = try await refreshOnce()
        }

        var response = try await rawSend(endpoint, body: body, contentType: contentType)
        if response.1 == 401,
           endpoint.auth != .public_,
           endpoint.path != "/auth/refresh",
           tokenStore.refresh() != nil {
            _ = try await refreshOnce()
            response = try await rawSend(endpoint, body: body, contentType: contentType)
            if response.1 == 401 {
                await logoutAndClear()
                throw APIError.unauthenticated
            }
        }
        return response
    }

    private func rawSend(_ endpoint: APIEndpoint, body: Data? = nil,
                         contentType: String? = nil) async throws -> (Data, Int) {
        guard var components = URLComponents(url: baseURL.appending(path: endpoint.path),
                                            resolvingAgainstBaseURL: false)
        else { throw APIError.invalidURL }
        components.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            request.httpBody = body
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        } else if let json = endpoint.jsonBody {
            request.httpBody = json
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.auth != .public_ {
            if let token = tokenStore.access() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if endpoint.auth == .required {
                throw APIError.unauthenticated
            }
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
            return (data, http.statusCode)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }
    }

    private func decodeError(status: Int, data: Data) -> APIError {
        if let err = try? APICoder.decoder.decode(ErrorResponse.self, from: data) {
            return .server(err.error)
        }
        return .server(ServerError(code: "HTTP_\(status)", message: "Kesalahan server (\(status)).", details: nil))
    }

    private func logoutAndClear() async {
        tokenStore.clear()
        let session = sessionRef
        await MainActor.run {
            session?.logout()
        }
    }
}

nonisolated struct RefreshRequest: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}
