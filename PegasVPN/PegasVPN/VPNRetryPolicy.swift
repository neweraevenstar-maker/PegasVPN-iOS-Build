import Foundation

struct VPNRetryPolicy {
    let maximumAttempts: Int
    let initialDelay: TimeInterval
    let maximumDelay: TimeInterval

    static let standard = VPNRetryPolicy(
        maximumAttempts: 3,
        initialDelay: 1,
        maximumDelay: 8
    )

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponent = max(0, min(attempt - 1, 10))
        return min(
            maximumDelay,
            initialDelay * pow(2.0, Double(exponent))
        )
    }

    func shouldRetry(statusCode: Int) -> Bool {
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504
    }
}
