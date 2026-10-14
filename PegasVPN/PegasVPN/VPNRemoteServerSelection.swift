import Foundation

enum VPNRemoteServerSelection {
    private static let key = "PegasVPN.selectedRemoteServer"

    static func save(_ serverID: String) {
        UserDefaults.standard.set(serverID, forKey: key)
    }

    static func selectedID() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func resolve(
        from servers: [VPNRemoteServer]
    ) -> VPNRemoteServer? {
        if let id = selectedID(),
           let server = servers.first(where: {
               $0.id == id && $0.isAvailable &&
               $0.endpointURL != nil
           }) {
            return server
        }

        return servers.first(where: {
            $0.isAvailable && $0.endpointURL != nil
        })
    }
}
