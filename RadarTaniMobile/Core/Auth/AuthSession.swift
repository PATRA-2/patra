import Observation

@MainActor
@Observable
final class AuthSession {
    var user: User?

    var isAuthenticated: Bool {
        user != nil
    }
}
