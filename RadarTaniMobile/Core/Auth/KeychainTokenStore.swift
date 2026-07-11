import Foundation
import Security

nonisolated struct KeychainTokenStore {
    private let service = "com.hendrairawan.dev.RadarTaniMobile"
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"

    func setAccess(_ token: String) { set(Data(token.utf8), account: accessKey) }
    func setRefresh(_ token: String) { set(Data(token.utf8), account: refreshKey) }

    func access() -> String? { string(account: accessKey) }
    func refresh() -> String? { string(account: refreshKey) }

    func clear() {
        delete(account: accessKey)
        delete(account: refreshKey)
    }

    private func set(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
    private func data(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }
    private func string(account: String) -> String? {
        guard let data = data(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
