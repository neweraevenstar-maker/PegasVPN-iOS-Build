import SwiftUI

/// The disclosure describes observable app behavior, not an unverified no-logs promise.
/// Legal privacy and retention statements must be finalized before App Store release.
enum VPNDisclosure {
    static let acceptedKey = "PegasVPN.disclosureAccepted.v1"

    static var isAccepted: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }
}

struct VPNDisclosureView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(VPNDisclosure.acceptedKey) private var accepted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 54))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)

                    Text("Before using PegasVPN")
                        .font(.title.bold())

                    Text(
                        "Please review how a VPN connection works and "
                        + "what information is needed to provide the service."
                    )
                    .foregroundStyle(.secondary)

                    disclosure(
                        "VPN traffic",
                        "When connected, your device routes selected "
                        + "network traffic through the VPN server. "
                        + "The VPN operator may be able to observe "
                        + "connection metadata."
                    )

                    disclosure(
                        "Account and connection",
                        "The app contacts our service to authenticate "
                        + "your session, check VPN access and request "
                        + "a WireGuard connection configuration."
                    )

                    disclosure(
                        "Sign-in and subscriptions",
                        "If you choose Apple or email sign-in, that "
                        + "identity is used to access your account. "
                        + "Apple handles in-app payments; the service "
                        + "verifies signed purchase transactions."
                    )

                    Text(
                        "This summary is not a claim that traffic "
                        + "or connection logs are never stored. "
                        + "Detailed retention terms and the final "
                        + "privacy policy must be published before release."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Button {
                        accepted = true
                        dismiss()
                    } label: {
                        Text("I understand — continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Not now") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .navigationTitle("Privacy and VPN")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func disclosure(
        _ title: String, _ detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
