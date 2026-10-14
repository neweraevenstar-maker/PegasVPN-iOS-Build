import Foundation

@MainActor
final class VPNConnectionGuard {
    static let shared = VPNConnectionGuard()

    private(set) var isProcessing = false

    private init() {}

    func begin() -> Bool {
        guard !isProcessing else {
            return false
        }

        isProcessing = true
        return true
    }

    func end() {
        isProcessing = false
    }
}
