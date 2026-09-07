import Foundation
import RedentKit
import RedentCrypto

/// Bridges the `TOTPGenerating` port to `RedentCrypto`'s pure functions.
public struct SystemTOTPGenerator: TOTPGenerating {
    public init() {}

    public func code(for account: TOTPAccount, at date: Date) throws -> TOTPCode {
        let algorithm = HashAlgorithm(rawValue: account.algorithm.rawValue) ?? .sha1
        let result = TOTP.generate(
            secret: account.secret,
            at: date,
            period: account.period,
            digits: account.digits,
            algorithm: algorithm
        )
        return TOTPCode(digits: result.digits, validFrom: result.windowStart, period: result.period)
    }
}
