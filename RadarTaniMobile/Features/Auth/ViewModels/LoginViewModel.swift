import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage: String?
    var isLoading = false

    private let auth: AuthService
    private let session: AuthSession

    init(env: AppEnvironment) {
        self.auth = env.auth
        self.session = env.session
    }

    func login() async -> Bool {
        guard !isLoading else { return false }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { errorMessage = "Masukkan email terlebih dahulu."; return false }
        guard !password.isEmpty else { errorMessage = "Masukkan password terlebih dahulu."; return false }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.login(email: trimmedEmail, password: password)
            session.didAuthenticate(token)
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal masuk."
            return false
        }
    }
}