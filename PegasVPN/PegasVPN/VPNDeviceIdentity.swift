import Foundation
import Security

enum VPNDeviceIdentity {
    private static let service = "com.pegasvpn.device"
    private static let account = "installation-id"

    static func identifier() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            guard let data = result as? Data,
                  let identifier = String(data: data, encoding: .utf8)
            else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecDecode))
            }
            return identifier
        }

        guard status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }

        let identifier = UUID().uuidString
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(identifier.utf8),
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let saveStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard saveStatus == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(saveStatus))
        }

        return identifier
    }
}
