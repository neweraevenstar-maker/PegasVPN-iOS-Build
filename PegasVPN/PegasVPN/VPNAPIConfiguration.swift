
import Foundation

enum VPNAPIConfiguration {
    static var baseURL: URL? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "PegasVPNAPIBaseURL"
        ) as? String,
        let url = URL(string: value),
        url.scheme?.lowercased() == "https",
        url.host != nil,
        url.user == nil,
        url.password == nil,
        url.query == nil,
        url.fragment == nil
        else {
            return nil
        }

        return url
    }

    static var isConfigured: Bool {
        baseURL != nil
    }
}
