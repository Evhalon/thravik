import Foundation
import RedentKit
import RedentCrypto

/// Parses a single `otpauth://totp/Issuer:account@x.com?secret=…` URI.
enum OTPAuthURIParser {
    static func parse(_ components: URLComponents) throws -> TOTPAccount {
        guard let type = components.host?.lowercased() else {
            throw OTPImportError.unsupportedScheme
        }
        guard type != "hotp" else { throw OTPImportError.counterBasedNotSupported }
        guard type == "totp" else { throw OTPImportError.unsupportedScheme }

        let items = components.queryItems ?? []
        guard let secretText = items.first(where: { $0.name == "secret" })?.value, !secretText.isEmpty
        else {
            throw OTPImportError.malformedPayload
        }
        let secret: Data
        do {
            secret = try Base32.decode(secretText)
        } catch {
            throw OTPImportError.malformedPayload
        }

        let (labelIssuer, account) = parseLabel(components.path)
        let issuer = resolvedIssuer(queryValue: items.first(where: { $0.name == "issuer" })?.value, labelIssuer: labelIssuer)
        let algorithm = try parseAlgorithm(items.first(where: { $0.name == "algorithm" })?.value)
        let digits = Int(items.first(where: { $0.name == "digits" })?.value ?? "") ?? 6
        let period = Int(items.first(where: { $0.name == "period" })?.value ?? "") ?? 30

        return TOTPAccount(
            issuer: issuer, accountName: account, secret: secret,
            algorithm: algorithm, digits: digits, period: period
        )
    }

    /// `URLComponents.path` already percent-decodes, so an encoded `%3A`
    /// arrives here as a plain colon and needs no special-casing.
    private static func parseLabel(_ path: String) -> (issuer: String, account: String) {
        var label = path
        if label.hasPrefix("/") { label.removeFirst() }
        guard let colonIndex = label.firstIndex(of: ":") else {
            return ("", label)
        }
        let issuer = String(label[..<colonIndex])
        var account = String(label[label.index(after: colonIndex)...])
        if account.hasPrefix(" ") { account.removeFirst() }
        return (issuer, account)
    }

    private static func resolvedIssuer(queryValue: String?, labelIssuer: String) -> String {
        if let queryValue, !queryValue.isEmpty { return queryValue }
        return labelIssuer
    }

    private static func parseAlgorithm(_ raw: String?) throws -> TOTPAlgorithm {
        guard let raw else { return .sha1 }
        switch raw.uppercased() {
        case "SHA1": return .sha1
        case "SHA256": return .sha256
        case "SHA512": return .sha512
        default: throw OTPImportError.unsupportedAlgorithm
        }
    }
}
