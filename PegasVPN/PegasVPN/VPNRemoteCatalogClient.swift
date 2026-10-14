import Foundation

enum VPNRemoteCatalogError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case emptyCatalog

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "VPN catalog endpoint is invalid"
        case .invalidResponse:
            return "Invalid VPN catalog response"
        case .emptyCatalog:
            return "No valid VPN servers available"
        }
    }
}

private final class VPNCatalogRedirectBlocker: NSObject, URLSessionTaskDelegate {
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

final class VPNRemoteCatalogClient {
    static let shared = VPNRemoteCatalogClient()

    private let redirectBlocker = VPNCatalogRedirectBlocker()

    private init() {}

    func fetch(from endpoint: URL) async throws -> [VPNRemoteServer] {
        guard endpoint.scheme?.lowercased() == "https",
              endpoint.host != nil,
              endpoint.user == nil,
              endpoint.password == nil,
              endpoint.query == nil,
              endpoint.fragment == nil,
              endpoint.port == nil || endpoint.port == 443
        else {
            throw VPNRemoteCatalogError.invalidEndpoint
        }

        let settings = URLSessionConfiguration.ephemeral
        settings.timeoutIntervalForRequest = 15
        settings.timeoutIntervalForResource = 30
        settings.httpCookieAcceptPolicy = .never
        settings.httpShouldSetCookies = false

        let session = URLSession(
            configuration: settings,
            delegate: redirectBlocker,
            delegateQueue: nil
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              data.count <= 262144
        else {
            throw VPNRemoteCatalogError.invalidResponse
        }

        let servers = try JSONDecoder().decode(
            [VPNRemoteServer].self,
            from: data
        )

        let valid = VPNRemoteServerValidator.validated(servers)

        guard !valid.isEmpty else {
            throw VPNRemoteCatalogError.emptyCatalog
        }

        return valid
    }
}
