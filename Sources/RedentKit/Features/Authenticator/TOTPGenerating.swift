import Foundation

/// Generates codes from a stored account. Kept as a port so view models depend
/// on the capability, not on RedentCrypto.
public protocol TOTPGenerating: Sendable {
    func code(for account: TOTPAccount, at date: Date) throws -> TOTPCode
}

public extension TOTPGenerating {
    func code(for account: TOTPAccount) throws -> TOTPCode {
        try code(for: account, at: .now)
    }
}

/// Decodes a scanned QR payload into accounts.
public protocol OTPAuthImporting: Sendable {
    /// Accepts both `otpauth://totp/...` and Google Authenticator's
    /// `otpauth-migration://offline?data=...` export payload.
    func accounts(fromScannedText text: String) throws -> [TOTPAccount]
}

public enum OTPImportError: Error, Sendable, Equatable {
    case unsupportedScheme
    case malformedPayload
    case emptyPayload
    case unsupportedAlgorithm
    case counterBasedNotSupported
}
