import SwiftUI

struct VPNAdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("PegasVPN.autoConnect")
    private var autoConnect = false

    @AppStorage("PegasVPN.killSwitch")
    private var killSwitch = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    Toggle(
                        "Connect when opening the app",
                        isOn: $autoConnect
                    )

                    Toggle(
                        "Block traffic outside VPN",
                        isOn: $killSwitch
                    )
                }

                Section("Settings backup") {
                    ShareLink(
                        item: VPNPreferencesExport.generate()
                    ) {
                        Label(
                            "Export settings",
                            systemImage: "square.and.arrow.up"
                        )
                    }

                    Text(
                        "Exports preferences only. VPN keys, "
                        + "credentials and server configurations "
                        + "are not included."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section("Important") {
                    Text(
                        "The traffic protection setting is "
                        + "applied when the VPN configuration "
                        + "is saved again. Its behaviour must "
                        + "be verified on a physical iPhone."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Advanced settings")
            .pegasPremiumScreen()
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
