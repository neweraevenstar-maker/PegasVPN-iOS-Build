import SwiftUI

struct VPNAdvancedDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var log = VPNEventLog.shared

    let isConnected: Bool
    let isConnecting: Bool
    let errorMessage: String?

    private var connectionStatus: String {
        if isConnected { return "Connected" }
        if isConnecting { return "Connecting" }
        return "Disconnected"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("VPN status") {
                    LabeledContent(
                        "Connection",
                        value: connectionStatus
                    )

                    LabeledContent(
                        "Protocol",
                        value: "WireGuard"
                    )

                    LabeledContent(
                        "Configuration",
                        value: VPNKeychain.load() == nil
                            ? "Not installed"
                            : "Installed"
                    )
                }

                Section("Provisioning") {
                    LabeledContent(
                        "API",
                        value: VPNServiceConfiguration
                            .isProvisioningConfigured
                            ? "Configured"
                            : "Not configured"
                    )
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Section("Connection error") {
                        PegasStatusNotice(message: errorMessage)
                    }
                }

                Section("Session events") {
                    if log.events.isEmpty {
                        Text("No events recorded")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(log.events, id: \.self) { event in
                            Text(event)
                                .font(.caption.monospaced())
                        }
                    }

                    Button("Clear events") {
                        log.clear()
                    }
                }

                Section("Diagnostic report") {
                    ShareLink(
                        item: log.report,
                        subject: Text("PegasVPN Diagnostics"),
                        message: Text("PegasVPN diagnostic report")
                    ) {
                        Label(
                            "Export report",
                            systemImage: "square.and.arrow.up"
                        )
                    }

                    Text(
                        "Reports contain application events only. "
                        + "VPN private keys and WireGuard "
                        + "configuration are not included."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Advanced diagnostics")
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
