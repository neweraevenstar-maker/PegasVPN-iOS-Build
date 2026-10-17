import SwiftUI

struct VPNConfigurationHealthView: View {
    @Environment(\.dismiss) private var dismiss

    private var summary: VPNConfigurationSummary? {
        guard let configuration = VPNKeychain.load()
        else { return nil }

        return VPNConfigurationInspector.inspect(
            configuration
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let summary {
                    Section("Configuration checks") {
                        item("Interface", summary.hasInterface)
                        item("Peer", summary.hasPeer)
                        item("Endpoint", summary.hasEndpoint)
                        item("DNS", summary.hasDNS)
                        item("Allowed IPs", summary.hasAllowedIPs)
                        item("Basic validation", summary.isValid)
                    }

                    Section {
                        Text(
                            "These checks inspect configuration "
                            + "structure only. They do not verify "
                            + "server availability or VPN traffic."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    ContentUnavailableView(
                        "No configuration",
                        systemImage: "doc.badge.questionmark",
                        description: Text(
                            "Import a WireGuard configuration first."
                        )
                    )
                }
            }
            .navigationTitle("Configuration health")
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

    private func item(
        _ title: String,
        _ passed: Bool
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(
                systemName: passed
                    ? "checkmark.circle.fill"
                    : "minus.circle"
            )
            .foregroundStyle(
                passed ? .green : .secondary
            )
        }
    }
}
