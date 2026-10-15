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

    static let gold = Color(red: 0.91, green: 0.81, blue: 0.61)
    static let deepBlue = Color(red: 0.01, green: 0.025, blue: 0.07)

    static let background = LinearGradient(
        colors: [deepBlue, navy, midnight, deepBlue],
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
            .toolbarBackground(PegasDesign.navy, for: .navigationBar)
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
                    .fill(LinearGradient(colors: [PegasDesign.surface, PegasDesign.navy], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(LinearGradient(colors: [PegasDesign.ice.opacity(0.38), PegasDesign.electric.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    }
            )
    }
}

extension View {
    func pegasPremiumScreen() -> some View { modifier(PegasPremiumScreen()) }
    func pegasPremiumCard() -> some View { modifier(PegasPremiumCard()) }
}

    
/// Dimensional chrome emblem and luminous orbital power control.
struct PegasOrbitalControl: View {
    let connected: Bool
    let connecting: Bool
    let title: String
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbit = false

    var body: some View {
        ZStack {
            Circle()
                .fill(PegasDesign.electric.opacity(0.12))
                .frame(width: 316, height: 316)
                .blur(radius: 34)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.clear, PegasDesign.electric.opacity(0.2),
                                     PegasDesign.ice.opacity(0.88), .clear],
                            center: .center,
                            startAngle: .degrees(0), endAngle: .degrees(360)
                        ),
                        lineWidth: index == 1 ? 2.5 : 1
                    )
                    .frame(width: CGFloat(300 - index * 25),
                           height: CGFloat(300 - index * 25))
                    .rotationEffect(.degrees(orbit ? 360 : 0))
                    .shadow(color: PegasDesign.electric.opacity(0.65), radius: 12)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [PegasDesign.surface, PegasDesign.midnight,
                                 PegasDesign.deepBlue],
                        center: .init(x: 0.3, y: 0.18),
                        startRadius: 8, endRadius: 155
                    )
                )
                .frame(width: 225, height: 225)
                .overlay {
                    Circle().strokeBorder(PegasDesign.metallic, lineWidth: 2.5)
                }
                .overlay {
                    Circle().strokeBorder(PegasDesign.ice.opacity(0.12), lineWidth: 12)
                        .padding(9)
                }
                .shadow(color: PegasDesign.electric.opacity(0.35), radius: 28, y: 10)

            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 43, weight: .thin))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(PegasDesign.ice, PegasDesign.electric)
                        .shadow(color: PegasDesign.electric.opacity(0.8), radius: 16)
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(PegasDesign.metallic)
                }
                .frame(width: 216, height: 216)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(connected ? "Disconnect VPN" : "Connect VPN")
        }
        .frame(height: 318)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                orbit = true
            }
        }
    }
}

/// Metallic, winged-horse inspired crest rendered in vector SwiftUI.
struct PegasCrest: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(PegasDesign.metallic.opacity(0.09))
                .frame(width: 48, height: 48)
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 27, weight: .thin))
                .foregroundStyle(PegasDesign.metallic)
            Image(systemName: "wing")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(PegasDesign.ice)
                .offset(x: 8, y: -7)
        }
        .accessibilityHidden(true)
    }
}
