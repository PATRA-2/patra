actor TokenStore {
    private var accessToken: String?

    func save(accessToken: String) {
        self.accessToken = accessToken
    }

    func token() -> String? {
        accessToken
    }

    func clear() {
        accessToken = nil
    }
}
