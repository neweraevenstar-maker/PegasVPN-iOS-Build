import SwiftUI

struct VPNSettingsView: View {
    @ObservedObject var vpnManager: VPNManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("PegasVPN.autoConnect") private var autoConnect = false
    @AppStorage("PegasVPN.language") private var language = "system"

    let openConfiguration: () -> Void
    let isConnected: Bool
    let isConnecting: Bool
    let errorMessage: String?

    @AppStorage("PegasVPN.killSwitch")
    private var killSwitch = false

    @State private var showControlCenter = false

    @State private var showPlans = false
    @State private var showDiagnostics = false

    private var activeLanguage: String {
        if language != "system" { return language }
        let code = Locale.preferredLanguages.first ?? "en"
        if code.hasPrefix("zh") { return "zh-Hans" }
        let short = String(code.prefix(2))
        return ["en", "ru", "es", "fr", "ar", "ja"].contains(short)
            ? short : "en"
    }

    private func t(_ key: String) -> String {
        guard let path = Bundle.main.path(
            forResource: activeLanguage, ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(
            forKey: key, value: key, table: nil
        )
    }

    var body: some View {
        NavigationStack {
            Form {

            Section {
                NavigationLink(destination: VPNWhitelistView()) {
                    Label("Белые списки", systemImage: "list.bullet.shield")
                }
            } header: {
                Text("Маршрутизация")
            }


                Section("PegasVPN tools") {
                    Button {
                        showControlCenter = true
                    } label: {
                        Label("Control center", systemImage: "square.grid.2x2")
                    }
                }

                Section(t("Connection")) {
                    Toggle(
                        t("Connect on launch"),
                        isOn: $autoConnect
                    )

                    Text(t("Connect automatically when the app opens"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text(t("Available server"))
                        Spacer()
                        Text("WireGuard")
                            .foregroundStyle(.secondary)
                    }

                    Text(t("Other locations are not configured yet"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(t("Security")) {
                    Label(
                        t("WireGuard encryption"),
                        systemImage: "lock.shield"
                    )

                    Button {
                        dismiss()
                        openConfiguration()
                    } label: {
                        Label(
                            t("Import WireGuard configuration"),
                            systemImage: "square.and.arrow.down"
                        )
                    }
                }

                Section(t("Russia whitelist mode")) {
                    HStack {
                        Label(
                            t("Russia whitelist mode"),
                            systemImage: "globe"
                        )
                        Spacer()
                        Text(t("Coming soon"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }


                Section(t("Account & subscription")) {
                    NavigationLink {
                        VPNSubscriptionView()
                    } label: {
                        Label(
                            "Premium subscription",
                            systemImage: "creditcard"
                        )
                    }

                    Button {
                        showPlans = true
                    } label: {
                        Label(t("Plans"), systemImage: "crown")
                    }
                }

                Section("Network protection") {
                    Toggle("Kill Switch", isOn: $killSwitch)

                    Text(
                        "Applies when a VPN connection is configured "
                        + "or reconnected. iOS controls enforcement."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section(t("Connection tools")) {
                    Button {
                        showDiagnostics = true
                    } label: {
                        Label(
                            t("Diagnostics"),
                            systemImage: "waveform.path.ecg"
                        )
                    }
                }

                Section(t("About")) {
                    HStack {
                        Text(t("Version"))
                        Spacer()
                        Text(
                            Bundle.main.infoDictionary?[
                                "CFBundleShortVersionString"
                            ] as? String ?? "Development"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(t("Settings"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t("Done")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showControlCenter) {
            VPNControlCenterView(
                vpnManager: vpnManager,
                isConnected: isConnected,
                isConnecting: isConnecting,
                errorMessage: errorMessage
            )
        }
        .sheet(isPresented: $showPlans) {
            VPNPlansView()
        }
        .sheet(isPresented: $showDiagnostics) {
            VPNDiagnosticsView(
                isConnected: isConnected,
                isConnecting: isConnecting,
                errorMessage: errorMessage
            )
        }
        .environment(
            \.layoutDirection,
            activeLanguage == "ar" ? .rightToLeft : .leftToRight
        )
    }
}
