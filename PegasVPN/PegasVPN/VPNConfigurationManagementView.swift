import SwiftUI

struct VPNConfigurationManagementView: View {
    @ObservedObject var vpnManager: VPNManager
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("WireGuard configuration") {
                    LabeledContent(
                        "Saved configuration",
                        value: VPNKeychain.load() == nil
                            ? "Not found" : "Available"
                    )

                    Button("Remove saved configuration",
                           role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .disabled(VPNKeychain.load() == nil)
                }

                Section {
                    Text(
                        "Removing a saved configuration does "
                        + "not remove an active iOS VPN profile. "
                        + "Disconnect VPN before resetting."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let message {
                    Section {
                        Text(message)
                    }
                }
            }
            .navigationTitle("Manage configuration")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove saved WireGuard configuration?",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Remove", role: .destructive) {
                    message = vpnManager.removeSavedConfiguration()
                        ? "Saved configuration removed."
                        : "Disconnect VPN or check configuration storage."
                }
            }
        }
    }
}
