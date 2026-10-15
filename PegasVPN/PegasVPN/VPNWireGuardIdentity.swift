import CryptoKit
import Foundation
import Security

/// The X25519 private key is generated on the iPhone, never sent to the API.
/// It remains in a ThisDeviceOnly Keychain item for reprovisioning.
enum VPNWireGuardIdentity {
    private static let service = "com.pegasvpn.wireguard.identity"
    private static let account = "private-key-v2"

    struct KeyPair {
        let privateKey: String
        let publicKey: String
    }

    private static var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func read() throws -> Data? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard data.count == 32 else {
            throw NSError(domain: "PegasVPN.Key", code: 1)
        }
        return data
    }

    static func loadOrCreate() throws -> KeyPair {
        let raw: Data
        if let existing = try read() {
            raw = existing
        } else {
            let generated = Curve25519.KeyAgreement.PrivateKey()
            let candidate = generated.rawRepresentation
            var item = query
            item[kSecValueData as String] = candidate
            item[kSecAttrAccessible as String] =
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let status = SecItemAdd(item as CFDictionary, nil)
            if status == errSecSuccess {
                raw = candidate
            } else if status == errSecDuplicateItem,
                      let existing = try read() {
                raw = existing
            } else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        }
        let key = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: raw
        )
        return KeyPair(
            privateKey: raw.base64EncodedString(),
            publicKey: key.publicKey.rawRepresentation.base64EncodedString()
        )
    }

    @discardableResult
    static func delete() -> Bool {
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
