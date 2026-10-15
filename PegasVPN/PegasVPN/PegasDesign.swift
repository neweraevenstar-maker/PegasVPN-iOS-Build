import SwiftUI

/// Shared visual system. Presentation only; no VPN, account or billing side effects.
enum PegasDesign {
    static let midnight = Color(red: 0.018, green: 0.032, blue: 0.075)
    static let navy = Color(red: 0.045, green: 0.077, blue: 0.145)
    static let surface = Color(red: 0.075, green: 0.115, blue: 0.205)
    static let ice = Color(red: 0.87, green: 0.93, blue: 1.0)
    static let silver = Color(red: 0.66, green: 0.78, blue: 0.92)
    static let electric = Color(red: 0.33, green: 0.65, blue: 1.0)
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
            .preferredColorScheme(.dark)
    }
}

struct PegasPremiumCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(PegasDesign.surface.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(PegasDesign.silver.opacity(0.22), lineWidth: 1)
                    }
            )
    }
}

extension View {
    func pegasPremiumScreen() -> some View { modifier(PegasPremiumScreen()) }
    func pegasPremiumCard() -> some View { modifier(PegasPremiumCard()) }
}
