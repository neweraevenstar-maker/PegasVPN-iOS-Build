import Foundation

@MainActor
final class VPNEventLog: ObservableObject {
    static let shared = VPNEventLog()

    @Published private(set) var events: [String] = []

    private init() {}

    func record(_ event: String) {
        let timestamp = Date().formatted(
            date: .abbreviated,
            time: .standard
        )

        // Записываем только заранее определённые события.
        events.insert("\(timestamp) — \(event)", at: 0)

        if events.count > 100 {
            events = Array(events.prefix(100))
        }
    }

    func clear() {
        events.removeAll()
    }

    var report: String {
        let header = """
        PegasVPN Diagnostics
        Generated: \(Date().formatted())
        App: PegasVPN
        Protocol: WireGuard

        """

        return header + events.joined(separator: "\n")
    }
}
