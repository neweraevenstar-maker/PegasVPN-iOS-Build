import Foundation

struct VPNPreferencesExport: Codable {
    let application: String
    let version: Int
    let autoConnect: Bool
    let killSwitch: Bool
    let language: String

    static func generate() -> String {
        let preferences = VPNPreferencesExport(
            application: "PegasVPN",
            version: 1,
            autoConnect: UserDefaults.standard.bool(
                forKey: "PegasVPN.autoConnect"
            ),
            killSwitch: UserDefaults.standard.bool(
                forKey: "PegasVPN.killSwitch"
            ),
            language: UserDefaults.standard.string(
                forKey: "PegasVPN.language"
            ) ?? "system"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(preferences),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return text
    }
}
