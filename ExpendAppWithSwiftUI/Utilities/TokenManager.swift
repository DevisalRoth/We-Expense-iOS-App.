import Foundation
import Security

class TokenManager {
    static let shared = TokenManager()
    private let service = "com.expendapp.auth"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    private init() {}
    
    func saveAccessToken(_ token: String) {
        save(token, key: accessTokenKey)
    }
    
    func getAccessToken() -> String? {
        return get(key: accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) {
        save(token, key: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return get(key: refreshTokenKey)
    }
    
    func clearTokens() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }
    
    private func save(_ token: String, key: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
