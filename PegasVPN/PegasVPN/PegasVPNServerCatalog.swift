import Foundation

struct PegasVPNServerEntry: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let countryCode: String
    let apiEndpoint: URL
    let isAvailable: Bool

    var isValid: Bool {
        guard let components = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: false) else { return false }
        return !id.isEmpty && !name.isEmpty && components.scheme?.lowercased() == "https" &&
            components.host != nil && components.user == nil && components.password == nil &&
            (components.port == nil || components.port == 443)
    }
}

enum PegasVPNServerCatalog {
    static func verified(_ candidates: [PegasVPNServerEntry]) -> [PegasVPNServerEntry] {
        var seen = Set<String>()
        return candidates.filter { $0.isValid && $0.isAvailable && seen.insert($0.id).inserted }
    }
}
