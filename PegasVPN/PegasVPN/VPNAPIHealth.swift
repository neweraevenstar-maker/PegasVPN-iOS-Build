import Foundation

enum VPNAPIHealthStatus: Equatable {
    case unavailable
    case reachable
    case unauthorized
    case serverError(Int)
}

struct VPNAPIHealthResult {
    let status: VPNAPIHealthStatus
    let checkedAt: Date
    let latencyMilliseconds: Int?
}
