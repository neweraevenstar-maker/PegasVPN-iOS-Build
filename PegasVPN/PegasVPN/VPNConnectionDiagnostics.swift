import Foundation
import Network

final class VPNConnectionDiagnostics {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "com.pegasvpn.connection-diagnostics"
    )

    private(set) var isNetworkAvailable = false

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
