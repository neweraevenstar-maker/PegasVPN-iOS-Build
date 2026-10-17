import SwiftUI

private func localized(_ key: String) -> String {
    let preference = UserDefaults.standard.string(
        forKey: "PegasVPN.language"
    ) ?? "system"

    let language: String
    if preference != "system" {
        language = preference
    } else {
        let preferred = Locale.preferredLanguages.first ?? "en"
        language = preferred.hasPrefix("zh")
            ? "zh-Hans" : String(preferred.prefix(2))
    }

    guard let path = Bundle.main.path(
        forResource: language, ofType: "lproj"
    ), let bundle = Bundle(path: path) else {
        return key
    }

    return bundle.localizedString(
        forKey: key, value: key, table: nil
    )
}


struct VPNDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    let isConnected: Bool
    let isConnecting: Bool
    let errorMessage: String?

    private var status: String {
        if isConnected { return localized("Connected") }
        if isConnecting { return localized("Connecting") }
        return localized("Disconnected")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    LabeledContent(localized("Status"), value: status)
                    LabeledContent(
                        localized("Protocol"),
                        value: "WireGuard"
                    )
                }

                Section(localized("Configuration")) {
                    LabeledContent(
                        localized("Saved configuration"),
                        value: VPNKeychain.load() == nil
                            ? localized("Not found") : localized("Available")
                    )
                }

                Section(localized("Automatic provisioning")) {
                    LabeledContent(
                        localized("Status"),
                        value: VPNServiceConfiguration
                            .isProvisioningConfigured
                            ? localized("Endpoint configured")
                            : localized("Not configured")
                    )
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Section(localized("Last error")) {
                        PegasStatusNotice(message: errorMessage)
                    }
                }

                Section {
                    Text(
                        "This screen reports application state. "
                        + "It does not perform an external IP, "
                        + "DNS leak or connectivity test."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(localized("Diagnostics"))
            .pegasPremiumScreen()
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
