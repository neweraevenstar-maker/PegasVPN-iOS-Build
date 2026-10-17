import SwiftUI

/// Shared visual system. Presentation only; no VPN, account or billing side effects.
enum PegasDesign {
    static let midnight = Color(red: 0.018, green: 0.032, blue: 0.075)
    static let navy = Color(red: 0.045, green: 0.077, blue: 0.145)
    static let surface = Color(red: 0.075, green: 0.115, blue: 0.205)
    static let ice = Color(red: 0.87, green: 0.93, blue: 1.0)
    static let silver = Color(red: 0.66, green: 0.78, blue: 0.92)
    static let electric = Color(red: 0.33, green: 0.65, blue: 1.0)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.43)
    static let danger = Color(red: 1.0, green: 0.43, blue: 0.48)
    static let mint = Color(red: 0.37, green: 0.89, blue: 0.77)

    static let background = LinearGradient(
        colors: [midnight, navy, midnight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let metallic = LinearGradient(
        colors: [ice, silver, electric.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct PegasPremiumScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(PegasDesign.background.ignoresSafeArea())
            .tint(PegasDesign.electric)
            .environment(\.colorScheme, .dark)
            .preferredColorScheme(.dark)
    }
}

struct PegasPremiumCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PegasDesign.surface, PegasDesign.navy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(PegasDesign.silver.opacity(0.22), lineWidth: 1)
                    }
            )
            .shadow(color: PegasDesign.electric.opacity(0.10), radius: 18, y: 8)
    }
}

extension View {
    func pegasPremiumScreen() -> some View { modifier(PegasPremiumScreen()) }
    func pegasPremiumCard() -> some View { modifier(PegasPremiumCard()) }
}

/// Shared treatment for failures and service notices.
struct PegasStatusNotice: View {
    let message: String
    var isError: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(isError ? PegasDesign.danger : PegasDesign.electric)
            Text(message)
                .font(.footnote)
                .foregroundStyle(PegasDesign.ice)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pegasPremiumCard()
        .accessibilityElement(children: .combine)
    }
}
