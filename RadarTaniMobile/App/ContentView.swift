import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var userEmail = ""

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView(userEmail: userEmail) {
                    isAuthenticated = false
                    userEmail = ""
                }
            } else {
                LoginView { email in
                    userEmail = email
                    isAuthenticated = true
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: isAuthenticated)
    }
}

#Preview {
    ContentView()
}
