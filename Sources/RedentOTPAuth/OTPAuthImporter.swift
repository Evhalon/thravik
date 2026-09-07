import Foundation
import RedentKit

/// Decodes QR payloads scanned by the user: a single `otpauth://totp/…` URI,
/// or Google Authenticator's `otpauth-migration://offline?data=…` bulk export.
public struct OTPAuthImporter: OTPAuthImporting {
    public init() {}

    public func accounts(fromScannedText text: String) throws -> [TOTPAccount] {
        guard let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased()
        else {
            throw OTPImportError.unsupportedScheme
        }

        switch scheme {
        case "otpauth":
            return [try OTPAuthURIParser.parse(components)]
        case "otpauth-migration":
            return try decodeMigration(components)
        default:
            throw OTPImportError.unsupportedScheme
        }
    }

    private func decodeMigration(_ components: URLComponents) throws -> [TOTPAccount] {
        guard let payload = components.queryItems?.first(where: { $0.name == "data" })?.value else {
            throw OTPImportError.malformedPayload
        }
        return try MigrationDecoder.decode(base64: payload)
    }
}
