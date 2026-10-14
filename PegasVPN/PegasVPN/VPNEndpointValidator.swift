import Foundation

enum VPNEndpointValidator {
    static func isValid(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host,
              !host.isEmpty,
              url.user == nil,
              url.password == nil,
              url.fragment == nil else {
            return false
        }

        return true
    }
}
