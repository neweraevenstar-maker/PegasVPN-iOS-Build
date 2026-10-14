import Foundation

enum VPNRemoteServerValidator {
    static func validated(
        _ servers: [VPNRemoteServer]
    ) -> [VPNRemoteServer] {
        var identifiers = Set<String>()

        return servers.filter { server in
            guard !server.id.isEmpty,
                  !server.name.isEmpty,
                  !server.countryCode.isEmpty,
                  server.endpointURL != nil,
                  !identifiers.contains(server.id)
            else {
                return false
            }

            identifiers.insert(server.id)
            return true
        }
    }
}
