import Foundation

/// Account bearer tokens must only be sent to the operator's trusted API.
/// Future regional endpoints require an explicit allowlist change and tests.
enum VPNProvisioningEndpointPolicy {
    static func isTrusted(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == "api.vimvitae.net"
            && (url.port == nil || url.port == 443)
            && url.path == "/vpn/provision"
            && url.user == nil
            && url.password == nil
            && url.query == nil
            && url.fragment == nil
    }
}
