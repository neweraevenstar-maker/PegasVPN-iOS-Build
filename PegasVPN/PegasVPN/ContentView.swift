import SwiftUI

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @AppStorage(VPNDisclosure.acceptedKey) private var disclosureAccepted = false
    @State private var showDisclosure = false
    @AppStorage("PegasVPN.autoConnect") private var autoConnect = false
    @State private var attemptedAutoConnect = false
    @State private var showConfiguration = false
    @State private var configurationText = ""
    @State private var showLocations = false
    @State private var showLanguage = false
    @AppStorage("PegasVPN.language") private var appLanguage = "system"

    private var activeLanguage: String {
        if appLanguage != "system" { return appLanguage }
        let code = Locale.preferredLanguages.first ?? "en"
        if code.hasPrefix("zh") { return "zh-Hans" }
        let short = String(code.prefix(2))
        return ["en", "ru", "es", "fr", "ar", "ja"].contains(short)
            ? short : "en"
    }

    private func t(_ key: String) -> String {
        guard let path = Bundle.main.path(
            forResource: activeLanguage, ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    @State private var selectedLocation = "Current configuration"

    private let background = Color(red: 0.025, green: 0.045, blue: 0.10)
    private let panel = Color(red: 0.055, green: 0.095, blue: 0.18)
    private let accent = Color(red: 0.20, green: 0.48, blue: 0.92)
    private let silver = Color(red: 0.84, green: 0.90, blue: 0.98)

    private var locations: [(String, String)] {
        VPNServerCatalog.locations.map { location in
            let flag: String

            switch location.countryCode {
            case "NL": flag = "🇳🇱"
            case "SE": flag = "🇸🇪"
            case "LT": flag = "🇱🇹"
            case "CH": flag = "🇨🇭"
            case "RU": flag = "🇷🇺"
            default: flag = "🌐"
            }

            return (flag, location.name)
        }
    }

    private var statusText: String {
        vpnManager.isConnected ? t("Protected") :
        vpnManager.isConnecting ? t("Connecting...") : t("Not Connected")
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PEGAS")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(silver)
                        +
                        Text("VPN")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(accent)

                    }

                    Spacer()

                    Button {
                        showLanguage = true
                    } label: {
                        Image(systemName: "character.bubble")
                            .font(.system(size: 22))
                            .foregroundStyle(silver)
                            .frame(width: 46, height: 46)
                            .background(panel, in: Circle())
                    }
                    .accessibilityLabel(t("Language"))

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22))
                            .foregroundStyle(silver)
                            .frame(width: 46, height: 46)
                            .background(panel, in: Circle())
                    }
                    .accessibilityLabel(t("VPN configuration"))
                }
                .padding(.top, 24)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.09), lineWidth: 1)
                        .frame(width: 290, height: 290)

                    Circle()
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                        .frame(width: 252, height: 252)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    vpnManager.isConnected
                                        ? Color(red: 0.08, green: 0.42, blue: 0.55)
                                        : accent.opacity(0.45),
                                    panel,
                                    background
                                ],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 220
                            )
                        )
                        .frame(width: 215, height: 215)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [silver.opacity(0.75), accent, accent.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: accent.opacity(0.22), radius: 30)

                    Button {
                        if vpnManager.isConnected || vpnManager.isConnecting {
                            vpnManager.disconnect()
                        } else if !disclosureAccepted {
                            showDisclosure = true
                        } else {
                            vpnManager.connectAutomatically()
                        }
                    } label: {
                        VStack(spacing: 15) {
                            Image(systemName: "power")
                                .font(.system(size: 58, weight: .light))

                            Text(
                                vpnManager.isConnected ? t("STOP") :
                                vpnManager.isConnecting ? t("CANCEL") : t("START")
                            )
                            .font(.system(size: 18, weight: .semibold))
                            .tracking(4)
                        }
                        .foregroundStyle(silver)
                        .frame(width: 205, height: 205)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 9) {
                    Circle()
                        .fill(
                            vpnManager.isConnected ? Color.green :
                            vpnManager.isConnecting ? Color.orange : silver.opacity(0.5)
                        )
                        .frame(width: 9, height: 9)

                    Text(statusText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(silver)
                }
                .padding(.top, 35)

                Text(
                    vpnManager.isConnected
                        ? t("Your connection is secured")
                        : t("Tap START to connect securely")
                )
                .font(.system(size: 13))
                .foregroundStyle(silver.opacity(0.5))
                .padding(.top, 8)

                if let error = vpnManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text(t("VPN LOCATION"))
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(silver.opacity(0.5))

                    Button {
                        showLocations = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: 23))
                                .foregroundStyle(accent)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(t(selectedLocation))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(silver)

                                Text(t("Select location"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(silver.opacity(0.45))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(silver.opacity(0.6))
                        }
                        .padding(18)
                        .background(panel, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    Text(t("Other locations are coming soon"))
                        .font(.system(size: 11))
                        .foregroundStyle(silver.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)

        .environment(
            \.layoutDirection,
            activeLanguage == "ar" ? .rightToLeft : .leftToRight
        )
        .sheet(isPresented: $showLanguage) {
            NavigationStack {
                List {
                    ForEach(
                        [
                            ("system", "🌐", t("System default")),
                            ("en", "🇬🇧", "English"),
                            ("ru", "🇷🇺", "Русский"),
                            ("es", "🇪🇸", "Español"),
                            ("zh-Hans", "🇨🇳", "简体中文"),
                            ("fr", "🇫🇷", "Français"),
                            ("ar", "🇸🇦", "العربية"),
                            ("ja", "🇯🇵", "日本語")
                        ],
                        id: \.0
                    ) { code, flag, title in
                        Button {
                            appLanguage = code
                            showLanguage = false
                        } label: {
                            HStack {
                                Text(flag)
                                Text(title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if appLanguage == code {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(t("Language"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(t("Done")) {
                            showLanguage = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showLocations) {
            NavigationStack {
                List {
                    ForEach(locations, id: \.1) { flag, name in
                        Button {
                            if name == "Current configuration" {
                                selectedLocation = name
                                showLocations = false
                            }
                        } label: {
                            HStack {
                                Text(flag)
                                Text(t(name))
                                    .foregroundStyle(.primary)

                                Spacer()

                                if name == selectedLocation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                } else if !VPNServerCatalog.isAvailable(name) {
                                    Text(t("Soon"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(!VPNServerCatalog.isAvailable(name))
                    }
                }
                .navigationTitle(t("VPN Locations"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(t("Done")) { showLocations = false }
                    }
                }
            }
        }

        .sheet(isPresented: $showSettings) {
            VPNSettingsView(
                vpnManager: vpnManager,
                openConfiguration: {
                    showConfiguration = true
                },
                isConnected: vpnManager.isConnected,
                isConnecting: vpnManager.isConnecting,
                errorMessage: vpnManager.errorMessage
            )
        }
        .task {
            guard !attemptedAutoConnect else { return }
            attemptedAutoConnect = true

            guard disclosureAccepted,
                  autoConnect,
                  VPNKeychain.load() != nil else { return }

            // Дожидаемся загрузки сохранённого NETunnelProviderManager.
            await vpnManager.prepareForAutoConnect()

            if !vpnManager.isConnected && !vpnManager.isConnecting {
                vpnManager.connectAutomatically()
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await vpnManager.revalidateAccess()
                do {
                    try await Task.sleep(for: .seconds(300))
                } catch {
                    break
                }
            }
        }
        .sheet(isPresented: $vpnManager.showSubscription) {
            NavigationStack {
                VPNSubscriptionView()
            }
        }
        .sheet(isPresented: $showDisclosure) {
            VPNDisclosureView()
        }
        .onAppear {
            if !disclosureAccepted {
                showDisclosure = true
            }
        }
        .sheet(isPresented: $showConfiguration) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text(t("Paste your WireGuard configuration"))
                        .font(.headline)

                    TextEditor(text: $configurationText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 220)
                        .border(Color.gray.opacity(0.3))

                    Button(t("Save Configuration")) {
                        vpnManager.setConfiguration(configurationText)

                        if vpnManager.errorMessage == nil {
                            configurationText = ""
                            showConfiguration = false
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .padding()
                .navigationTitle(t("VPN Configuration"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(t("Cancel")) {
                            configurationText = ""
                            showConfiguration = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
