import Foundation

struct VPNConfigurationExpiry: Codable {
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }

    var shouldRefresh: Bool {
        guard let expiresAt else { return false }
        return Date().addingTimeInterval(86400) >= expiresAt
    }
}
