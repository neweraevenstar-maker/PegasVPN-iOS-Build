import Foundation
import Security

enum VPNGuestRefreshError: LocalizedError {
    case missing
    case invalid
    case server(Int)
    case storage

    var errorDescription: String? {
        switch self {
        case .missing:
            return "Guest session recovery is unavailable"
        case .invalid:
            return "Invalid guest session response"
        case .server(let code):
            return "Guest session error: \(code)"
        case .storage:
            return "Could not save guest credentials"
        }
    }
}

@MainActor
enum VPNGuestRefresh {
    private static var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.pegasvpn.guest",
            kSecAttrAccount as String: "refresh-token"
        ]
    }

    static func load() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard SecItemCopyMatching(
            q as CFDictionary, &result
        ) == errSecSuccess,
              let data = result as? Data
        else { return nil }

        return String(data: data, encoding: .utf8)
    }

    static func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw VPNGuestRefreshError.invalid
        }

        let update = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(
            query as CFDictionary,
            update as CFDictionary
        )

        if status == errSecSuccess { return }

        guard status == errSecItemNotFound else {
            throw VPNGuestRefreshError.storage
        }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        guard SecItemAdd(
            item as CFDictionary, nil
        ) == errSecSuccess else {
            throw VPNGuestRefreshError.storage
        }
    }

    private static func send(
        _ path: String,
        access: String? = nil,
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: URL(
            string: "https://api.vimvitae.net" + path
        )!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20

        if let access {
            request.setValue(
                "Bearer \(access)",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        let (data, response) = try await session.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse else {
            throw VPNGuestRefreshError.invalid
        }

        guard http.statusCode == 200 else {
            throw VPNGuestRefreshError.server(http.statusCode)
        }

        guard data.count < 8192 else {
            throw VPNGuestRefreshError.invalid
        }

        return data
    }

    static func enroll(using access: String) async throws {
        struct Reply: Decodable {
            let refresh_token: String
        }

        let data = try await send(
            "/auth/enroll", access: access
        )
        let reply = try JSONDecoder().decode(
            Reply.self, from: data
        )
        try save(reply.refresh_token)
    }

    static func renew() async throws -> String {
        guard let token = load() else {
            throw VPNGuestRefreshError.missing
        }

        let body = try JSONEncoder().encode(
            ["refresh_token": token]
        )
        let data = try await send(
            "/auth/refresh", body: body
        )

        struct Reply: Decodable {
            let access_token: String
            let refresh_token: String
        }

        let reply = try JSONDecoder().decode(
            Reply.self, from: data
        )
        guard !reply.access_token.isEmpty,
              !reply.refresh_token.isEmpty else {
            throw VPNGuestRefreshError.invalid
        }

        try save(reply.refresh_token)
        return reply.access_token
    }

    static func clear() {
        SecItemDelete(query as CFDictionary)
    }

}
