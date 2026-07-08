struct AuthService: Sendable {
    func login(email: String, password: String) async throws -> User {
        User(name: "Petani RTD", email: email, cooperativeName: "Koperasi Desa Sukamaju")
    }
}
