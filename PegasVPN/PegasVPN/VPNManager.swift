
import Foundation
import NetworkExtension

@MainActor
final class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    @Published var showSubscription = false

    private let providerBundleID = "com.pegasvpn.app.tunnel"
    private var manager = NETunnelProviderManager()
    private var wireGuardConfiguration: String?
    private var activationTask: Task<Void, Never>?

    init() {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnectionStatus()
            }
        }

        wireGuardConfiguration = VPNKeychain.load()

        Task {
            await loadConfiguration()
        }
    }

    func setConfiguration(_ configuration: String) {
        do {
            try VPNConfigurationValidator.validate(configuration)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let trimmed = configuration.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.contains("[Interface]"),
              trimmed.contains("[Peer]"),
              trimmed.contains("PrivateKey"),
              trimmed.contains("PublicKey") else {
            errorMessage = "Invalid WireGuard configuration"
            return
        }

        guard VPNKeychain.save(trimmed) else {
            errorMessage = "Could not securely save VPN configuration"
            return
        }
        wireGuardConfiguration = trimmed
        errorMessage = nil
    }

    func recordConnectionAttempt() {
        VPNEventLog.shared.record("Connection requested")
    }


    func removeSavedConfiguration() -> Bool {
        guard !isConnected && !isConnecting else {
            errorMessage = "Disconnect VPN before removing configuration"
            return false
        }

        guard VPNConfigurationStore.delete() else {
            errorMessage = "Could not remove saved configuration"
            return false
        }

        wireGuardConfiguration = nil
        VPNEventLog.shared.record("Saved configuration removed")
        return true
    }


    func provisionConfiguration(
        endpoint: URL,
        accessToken: String
    ) async -> Bool {
        guard !isConnected && !isConnecting else {
            errorMessage = "Disconnect VPN before changing configuration"
            return false
        }

        guard !accessToken.isEmpty else {
            errorMessage = "VPN account authorization is required"
            return false
        }

        do {
            let configuration = try await VPNAPIClient.shared.provision(
                endpoint: endpoint,
                accessToken: accessToken
            )

            setConfiguration(configuration)

            guard errorMessage == nil else {
                return false
            }

            VPNEventLog.shared.record("VPN configuration provisioned")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func connectAutomatically() {
        guard VPNDisclosure.isAccepted else {
            errorMessage = "Review VPN data disclosure before connecting."
            return
        }
        guard !isConnected && !isConnecting else { return }
        isConnecting = true
        errorMessage = nil

        activationTask = Task {
            do {
                let access = try await VPNBillingClient.accessStatus()
                try Task.checkCancellation()

                guard access.has_access else {
                    errorMessage = "No active VPN access. Choose a subscription."
                    isConnecting = false
                    showSubscription = true
                    return
                }

                if wireGuardConfiguration == nil {
                    guard let endpoint =
                        VPNServiceConfiguration.provisioningEndpoint
                    else {
                        errorMessage = "VPN service unavailable"
                        isConnecting = false
                        return
                    }

                    var token = try await VPNGuestAuth.accessToken()
                    let configuration: String

                    do {
                        configuration = try await VPNAPIClient.shared.provision(
                            endpoint: endpoint,
                            accessToken: token
                        )
                    } catch VPNProvisioningError.unauthorized {
                        token = try await VPNGuestAuth.accessToken(
                            refresh: true
                        )
                        configuration = try await VPNAPIClient.shared.provision(
                            endpoint: endpoint,
                            accessToken: token
                        )
                    }

                    try Task.checkCancellation()
                    setConfiguration(configuration)

                    guard wireGuardConfiguration != nil,
                          errorMessage == nil else {
                        isConnecting = false
                        return
                    }
                }

                try Task.checkCancellation()
                isConnecting = false
                connect()
            } catch is CancellationError {
                isConnecting = false
            } catch {
                isConnecting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func connect() {
        guard VPNDisclosure.isAccepted else {
            errorMessage = "Review VPN data disclosure before connecting."
            return
        }
        recordConnectionAttempt()

        guard !isConnecting && !isConnected else { return }

        guard let configuration = wireGuardConfiguration else {
            errorMessage = "Automatic setup is not activated yet"
            return
        }

        isConnecting = true
        errorMessage = nil

        Task {
            do {
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.providerBundleIdentifier = providerBundleID
                tunnelProtocol.serverAddress = "PegasVPN"
                tunnelProtocol.providerConfiguration = [
                    "wgQuickConfig": configuration
                ]
        tunnelProtocol.providerConfiguration?["excludedIPv4"] =
            VPNWhitelist.load().excludedIPv4


                // Системное автоматическое подключение iOS.
                let autoConnect = UserDefaults.standard.bool(
                    forKey: "PegasVPN.autoConnect"
                )

                tunnelProtocol.includeAllNetworks = VPNKillSwitch.isEnabled

                manager.protocolConfiguration = tunnelProtocol
                manager.localizedDescription = "PegasVPN"
                manager.isEnabled = true

                if autoConnect {
                    let rule = NEOnDemandRuleConnect()
                    rule.interfaceTypeMatch = .any
                    manager.onDemandRules = [rule]
                    manager.isOnDemandEnabled = true
                } else {
                    manager.onDemandRules = []
                    manager.isOnDemandEnabled = false
                }

                try await manager.saveToPreferences()
                try await manager.loadFromPreferences()
                try manager.connection.startVPNTunnel()

                updateConnectionStatus()
            } catch {
                errorMessage = error.localizedDescription
                isConnecting = false
                updateConnectionStatus()
            }
        }
    }

    /// Never reuse a previous account's tunnel or WireGuard private key.
    func resetAfterAccountChange() async {
        activationTask?.cancel()
        activationTask = nil
        manager.isOnDemandEnabled = false
        manager.connection.stopVPNTunnel()

        if manager.protocolConfiguration != nil {
            do {
                try await manager.removeFromPreferences()
                manager = NETunnelProviderManager()
            } catch {
                // If iOS cannot remove the profile, scrub the old
                // WireGuard key and disable on-demand access.
                let emptyProtocol = NETunnelProviderProtocol()
                emptyProtocol.providerBundleIdentifier = providerBundleID
                emptyProtocol.serverAddress = "PegasVPN"
                emptyProtocol.providerConfiguration = [:]
                manager.protocolConfiguration = emptyProtocol
                manager.isEnabled = false
                do {
                    try await manager.saveToPreferences()
                } catch {
                    errorMessage = "Remove the old VPN profile in iOS Settings."
                }
            }
        }

        wireGuardConfiguration = nil
        if !VPNConfigurationStore.delete() {
            errorMessage = "Could not clear the previous VPN configuration."
        }
        updateConnectionStatus()
    }

    func resetAfterAccountDeletion() async {
        await resetAfterAccountChange()
    }

    func prepareForAutoConnect() async {
        await loadConfiguration()
    }

    func disconnect() {
        activationTask?.cancel()
        activationTask = nil
        isConnecting = false
        manager.isOnDemandEnabled = false
        manager.connection.stopVPNTunnel()
        updateConnectionStatus()

        Task {
            do {
                try await manager.saveToPreferences()
                try await manager.loadFromPreferences()
                updateConnectionStatus()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadConfiguration() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()

            if let existing = managers.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?
                    .providerBundleIdentifier == providerBundleID
            }) {
                manager = existing
            }

            updateConnectionStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateConnectionStatus() {
        switch manager.connection.status {
        case .connected:
            isConnected = true
            isConnecting = false
        case .connecting, .reasserting:
            isConnected = false
            isConnecting = true
        default:
            isConnected = false
            isConnecting = false
        }
    }
}
