import Observation

@MainActor
@Observable
final class AppRouter {
    var selectedTab: HomeTab = .home
}
