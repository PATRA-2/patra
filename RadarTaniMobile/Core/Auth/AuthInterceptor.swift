import Foundation

struct AuthInterceptor: Sendable {
    let tokenStore: TokenStore

    func prepare(_ request: URLRequest) async -> URLRequest {
        var request = request
        if let token = await tokenStore.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
