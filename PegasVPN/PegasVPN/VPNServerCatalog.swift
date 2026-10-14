import Foundation

struct VPNServerLocation: Identifiable {
    let id: String
    let name: String
    let countryCode: String
    let isAvailable: Bool
}

enum VPNServerCatalog {
    static func isAvailable(_ name: String) -> Bool {
        locations.first(where: { $0.name == name })?.isAvailable ?? false
    }

    static let locations: [VPNServerLocation] = [
        .init(
            id: "current",
            name: "Current configuration",
            countryCode: "ZZ",
            isAvailable: true
        ),
        .init(
            id: "netherlands",
            name: "Netherlands",
            countryCode: "NL",
            isAvailable: false
        ),
        .init(
            id: "sweden",
            name: "Sweden",
            countryCode: "SE",
            isAvailable: false
        ),
        .init(
            id: "lithuania",
            name: "Lithuania",
            countryCode: "LT",
            isAvailable: false
        ),
        .init(
            id: "switzerland",
            name: "Switzerland",
            countryCode: "CH",
            isAvailable: false
        ),
        .init(
            id: "russia",
            name: "Russia",
            countryCode: "RU",
            isAvailable: false
        )
    ]
}
