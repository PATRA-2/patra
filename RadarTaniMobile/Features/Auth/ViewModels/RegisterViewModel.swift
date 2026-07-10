import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var cooperativeName = ""
    var farmLocation = ""
    var password = ""
    var errorMessage: String?
    var isLoading = false

    func register() async -> String? {
        guard !isLoading else { return nil }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCooperative = cooperativeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFarmLocation = farmLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Masukkan nama lengkap terlebih dahulu."
            return nil
        }

        guard trimmedEmail.rtdIsValidEmail else {
            errorMessage = "Masukkan email yang valid."
            return nil
        }

        guard !trimmedCooperative.isEmpty else {
            errorMessage = "Masukkan nama kelompok tani."
            return nil
        }

        guard !trimmedFarmLocation.isEmpty else {
            errorMessage = "Masukkan lokasi lahan utama."
            return nil
        }

        guard password.count >= 6 else {
            errorMessage = "Password minimal 6 karakter."
            return nil
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(900))
        return trimmedEmail
    }
}
