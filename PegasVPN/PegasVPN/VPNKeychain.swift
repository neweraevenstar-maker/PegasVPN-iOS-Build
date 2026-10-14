import Foundation
import Security

enum VPNKeychain {
    private static let service = "com.pegasvpn.configuration"
    private static let account = "wireguard"


    @discardableResult
    static func save(_ configuration: String) -> Bool {
        do {
            try VPNConfigurationValidator.validate(configuration)
        } catch {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: Data(configuration.utf8),
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var newItem = query
        for (key, value) in attributes {
            newItem[key] = value
        }

        return SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        guard SecItemCopyMatching(
            query as CFDictionary,
            &result
        ) == errSecSuccess,
        let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
