import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var userEmail = ""
    @State private var reportHistoryStore = ReportHistoryStore()
    @State private var plantAnalysisStore = PlantAnalysisStore()
    @State private var farmStore = FarmStore()

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView(userEmail: userEmail, reportHistoryStore: reportHistoryStore) {
                    isAuthenticated = false
                    userEmail = ""
                }
                .environment(plantAnalysisStore)
                .environment(farmStore)
            } else {
                NavigationStack {
                    LoginView { email in
                        authenticate(email: email)
                    }
                    .navigationDestination(for: AuthRoute.self) { route in
                        switch route {
                        case .registerFarmer:
                            RegisterView { email in
                                authenticate(email: email)
                            }
                        }
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: isAuthenticated)
    }

    private func authenticate(email: String) {
        userEmail = email
        isAuthenticated = true
    }
}

#Preview {
    ContentView()
}

enum AuthRoute: Hashable {
    case registerFarmer
}
