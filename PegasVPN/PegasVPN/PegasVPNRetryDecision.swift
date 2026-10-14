import Foundation

enum PegasVPNRetryDecision {
    static func shouldRetry(statusCode: Int, attempt: Int, maxAttempts: Int = 3) -> Bool {
        guard attempt > 0, attempt < maxAttempts else { return false }
        return [429, 502, 503, 504].contains(statusCode)
    }
}
