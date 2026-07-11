import Foundation

struct AuthService: Sendable {
    let client: APIClient

    func login(email: String, password: String) async throws -> AuthToken {
        let body = try APICoder.encoder.encode(LoginRequest(email: email, password: password))
        return try await client.request(AuthToken.self, endpoint: APIRoute.login.withBody(body))
    }

    func register(name: String, email: String, password: String,
                  cooperativeName: String?, farmLocation: String?) async throws -> AuthToken {
        let body = try APICoder.encoder.encode(RegisterRequest(
            name: name, email: email, password: password,
            cooperativeName: cooperativeName, farmLocation: farmLocation))
        return try await client.request(AuthToken.self, endpoint: APIRoute.register.withBody(body))
    }

    func logout() async throws {
        try await client.requestVoid(APIRoute.logout)
    }

    func me() async throws -> UserOut {
        try await client.request(UserOut.self, endpoint: APIRoute.me)
    }
}

nonisolated struct LoginRequest: Encodable {
    let email: String
    let password: String
}

nonisolated struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let cooperativeName: String?
    let farmLocation: String?
    enum CodingKeys: String, CodingKey {
        case name, email, password
        case cooperativeName = "cooperative_name"
        case farmLocation = "farm_location"
    }
}