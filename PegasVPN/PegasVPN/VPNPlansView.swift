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


struct VPNPlansView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                        .padding(.top, 30)

                    Text("PegasVPN")
                        .font(.largeTitle.bold())

                    Text(localized("Choose your protection"))
                        .foregroundStyle(.secondary)

                    plan(
                        name: "Free",
                        subtitle: localized("Basic VPN access"),
                        features: [
                            localized("Manual WireGuard configuration"),
                            localized("Secure VPN tunnel"),
                            localized("Basic connection controls")
                        ]
                    )

                    plan(
                        name: "Premium",
                        subtitle: "Coming soon",
                        features: [
                            localized("Multiple server locations"),
                            localized("Automatic server selection"),
                            localized("Additional connection modes")
                        ]
                    )

                    Text(localized("Subscriptions are not available yet."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(localized("Plans"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func plan(
        name: String,
        subtitle: String,
        features: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(name)
                .font(.title2.bold())

            Text(subtitle)
                .foregroundStyle(.secondary)

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            Color.blue.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}
