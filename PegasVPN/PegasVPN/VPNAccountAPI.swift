import Foundation
import CryptoKit
import Security

private final class AccountNoRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

enum VPNAccountError: LocalizedError {
    case invalidResponse
    case server(Int)
    case invalidIdentity

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid account response"
        case .server(401): return "Invalid or expired sign-in code"
        case .server(409): return "Account already linked"
        case .server(429): return "Too many attempts. Try again later."
        case .server(503): return "Account service is temporarily unavailable"
        case .server(let code): return "Account service error: \(code)"
        case .invalidIdentity: return "Apple did not return a valid identity token"
        }
    }
}

@MainActor
enum VPNAccountAPI {
    static let methodKey = "PegasVPN.accountMethod"

    static var method: String {
        UserDefaults.standard.string(forKey: methodKey) ?? "guest"
    }

    static func makeNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
                == errSecSuccess else {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func hashedNonce(_ nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8))
            .map { String(format: "%02x", $0) }.joined()
    }

    private static func send(
        _ path: String, method: String,
        body: Data? = nil, token: String? = nil
    ) async throws -> Data {
        let url = URL(string: "https://api.vimvitae.net" + path)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let session = URLSession(
            configuration: .ephemeral,
            delegate: AccountNoRedirect(),
            delegateQueue: nil
        )
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VPNAccountError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw VPNAccountError.server(http.statusCode)
        }
        guard data.count <= 16384 else {
            throw VPNAccountError.invalidResponse
        }
        return data
    }

    private struct Session: Decodable {
        let access_token: String
        let refresh_token: String
    }

    private static func install(_ data: Data, method: String) throws {
        let reply = try JSONDecoder().decode(Session.self, from: data)
        guard !reply.access_token.isEmpty,
              !reply.refresh_token.isEmpty else {
            throw VPNAccountError.invalidResponse
        }
        try VPNGuestAuth.installSession(
            accessToken: reply.access_token,
            refreshToken: reply.refresh_token
        )
        UserDefaults.standard.set(method, forKey: methodKey)
    }

    static func requestEmailCode(_ email: String) async throws {
        let data = try JSONEncoder().encode(["email": email])
        _ = try await send("/auth/email/request", method: "POST", body: data)
    }

    private static func validGuestToken() async -> String? {
        guard method == "guest",
              (try? await VPNGuestAuth.accessToken()) != nil else {
            return nil
        }
        // Do not send a cached, potentially expired guest session
        // when linking an Apple or email identity.
        return try? await VPNGuestAuth.accessToken(refresh: true)
    }

    static func signInEmail(email: String, code: String) async throws {
        let guest = await validGuestToken()
        let body = try JSONEncoder().encode([
            "email": email, "code": code
        ])
        let data: Data
        do {
            data = try await send(
                "/auth/email/verify", method: "POST", body: body, token: guest
            )
        } catch VPNAccountError.server(409) {
            // An existing email identity belongs to another account.
            // The verified email code authenticates that identity directly;
            // never merge or overwrite the current guest account.
            data = try await send(
                "/auth/email/verify", method: "POST", body: body
            )
        }
        try install(data, method: "email")
    }

    static func signInApple(identityToken: Data, nonce: String) async throws {
        guard let token = String(data: identityToken, encoding: .utf8),
              !token.isEmpty else {
            throw VPNAccountError.invalidIdentity
        }
        let guest = await validGuestToken()
        let body = try JSONEncoder().encode([
            "identity_token": token, "nonce": nonce
        ])
        let data = try await send(
            "/auth/apple", method: "POST", body: body, token: guest
        )
        try install(data, method: "apple")
    }

    static func deleteAccount() async throws {
        let token = try await VPNGuestAuth.accessToken()
        do {
            _ = try await send(
                "/auth/account", method: "DELETE", token: token
            )
        } catch VPNAccountError.server(401) {
            let renewed = try await VPNGuestAuth.accessToken(refresh: true)
            _ = try await send(
                "/auth/account", method: "DELETE", token: renewed
            )
        }
        VPNGuestAuth.clearSession()
        UserDefaults.standard.removeObject(forKey: methodKey)
        UserDefaults.standard.set(false, forKey: "PegasVPN.autoConnect")
        _ = VPNConfigurationStore.delete()
    }
}
