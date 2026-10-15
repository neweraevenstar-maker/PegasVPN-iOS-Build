import Foundation

struct VPNRemoteServer: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let countryCode: String
    let endpoint: String
    let isAvailable: Bool

    var endpointURL: URL? {
        guard let url = URL(string: endpoint),
              VPNProvisioningEndpointPolicy.isTrusted(url)
        else {
            return nil
        }
        return url
    }
}
