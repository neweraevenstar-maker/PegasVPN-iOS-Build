import Foundation

struct VPNConfigurationSummary {
    let hasInterface: Bool
    let hasPeer: Bool
    let hasEndpoint: Bool
    let hasDNS: Bool
    let hasAllowedIPs: Bool
    let isValid: Bool
}

enum VPNConfigurationInspector {
    static func inspect(
        _ configuration: String
    ) -> VPNConfigurationSummary {
        let lines = configuration
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(
                    in: .whitespaces
                )
            }

        let hasInterface = lines.contains("[Interface]")
        let hasPeer = lines.contains("[Peer]")

        func containsKey(_ key: String) -> Bool {
            lines.contains {
                $0.hasPrefix(key + " ") ||
                $0.hasPrefix(key + "=")
            }
        }

        let valid: Bool
        do {
            try VPNConfigurationValidator.validate(
                configuration
            )
            valid = true
        } catch {
            valid = false
        }

        return VPNConfigurationSummary(
            hasInterface: hasInterface,
            hasPeer: hasPeer,
            hasEndpoint: containsKey("Endpoint"),
            hasDNS: containsKey("DNS"),
            hasAllowedIPs: containsKey("AllowedIPs"),
            isValid: valid
        )
    }
}
