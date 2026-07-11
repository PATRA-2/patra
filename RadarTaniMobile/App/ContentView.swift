import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.session.isRestoring {
                RTDLoadingView()
            } else if env.session.isAuthenticated {
                MainTabView(onLogout: { Task { await logout() } })
            } else {
                NavigationStack {
                    LoginView()
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .registerFarmer:
                                RegisterView()
                            }
                        }
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: env.session.isAuthenticated)
        .task {
            await env.session.restore(using: env.auth)
        }
    }

    private func logout() async {
        try? await env.auth.logout()
        env.session.logout()
    }
}

#Preview {
    ContentView().environment(AppEnvironment())
}

enum AuthRoute: Hashable {
    case registerFarmer
}
