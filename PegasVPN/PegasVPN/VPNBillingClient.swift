import Foundation
import StoreKit

struct VPNAccessStatus: Decodable {
    let has_access: Bool
    let trial_active: Bool
    let subscription_active: Bool
    let trial_ends_at: String?
    let subscription_ends_at: String?
}

enum VPNBillingError: LocalizedError {
    case invalidResponse
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid Apple billing response"
        case .server(503):
            return "Apple payments are not activated yet"
        case .server(let code):
            return "Billing server error: \(code)"
        }
    }
}

private final class BillingNoRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

@MainActor
enum VPNBillingClient {
    private static let base = "https://api.vimvitae.net"

    private static func send(
        _ path: String,
        method: String,
        body: Data? = nil
    ) async throws -> Data {
        let token = try await VPNGuestAuth.accessToken()

        var request = URLRequest(
            url: URL(string: base + path)!
        )
        request.httpMethod = method
        request.timeoutInterval = 20

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if let body {
            request.httpBody = body
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let session = URLSession(
            configuration: .ephemeral,
            delegate: BillingNoRedirect(),
            delegateQueue: nil
        )
        defer { session.finishTasksAndInvalidate() }

        let first = try await session.data(for: request)
        var data = first.0
        var response = first.1

        if let http = response as? HTTPURLResponse,
           http.statusCode == 401 {
            let token = try await VPNGuestAuth.accessToken(
                refresh: true
            )
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
            let second = try await session.data(for: request)
            data = second.0
            response = second.1
        }

        guard let http = response as? HTTPURLResponse else {
            throw VPNBillingError.invalidResponse
        }

        guard http.statusCode == 200 else {
            throw VPNBillingError.server(http.statusCode)
        }

        guard data.count < 16384 else {
            throw VPNBillingError.invalidResponse
        }

        return data
    }

    static func accessStatus() async throws -> VPNAccessStatus {
        let data = try await send(
            "/access/status",
            method: "GET"
        )
        return try JSONDecoder().decode(
            VPNAccessStatus.self,
            from: data
        )
    }

    static func accountToken() async throws -> UUID {
        struct Account: Decodable {
            let app_account_token: String
        }

        let data = try await send(
            "/billing/account",
            method: "GET"
        )

        let result = try JSONDecoder().decode(
            Account.self,
            from: data
        )

        guard let uuid = UUID(
            uuidString: result.app_account_token
        ) else {
            throw VPNBillingError.invalidResponse
        }

        return uuid
    }

    static func verify(
        _ result: VerificationResult<Transaction>) async throws {
        struct Payload: Encodable {
            let signed_transaction: String
        }

        struct Result: Decodable {
            let verified: Bool
        }

        let body = try JSONEncoder().encode(
            Payload(
                signed_transaction: result.jwsRepresentation
            )
        )

        let data = try await send(
            "/billing/verify",
            method: "POST",
            body: body
        )

        let result = try JSONDecoder().decode(
            Result.self,
            from: data
        )

        guard result.verified else {
            throw VPNBillingError.invalidResponse
        }
    }
}
