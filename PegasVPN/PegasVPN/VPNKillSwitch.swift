import Foundation

enum VPNKillSwitch {
    private static let key = "PegasVPN.killSwitch"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
