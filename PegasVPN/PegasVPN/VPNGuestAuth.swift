import Foundation
import Security

enum VPNGuestAuthError: LocalizedError {
    case invalidResponse
    case server(Int)
    case keychain

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not activate guest VPN access"
        case .server(429):
            return "Too many requests. Please try again later."
        case .server(let code):
            return "VPN activation failed: \(code)"
        case .keychain:
            return "Could not securely store VPN access"
        }
    }
}

@MainActor
enum VPNGuestAuth {
    private static let service = "com.pegasvpn.guest"
    private static let account = "access-token"

    private static var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func load() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw VPNGuestAuthError.invalidResponse
        }
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(
            query as CFDictionary, update as CFDictionary
        )
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw VPNGuestAuthError.keychain
        }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw VPNGuestAuthError.keychain
        }
    }

    static func accessToken(refresh: Bool = false) async throws -> String {
        if let saved = load(), !refresh {
            if VPNGuestRefresh.load() == nil {
                try await VPNGuestRefresh.enroll(using: saved)
            }
            return saved
        }

        if refresh || VPNGuestRefresh.load() != nil {
            if VPNGuestRefresh.load() == nil,
               let saved = load() {
                try await VPNGuestRefresh.enroll(using: saved)
            }

            let renewed = try await VPNGuestRefresh.renew()
            try save(renewed)
            return renewed
        }

        let url = URL(string: "https://api.vimvitae.net/auth/guest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VPNGuestAuthError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw VPNGuestAuthError.server(http.statusCode)
        }
        guard data.count < 8192 else {
            throw VPNGuestAuthError.invalidResponse
        }

        struct GuestResponse: Decodable {
            let access_token: String
            let refresh_token: String
        }
        let guest = try JSONDecoder().decode(GuestResponse.self, from: data)
        guard !guest.access_token.isEmpty else {
            throw VPNGuestAuthError.invalidResponse
        }
        try VPNGuestRefresh.save(guest.refresh_token)
        try save(guest.access_token)
        return guest.access_token
    }

    static func installSession(
        accessToken: String, refreshToken: String
    ) throws {
        let previousRefresh = VPNGuestRefresh.load()
        try VPNGuestRefresh.save(refreshToken)
        do {
            try save(accessToken)
        } catch {
            if let previousRefresh {
                try? VPNGuestRefresh.save(previousRefresh)
            } else {
                VPNGuestRefresh.clear()
            }
            throw error
        }
    }

    static func clearSession() {
        SecItemDelete(query as CFDictionary)
        VPNGuestRefresh.clear()
    }

}
