import Foundation

struct VPNProvisionRequest: Encodable {
    let user_id: String
}

struct VPNProvisionResponse: Decodable {
    let configuration: String
}

enum VPNAPIError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case emptyConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from VPN server"
        case .serverError(let code):
            return "VPN server error: \(code)"
        case .emptyConfiguration:
            return "VPN server returned an empty configuration"
        }
    }
}

final class VPNAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func provision(
        endpoint: URL,
        userID: String,
        accessToken: String
    ) async throws -> String {
        guard endpoint.scheme?.lowercased() == "https",
              endpoint.host != nil else {
            throw URLError(.secureConnectionFailed)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.httpBody = try JSONEncoder().encode(
            VPNProvisionRequest(user_id: userID)
        )

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VPNAPIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw VPNAPIError.serverError(http.statusCode)
        }

        let result = try JSONDecoder().decode(
            VPNProvisionResponse.self,
            from: data
        )

        guard !result.configuration.isEmpty else {
            throw VPNAPIError.emptyConfiguration
        }

        return result.configuration
    }
}
