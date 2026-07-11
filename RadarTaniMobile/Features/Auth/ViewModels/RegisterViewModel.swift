import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var cooperativeName = ""
    var farmLocation = ""
    var errorMessage: String?
    var isLoading = false

    private let auth: AuthService
    private let session: AuthSession
    init(env: AppEnvironment) { self.auth = env.auth; self.session = env.session }

    func register() async -> Bool {
        guard !isLoading else { return false }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Nama wajib diisi."; return false
        }
        guard trimmedEmail.rtdIsValidEmail else { errorMessage = "Masukkan email yang valid."; return false }
        guard password.count >= 6 else { errorMessage = "Password minimal 6 karakter."; return false }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.register(
                name: name, email: trimmedEmail, password: password,
                cooperativeName: cooperativeName.isEmpty ? nil : cooperativeName,
                farmLocation: farmLocation.isEmpty ? nil : farmLocation)
            session.didAuthenticate(token)
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal mendaftar."
            return false
        }
    }
}