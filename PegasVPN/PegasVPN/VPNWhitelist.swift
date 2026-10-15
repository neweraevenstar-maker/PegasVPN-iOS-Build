
import Foundation

struct VPNWhitelist: Codable, Equatable {
    var excludedIPv4: [String] = []

    static let storageKey = "pegasvpn.whitelist.v1"
    static let maxExcludedNetworks = 32

    static func load() -> VPNWhitelist {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let value = try? JSONDecoder().decode(VPNWhitelist.self, from: data)
        else { return VPNWhitelist() }
        return value
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static func validCIDR(_ input: String) -> Bool {
        let parts = input.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              (0...32).contains(prefix)
        else { return false }

        let octets = parts[0].split(
            separator: ".",
            omittingEmptySubsequences: false
        )

        guard octets.count == 4 else { return false }

        return octets.allSatisfy {
            guard let value = UInt8($0) else { return false }
            return String(value) == String($0)
        }
    }

    mutating func add(_ cidr: String) -> Bool {
        let value = cidr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.validCIDR(value),
              value != "0.0.0.0/0",
              excludedIPv4.count < Self.maxExcludedNetworks,
              !excludedIPv4.contains(value)
        else { return false }

        excludedIPv4.append(value)
        return true
    }

    mutating func remove(at offsets: IndexSet) {
        excludedIPv4.remove(atOffsets: offsets)
    }
}


extension VPNWhitelist {
    /// Преобразует CIDR в IPv4-адрес и маску подсети.
    static func routeComponents(_ cidr: String) -> (String, String)? {
        guard validCIDR(cidr) else { return nil }

        let parts = cidr.split(separator: "/")
        let prefix = Int(parts[1])!

        let mask: UInt32 = prefix == 0
            ? 0
            : UInt32.max << (32 - prefix)

        let octets = (0..<4).map { shift -> String in
            String((mask >> (24 - shift * 8)) & 255)
        }

        return (String(parts[0]), octets.joined(separator: "."))
    }
}
