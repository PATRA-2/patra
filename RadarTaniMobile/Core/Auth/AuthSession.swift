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
        if let user = tokenStore.cachedUser(), tokenStore.access() != nil {
            currentUser = user
        }
        isRestoring = false
    }

    func didAuthenticate(_ token: AuthToken) {
        tokenStore.setAccess(token.accessToken)
        tokenStore.setRefresh(token.refreshToken)
        if let user = token.user {
            tokenStore.setCachedUser(user)
            currentUser = user
        }
    }

    func logout() {
        tokenStore.clear()
        currentUser = nil
    }
}