import Foundation

final class VPNAPIHealthChecker {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 10
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        self.session = URLSession(configuration: configuration)
    }

    func check(_ url: URL) async -> VPNAPIHealthResult {
        let now = Date()

        guard url.scheme?.lowercased() == "https",
              url.host != nil,
              url.user == nil,
              url.password == nil,
              url.query == nil,
              url.fragment == nil,
              url.port == nil || url.port == 443
        else {
            return VPNAPIHealthResult(
                status: .unavailable,
                checkedAt: now,
                latencyMilliseconds: nil
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8

        let start = Date()

        do {
            let (_, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  http.url?.host?.lowercased() == url.host?.lowercased(),
                  http.url?.scheme?.lowercased() == "https"
            else {
                return VPNAPIHealthResult(
                    status: .unavailable,
                    checkedAt: now,
                    latencyMilliseconds: nil
                )
            }

            let latency = Int(
                Date().timeIntervalSince(start) * 1000
            )

            let status: VPNAPIHealthStatus

            switch http.statusCode {
            case 200..<400:
                status = .reachable
            case 401, 403:
                status = .unauthorized
            default:
                status = .serverError(http.statusCode)
            }

            return VPNAPIHealthResult(
                status: status,
                checkedAt: now,
                latencyMilliseconds: latency
            )
        } catch {
            return VPNAPIHealthResult(
                status: .unavailable,
                checkedAt: now,
                latencyMilliseconds: nil
            )
        }
    }
}
