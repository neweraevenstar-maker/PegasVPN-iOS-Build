import SwiftUI

struct VPNControlCenterView: View {
    @ObservedObject var vpnManager: VPNManager
    @Environment(\.dismiss) private var dismiss

    let isConnected: Bool
    let isConnecting: Bool
    let errorMessage: String?

    @State private var showConfigurationManagement = false

    @State private var showConfigurationHealth = false

    @State private var showAdvancedSettings = false
    @State private var showDiagnostics = false

    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    NavigationLink {
                        VPNServerListView()
                    } label: {
                        Label(
                            "Server locations",
                            systemImage: "globe.europe.africa"
                        )
                    }

                    Button {
                        showAdvancedSettings = true
                    } label: {
                        Label(
                            "Advanced settings",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                }

                Section("Configuration management") {
                    Button {
                        showConfigurationManagement = true
                    } label: {
                        Label(
                            "Manage saved configuration",
                            systemImage: "doc.badge.gearshape"
                        )
                    }
                }

                Section("Configuration") {
                    Button {
                        showConfigurationHealth = true
                    } label: {
                        Label(
                            "Configuration health",
                            systemImage: "checkmark.shield"
                        )
                    }
                }

                Section("Support") {
                    Button {
                        showDiagnostics = true
                    } label: {
                        Label(
                            "Advanced diagnostics",
                            systemImage: "waveform.path.ecg"
                        )
                    }
                }
            }
            .navigationTitle("Control center")
            .pegasPremiumScreen()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfigurationManagement) {
                VPNConfigurationManagementView(vpnManager: vpnManager)
            }
            .sheet(isPresented: $showConfigurationHealth) {
                VPNConfigurationHealthView()
            }
            .sheet(isPresented: $showAdvancedSettings) {
                VPNAdvancedSettingsView()
            }
            .sheet(isPresented: $showDiagnostics) {
                VPNAdvancedDiagnosticsView(
                    isConnected: isConnected,
                    isConnecting: isConnecting,
                    errorMessage: errorMessage
                )
            }
        }
    }
}

private struct VPNServerListView: View {
    var body: some View {
        List {
            ForEach(VPNServerCatalog.locations) { server in
                HStack {
                    VStack(alignment: .leading) {
                        Text(server.name)

                        Text(
                            server.isAvailable
                                ? "Uses imported configuration"
                                : "Coming soon"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(
                        systemName: server.isAvailable
                            ? "checkmark.circle"
                            : "lock"
                    )
                    .foregroundStyle(
                        server.isAvailable
                            ? .green : .secondary
                    )
                }
            }
        }
        .navigationTitle("Server locations")
    }
}
