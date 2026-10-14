import Foundation

struct VPNConfigurationRefreshPolicy {
    static let minimumRefreshInterval: TimeInterval = 3600

    static func canRefresh(
        lastRefresh: Date?,
        now: Date = Date()
    ) -> Bool {
        guard let lastRefresh else { return true }

        return now.timeIntervalSince(lastRefresh) >=
            minimumRefreshInterval
    }
}
