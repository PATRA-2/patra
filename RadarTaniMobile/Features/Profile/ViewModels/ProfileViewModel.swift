import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let session: AuthSession
    private let auth: AuthService
    private(set) var errorMessage: String?

    init(env: AppEnvironment) {
        self.session = env.session
        self.auth = env.auth
    }

    var name: String { session.currentUser?.name ?? "Petani" }
    var cooperative: String { session.currentUser?.cooperativeName ?? "Koperasi" }
    var email: String { session.currentUser?.email ?? "" }

    func load() async {
        do {
            session.updateCurrentUser(try await auth.me())
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Profil gagal dimuat dari server."
        }
    }
}
