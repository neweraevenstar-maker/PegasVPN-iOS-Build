import Foundation
import NetworkExtension
import WireGuardKit

final class PacketTunnelProvider: NEPacketTunnelProvider {

    private lazy var adapter = WireGuardAdapter(
        with: self,
        logHandler: { level, message in
            NSLog("WireGuard [%d]: %@", level.rawValue, message)
        }
    )

    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard
            let tunnelProtocol = protocolConfiguration as? NETunnelProviderProtocol,
            let configText = tunnelProtocol.providerConfiguration?["wgQuickConfig"] as? String
        else {
            completionHandler(NSError(
                domain: "PegasVPN",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "WireGuard configuration is missing"
                ]
            ))
            return
        }

        do {
            let exclusions = (
                tunnelProtocol.providerConfiguration?["excludedIPv4"]
                as? [String]
            ) ?? []

            let configuration = try parseConfiguration(configText)
            let routedConfiguration = try applyingExclusions(
                exclusions,
                to: configuration
            )

            adapter.start(tunnelConfiguration: routedConfiguration) { error in
                completionHandler(error)
            }
        } catch {
            completionHandler(error)
        }
    }


    private var pendingExcludedRoutes: [NEIPv4Route] = []

    private static func excludedRoute(_ cidr: String) throws -> NEIPv4Route {
        let parts = cidr.split(
            separator: "/",
            omittingEmptySubsequences: false
        )

        guard parts.count == 2,
              let prefix = Int(parts[1]),
              (0...32).contains(prefix)
        else {
            throw NSError(
                domain: "PegasVPN",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid excluded route"]
            )
        }

        let octets = parts[0].split(
            separator: ".",
            omittingEmptySubsequences: false
        )

        guard octets.count == 4,
              octets.allSatisfy({ UInt8($0) != nil })
        else {
            throw NSError(
                domain: "PegasVPN",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Invalid IPv4 address"]
            )
        }

        let mask: UInt32 = prefix == 0
            ? 0
            : UInt32.max << (32 - prefix)

        let subnetMask = (0..<4).map {
            String((mask >> (24 - $0 * 8)) & 255)
        }.joined(separator: ".")

        return NEIPv4Route(
            destinationAddress: String(parts[0]),
            subnetMask: subnetMask
        )
    }


    private func applyingExclusions(
        _ exclusions: [String],
        to configuration: TunnelConfiguration
    ) throws -> TunnelConfiguration {

        guard !exclusions.isEmpty else { return configuration }

        let excluded = try exclusions.map { try Self.parseIPv4CIDR($0) }

        var updatedPeers: [PeerConfiguration] = []

        for original in configuration.peers {
            var peer = original
            var updatedRanges: [IPAddressRange] = []

            for allowed in original.allowedIPs {
                let description = String(describing: allowed)

                if description == "0.0.0.0/0" {
                    let ranges = Self.subtract(excluded)

                    updatedRanges += ranges.compactMap {
                        IPAddressRange(from: $0)
                    }
                } else {
                    updatedRanges.append(allowed)
                }
            }

            peer.allowedIPs = updatedRanges
            updatedPeers.append(peer)
        }

        return TunnelConfiguration(
            name: configuration.name,
            interface: configuration.interface,
            peers: updatedPeers
        )
    }

    private static func parseIPv4CIDR(
        _ cidr: String
    ) throws -> (UInt32, Int) {

        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              (0...32).contains(prefix)
        else {
            throw NSError(domain: "PegasVPN", code: 10)
        }

        let octets = parts[0].split(separator: ".")
        guard octets.count == 4 else {
            throw NSError(domain: "PegasVPN", code: 11)
        }

        var address: UInt32 = 0

        for octet in octets {
            guard let value = UInt8(octet) else {
                throw NSError(domain: "PegasVPN", code: 12)
            }
            address = (address << 8) | UInt32(value)
        }

        return (address, prefix)
    }

    private static func subtract(
        _ exclusions: [(UInt32, Int)]
    ) -> [String] {

        var ranges: [(UInt32, Int)] = [(0, 0)]

        for (address, prefix) in exclusions {
            let mask: UInt32 = prefix == 0
                ? 0
                : UInt32.max << (32 - prefix)

            let target = address & mask
            var next: [(UInt32, Int)] = []

            for (base, length) in ranges {
                splitRange(
                    base: base,
                    length: length,
                    excluded: target,
                    excludedLength: prefix,
                    into: &next
                )
            }

            ranges = next
        }

        return ranges.map { address, prefix in
            let a = (address >> 24) & 255
            let b = (address >> 16) & 255
            let c = (address >> 8) & 255
            let d = address & 255

            return "\(a).\(b).\(c).\(d)/\(prefix)"
        }
    }

    private static func splitRange(
        base: UInt32,
        length: Int,
        excluded: UInt32,
        excludedLength: Int,
        into result: inout [(UInt32, Int)]
    ) {
        let common = min(length, excludedLength)

        let mask: UInt32 = common == 0
            ? 0
            : UInt32.max << (32 - common)

        guard (base & mask) == (excluded & mask) else {
            result.append((base, length))
            return
        }

        if length >= excludedLength {
            return
        }

        let nextLength = length + 1
        let bit = UInt32(1) << (32 - nextLength)

        splitRange(
            base: base,
            length: nextLength,
            excluded: excluded,
            excludedLength: excludedLength,
            into: &result
        )

        splitRange(
            base: base | bit,
            length: nextLength,
            excluded: excluded,
            excludedLength: excludedLength,
            into: &result
        )
    }

    private func parseConfiguration(
        _ text: String
    ) throws -> TunnelConfiguration {

        let lines = text.components(separatedBy: .newlines)

        var privateKey: PrivateKey?
        var addresses: [IPAddressRange] = []
        var dnsServers: [DNSServer] = []
        var peers: [PeerConfiguration] = []

        var section = ""
        var peerPublicKey: PublicKey?
        var peerAllowedIPs: [IPAddressRange] = []
        var peerEndpoint: Endpoint?
        var peerKeepalive: UInt16?

        func finishPeer() {
            if let key = peerPublicKey {
                var peer = PeerConfiguration(publicKey: key)
                peer.allowedIPs = peerAllowedIPs
                peer.endpoint = peerEndpoint
                peer.persistentKeepAlive = peerKeepalive
                peers.append(peer)
            }

            peerPublicKey = nil
            peerAllowedIPs = []
            peerEndpoint = nil
            peerKeepalive = nil
        }

        for rawLine in lines {

            let line = rawLine
                .components(separatedBy: "#")[0]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if line.isEmpty {
                continue
            }

            if line == "[Interface]" {
                finishPeer()
                section = "interface"
                continue
            }

            if line == "[Peer]" {
                finishPeer()
                section = "peer"
                continue
            }

            let parts = line.split(
                separator: "=",
                maxSplits: 1
            )

            guard parts.count == 2 else {
                continue
            }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            if section == "interface" {

                switch key.lowercased() {

                case "privatekey":
                    privateKey = PrivateKey(base64Key: value)

                case "address":
                    addresses += value.split(separator: ",").compactMap {
                        IPAddressRange(
                            from: String($0).trimmingCharacters(in: .whitespaces)
                        )
                    }

                case "dns":
                    dnsServers += value.split(separator: ",").compactMap {
                        DNSServer(
                            from: String($0).trimmingCharacters(in: .whitespaces)
                        )
                    }

                default:
                    break
                }

            } else if section == "peer" {

                switch key.lowercased() {

                case "publickey":
                    peerPublicKey = PublicKey(base64Key: value)

                case "allowedips":
                    peerAllowedIPs += value.split(separator: ",").compactMap {
                        IPAddressRange(
                            from: String($0).trimmingCharacters(in: .whitespaces)
                        )
                    }

                case "endpoint":
                    peerEndpoint = Endpoint(from: value)

                case "persistentkeepalive":
                    peerKeepalive = UInt16(value)

                default:
                    break
                }
            }
        }

        finishPeer()

        guard let key = privateKey, !peers.isEmpty else {
            throw NSError(
                domain: "PegasVPN",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid WireGuard configuration"
                ]
            )
        }

        var interface = InterfaceConfiguration(privateKey: key)
        interface.addresses = addresses
        interface.dns = dnsServers

        return TunnelConfiguration(
            name: "OneTap VPN",
            interface: interface,
            peers: peers
        )
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        adapter.stop { _ in
            completionHandler()
        }
    }
}
