import Foundation

enum VPNRequestExecutor {
    static func execute(
        request: URLRequest,
        session: URLSession = .shared,
        policy: VPNRetryPolicy = .standard,
        allowRetry: Bool = false
    ) async throws -> (Data, URLResponse) {
        let attempts = allowRetry
            ? max(1, policy.maximumAttempts)
            : 1

        for attempt in 1...attempts {
            try Task.checkCancellation()

            do {
                let (data, response) =
                    try await session.data(for: request)

                if allowRetry,
                   attempt < attempts,
                   let http = response as? HTTPURLResponse,
                   policy.shouldRetry(statusCode: http.statusCode) {

                    let delay = policy.delay(forAttempt: attempt)
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                    continue
                }

                return (data, response)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if !allowRetry || attempt >= attempts {
                    throw error
                }

                let delay = policy.delay(forAttempt: attempt)
                try await Task.sleep(
                    nanoseconds: UInt64(delay * 1_000_000_000)
                )
            }
        }

        throw URLError(.unknown)
    }
}
