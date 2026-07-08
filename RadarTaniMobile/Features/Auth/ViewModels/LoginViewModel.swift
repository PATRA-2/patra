import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage: String?
    var isLoading = false

    func login() async -> String? {
        guard !isLoading else { return nil }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Masukkan email terlebih dahulu."
            return nil
        }

        guard !password.isEmpty else {
            errorMessage = "Masukkan password terlebih dahulu."
            return nil
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(900))
        if trimmedEmail.localizedCaseInsensitiveContains("error") {
            errorMessage = "Email atau password belum sesuai. Coba lagi."
            return nil
        }

        return trimmedEmail
    }
}
