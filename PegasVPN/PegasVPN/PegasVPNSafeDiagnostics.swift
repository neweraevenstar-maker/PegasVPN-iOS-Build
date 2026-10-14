import Foundation

struct PegasVPNSafeDiagnostics: Codable {
    let generatedAt: Date
    let appVersion: String
    let availableServerCount: Int
    let selectedServerID: String?

    static func snapshot(availableServerCount: Int, selectedServerID: String?) -> Self {
        Self(generatedAt: Date(),
             appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
             availableServerCount: availableServerCount,
             selectedServerID: selectedServerID)
    }

    func exportJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}
