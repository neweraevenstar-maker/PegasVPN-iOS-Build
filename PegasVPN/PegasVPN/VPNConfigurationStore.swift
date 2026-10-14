import Foundation
import Security

enum VPNConfigurationStore {
    static func delete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String:
                "com.pegasvpn.configuration",
            kSecAttrAccount as String: "wireguard"
        ]

        let result = SecItemDelete(query as CFDictionary)

        return result == errSecSuccess ||
               result == errSecItemNotFound
    }
}
