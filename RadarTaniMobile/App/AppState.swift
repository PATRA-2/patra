import Observation

@MainActor
@Observable
final class AppState {
    var isAuthenticated = false
    var userEmail = ""
}
