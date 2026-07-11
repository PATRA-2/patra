import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let session: AuthSession
    var notificationsEnabled = true
    init(env: AppEnvironment) { self.session = env.session }

    var name: String { session.currentUser?.name ?? "Petani" }
    var cooperative: String { session.currentUser?.cooperativeName ?? "Koperasi" }
    var email: String { session.currentUser?.email ?? "" }
}