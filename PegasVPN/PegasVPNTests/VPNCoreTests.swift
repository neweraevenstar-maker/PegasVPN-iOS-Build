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
