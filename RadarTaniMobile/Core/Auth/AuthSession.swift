import Foundation
import Observation

@MainActor
@Observable
final class AuthSession {
    private let tokenStore: KeychainTokenStore
    private(set) var currentUser: UserOut?
    private(set) var isRestoring: Bool = true

    var isAuthenticated: Bool { currentUser != nil }

    init(tokenStore: KeychainTokenStore) {
        self.tokenStore = tokenStore
    }

    func restore(using auth: AuthService) async {
        guard isRestoring else { return }
        defer { isRestoring = false }

        guard tokenStore.access() != nil || tokenStore.refresh() != nil else { return }
        do {
            currentUser = try await auth.me()
        } catch APIError.unauthenticated {
            tokenStore.clear()
            currentUser = nil
        } catch let APIError.server(serverError)
            where serverError.code == APIErrorCode.invalidRefreshToken {
            tokenStore.clear()
            currentUser = nil
        } catch {
            currentUser = nil
        }
    }

    func didAuthenticate(_ token: AuthToken) {
        tokenStore.setAccess(token.accessToken)
        tokenStore.setRefresh(token.refreshToken)
        if let user = token.user {
            currentUser = user
        }
    }

    func updateCurrentUser(_ user: UserOut) {
        currentUser = user
    }

    func logout() {
        tokenStore.clear()
        currentUser = nil
    }
}
