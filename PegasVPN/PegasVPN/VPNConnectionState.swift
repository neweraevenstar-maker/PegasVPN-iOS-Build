import Foundation
import NetworkExtension

enum VPNConnectionState: String {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case reasserting
    case invalid

    init(_ status: NEVPNStatus) {
        switch status {
        case .connected:
            self = .connected
        case .connecting:
            self = .connecting
        case .disconnecting:
            self = .disconnecting
        case .reasserting:
            self = .reasserting
        case .invalid:
            self = .invalid
        case .disconnected:
            self = .disconnected
        @unknown default:
            self = .invalid
        }
    }

    var isBusy: Bool {
        self == .connecting ||
        self == .disconnecting ||
        self == .reasserting
    }

    var isProtected: Bool {
        self == .connected
    }
}
