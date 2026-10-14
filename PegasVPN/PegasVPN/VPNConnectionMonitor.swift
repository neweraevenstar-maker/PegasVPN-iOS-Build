import Foundation
import NetworkExtension

@MainActor
final class VPNConnectionMonitor: ObservableObject {
    @Published private(set) var status: NEVPNStatus = .disconnected

    private var observer: NSObjectProtocol?

    func start() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection =
                notification.object as? NEVPNConnection else {
                return
            }

            Task { @MainActor [weak self] in
                self?.status = connection.status
            }
        }
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
