import XCTest
@testable import PegasVPN

final class VPNCoreTests: XCTestCase {

    private let validPrivateKey =
        Data(repeating: 1, count: 32).base64EncodedString()

    private let validPublicKey =
        Data(repeating: 2, count: 32).base64EncodedString()

    private var validConfig: String {
        """
        [Interface]
        PrivateKey = \(validPrivateKey)
        Address = 10.66.66.2/32
        DNS = 1.1.1.1

        [Peer]
        PublicKey = \(validPublicKey)
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = vpn.example.com:51820
        """
    }

    func testValidWireGuardConfiguration() throws {
        XCTAssertNoThrow(
            try VPNConfigurationValidator.validate(validConfig)
        )
    }

    func testMissingPrivateKey() {
        let config = """
        [Interface]
        Address = 10.66.66.2/32

        [Peer]
        PublicKey = \(validPublicKey)
        """

        XCTAssertThrowsError(
            try VPNConfigurationValidator.validate(config)
        )
    }

    func testInvalidPublicKey() {
        let config = validConfig.replacingOccurrences(
            of: validPublicKey,
            with: "invalid-key"
        )

        XCTAssertThrowsError(
            try VPNConfigurationValidator.validate(config)
        )
    }

    func testMissingPeer() {
        let config = """
        [Interface]
        PrivateKey = \(validPrivateKey)
        """

        XCTAssertThrowsError(
            try VPNConfigurationValidator.validate(config)
        )
    }

    func testConfigurationInspector() {
        let summary = VPNConfigurationInspector.inspect(validConfig)

        XCTAssertTrue(summary.hasInterface)
        XCTAssertTrue(summary.hasPeer)
        XCTAssertTrue(summary.hasEndpoint)
        XCTAssertTrue(summary.hasDNS)
        XCTAssertTrue(summary.hasAllowedIPs)
        XCTAssertTrue(summary.isValid)
    }

    func testInspectorRejectsInvalidConfiguration() {
        let summary = VPNConfigurationInspector.inspect("invalid")

        XCTAssertFalse(summary.isValid)
    }

    func testHTTPSAccepted() throws {
        let url = try XCTUnwrap(
            URL(string: "https://vpn.example.com/api/provision")
        )

        XCTAssertTrue(VPNEndpointValidator.isValid(url))
    }

    func testHTTPRejected() throws {
        let url = try XCTUnwrap(
            URL(string: "http://vpn.example.com/api/provision")
        )

        XCTAssertFalse(VPNEndpointValidator.isValid(url))
    }

    func testURLCredentialsRejected() throws {
        let url = try XCTUnwrap(
            URL(string: "https://user:password@vpn.example.com/api")
        )

        XCTAssertFalse(VPNEndpointValidator.isValid(url))
    }

    func testURLFragmentRejected() throws {
        let url = try XCTUnwrap(
            URL(string: "https://vpn.example.com/api#secret")
        )

        XCTAssertFalse(VPNEndpointValidator.isValid(url))
    }

    func testSettingsExportExcludesWireGuardSecrets() {
        let exported = VPNPreferencesExport.generate()

        XCTAssertTrue(exported.contains("PegasVPN"))
        XCTAssertFalse(exported.contains("PrivateKey"))
        XCTAssertFalse(exported.contains("PublicKey"))
        XCTAssertFalse(exported.contains("wgQuickConfig"))
    }

    func testServerCatalogIdentifiersAreUnique() {
        let ids = VPNServerCatalog.locations.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testFutureServersNotMarkedAvailable() {
        let futureServers = VPNServerCatalog.locations.filter {
            $0.id != "current"
        }

        XCTAssertFalse(futureServers.isEmpty)
        XCTAssertTrue(
            futureServers.allSatisfy { !$0.isAvailable }
        )
    }

    func testProvisioningAPIRejectsUntrustedOrigins() throws {
        let good = try XCTUnwrap(
            URL(string: "https://api.vimvitae.net/vpn/provision")
        )
        XCTAssertTrue(VPNProvisioningEndpointPolicy.isTrusted(good))

        for raw in [
            "https://evil.example/vpn/provision",
            "http://api.vimvitae.net/vpn/provision",
            "https://api.vimvitae.net.evil.example/vpn/provision",
            "https://api.vimvitae.net:8443/vpn/provision",
            "https://api.vimvitae.net/vpn/provision?token=abc",
            "https://api.vimvitae.net/other",
        ] {
            let url = try XCTUnwrap(URL(string: raw))
            XCTAssertFalse(VPNProvisioningEndpointPolicy.isTrusted(url))
        }
    }

    func testRemoteCatalogRejectsUntrustedProvisioningEndpoint() {
        let invalid = VPNRemoteServer(
            id: "fake", name: "Fake", countryCode: "NL",
            endpoint: "https://evil.example/vpn/provision",
            isAvailable: true
        )
        XCTAssertNil(invalid.endpointURL)
        XCTAssertTrue(VPNRemoteServerValidator.validated([invalid]).isEmpty)
    }

    func testIPv4ExclusionsRejectDefaultRouteAndDuplicates() {
        var exclusions = VPNWhitelist()
        XCTAssertFalse(exclusions.add("0.0.0.0/0"))
        XCTAssertTrue(exclusions.add("192.168.0.0/16"))
        XCTAssertFalse(exclusions.add("192.168.0.0/16"))
        XCTAssertFalse(exclusions.add("300.1.1.0/24"))
        XCTAssertEqual(exclusions.excludedIPv4.count, 1)
    }

    func testIPv4ExclusionsLimitRouteCount() {
        var exclusions = VPNWhitelist()
        for number in 0..<VPNWhitelist.maxExcludedNetworks {
            XCTAssertTrue(exclusions.add("10.0.\(number).0/24"))
        }
        XCTAssertFalse(exclusions.add("10.1.1.0/24"))
        XCTAssertEqual(
            exclusions.excludedIPv4.count,
            VPNWhitelist.maxExcludedNetworks
        )
    }

    func testCurrentLocationIsGermany() {
        let active = VPNServerCatalog.locations.filter(\.isAvailable)
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.name, "Germany")
        XCTAssertEqual(active.first?.countryCode, "DE")
    }

    func testPlannedNetherlandsCannotBeSelected() {
        XCTAssertFalse(VPNServerCatalog.isAvailable("Netherlands"))
        XCTAssertFalse(VPNServerCatalog.isAvailable("Sweden"))
        XCTAssertFalse(VPNServerCatalog.isAvailable("Lithuania"))
        XCTAssertFalse(VPNServerCatalog.isAvailable("Switzerland"))
        XCTAssertFalse(VPNServerCatalog.isAvailable("Russia"))
    }
}
