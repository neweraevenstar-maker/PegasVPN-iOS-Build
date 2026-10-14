import Foundation

enum PegasVPNNetworkFailure: String, Equatable {
    case offline, timeout, authorization, serverUnavailable, cancelled, unknown
}

enum PegasVPNNetworkErrorClassifier {
    static func classify(_ error: Error) -> PegasVPNNetworkFailure {
        if error is CancellationError { return .cancelled }
        guard let error = error as? URLError else { return .unknown }
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost: return .offline
        case .timedOut: return .timeout
        case .userAuthenticationRequired: return .authorization
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed: return .serverUnavailable
        case .cancelled: return .cancelled
        default: return .unknown
        }
    }
}
