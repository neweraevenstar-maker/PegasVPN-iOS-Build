
import Foundation

enum VPNProvisioningError: LocalizedError {
    case notConfigured
    case unauthorized
    case invalidResponse
    case serverError(Int)
    case insecureRedirect

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "VPN service is not configured"
        case .unauthorized:
            return "VPN account authorization is required"
        case .invalidResponse:
            return "Invalid VPN server response"
        case .serverError(let code):
            return "VPN server error: \(code)"
        case .insecureRedirect:
            return "VPN server redirect is not permitted"
        }
    }
}

struct VPNProvisioningResponse: Decodable {
    let configuration: String
}

private final class VPNNoRedirectDelegate: NSObject, URLSessionTaskDelegate {
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

final class VPNAPIClient {
    static let shared = VPNAPIClient()

    private let redirectDelegate = VPNNoRedirectDelegate()

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false

        return URLSession(
            configuration: configuration,
            delegate: redirectDelegate,
            delegateQueue: nil
        )
    }()

    private init() {}

    func provision(
        endpoint: URL,
        accessToken: String
    ) async throws -> String {
        guard VPNProvisioningEndpointPolicy.isTrusted(endpoint) else {
            throw VPNProvisioningError.notConfigured
        }

        let identity = try VPNWireGuardIdentity.loadOrCreate()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        // Stable only for this installation; never reuse a WireGuard
        // private key between different devices on the same account.
        request.setValue(
            try VPNDeviceIdentity.identifier(),
            forHTTPHeaderField: "X-PegasVPN-Device-ID"
        )
        request.setValue(
            identity.publicKey,
            forHTTPHeaderField: "X-PegasVPN-Public-Key"
        )
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VPNProvisioningError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            break
        case 301, 302, 303, 307, 308:
            throw VPNProvisioningError.insecureRedirect
        case 401, 403:
            throw VPNProvisioningError.unauthorized
        default:
            throw VPNProvisioningError.serverError(http.statusCode)
        }

        guard data.count <= 65536 else {
            throw VPNProvisioningError.invalidResponse
        }

        let result = try JSONDecoder().decode(
            VPNProvisioningResponse.self,
            from: data
        )

        // Reject old server-generated keys: a VPN private key must never
        // have been known by the backend. Only the exact template is valid.
        let marker = "PrivateKey = __PEGASVPN_LOCAL_KEY__"
        guard result.configuration.components(separatedBy: marker).count == 2
        else {
            throw VPNProvisioningError.invalidResponse
        }
        let local = result.configuration.replacingOccurrences(
            of: marker,
            with: "PrivateKey = " + identity.privateKey
        )
        try VPNProvisioningValidation.validate(configuration: local)
        return "# PegasVPN-Client-Key-V2\\n" + local
    }
}
