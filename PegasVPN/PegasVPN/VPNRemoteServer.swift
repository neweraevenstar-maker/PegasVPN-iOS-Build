import Foundation

struct VPNRemoteServer: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let countryCode: String
    let endpoint: String
    let isAvailable: Bool

    var endpointURL: URL? {
        guard let url = URL(string: endpoint),
              url.scheme?.lowercased() == "https",
              url.host != nil,
              url.user == nil,
              url.password == nil,
              url.fragment == nil,
              url.query == nil,
              url.port == nil || url.port == 443
        else {
            return nil
        }
        return url
    }
}
