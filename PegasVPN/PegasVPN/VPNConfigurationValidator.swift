import Foundation

enum VPNConfigurationValidator {
    enum ValidationError: LocalizedError {
        case invalidConfiguration

        var errorDescription: String? {
            "Invalid WireGuard configuration"
        }
    }

    static func validate(_ configuration: String) throws {
        let lines = configuration
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var section = ""
        var interfaceKeys: [String: String] = [:]
        var peerKeys: [String: String] = [:]
        var peers: [[String: String]] = []

        for line in lines {
            if line.isEmpty ||
                line.hasPrefix("#") ||
                line.hasPrefix(";") {
                continue
            }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                if section == "Peer" {
                    peers.append(peerKeys)
                    peerKeys = [:]
                }

                section = String(line.dropFirst().dropLast())
                guard section == "Interface" ||
                      section == "Peer" else {
                    throw ValidationError.invalidConfiguration
                }
                continue
            }

            let parts = line.split(
                separator: "=", maxSplits: 1,
                omittingEmptySubsequences: false
            )

            guard parts.count == 2 else {
                throw ValidationError.invalidConfiguration
            }

            let key = String(parts[0])
                .trimmingCharacters(in: .whitespaces)
            let value = String(parts[1])
                .trimmingCharacters(in: .whitespaces)

            guard !key.isEmpty, !value.isEmpty else {
                throw ValidationError.invalidConfiguration
            }

            if section == "Interface" {
                interfaceKeys[key] = value
            } else if section == "Peer" {
                peerKeys[key] = value
            } else {
                throw ValidationError.invalidConfiguration
            }
        }

        if section == "Peer" {
            peers.append(peerKeys)
        }

        guard let privateKey = interfaceKeys["PrivateKey"],
              isWireGuardKey(privateKey),
              !peers.isEmpty,
              peers.allSatisfy({
                  guard let publicKey = $0["PublicKey"] else {
                      return false
                  }
                  return isWireGuardKey(publicKey)
              })
        else {
            throw ValidationError.invalidConfiguration
        }
    }

    private static func isWireGuardKey(_ key: String) -> Bool {
        guard let data = Data(base64Encoded: key),
              data.count == 32 else {
            return false
        }
        return true
    }
}
