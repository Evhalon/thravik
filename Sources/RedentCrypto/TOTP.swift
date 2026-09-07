import Foundation

public struct TOTPResult: Sendable, Hashable {
    public let digits: String
    public let windowStart: Date
    public let period: Int
}

/// RFC 6238 time-based one-time password: HOTP keyed by a counter derived
/// from wall-clock time rather than an incrementing value.
public enum TOTP {
    /// - Parameter date: the moment to generate for. Never read internally —
    ///   callers own the clock, which keeps this deterministic and testable.
    public static func generate(
        secret: Data, at date: Date, period: Int, digits: Int, algorithm: HashAlgorithm
    ) -> TOTPResult {
        let counter = UInt64(floor(date.timeIntervalSince1970 / Double(period)))
        let code = HOTP.generate(secret: secret, counter: counter, digits: digits, algorithm: algorithm)
        let windowStart = Date(timeIntervalSince1970: Double(counter) * Double(period))
        return TOTPResult(digits: code, windowStart: windowStart, period: period)
    }
}
