import Foundation
import LocalAuthentication
import Security

/// Builds the `[String: Any]` query dictionaries shared by every Keychain
/// call site, so `CFString` bridging lives in exactly one place rather than
/// scattered across the stores.
enum KeychainQuery {
    /// Matches every generic-password item under a service.
    ///
    /// The data-protection flag is omitted for file-based items — setting it
    /// to `false` does not match logins written before that key existed.
    static func base(service: String, dataProtection: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if dataProtection {
            query[kSecUseDataProtectionKeychain as String] = true
            query[kSecAttrSynchronizable as String] = false
        }
        return query
    }

    /// Matches a single item by its stable account identifier.
    static func base(service: String, account: String, dataProtection: Bool) -> [String: Any] {
        var query = base(service: service, dataProtection: dataProtection)
        query[kSecAttrAccount as String] = account
        return query
    }

    /// Fails closed instead of popping a Keychain password dialog.
    ///
    /// `LAContext.interactionNotAllowed` only covers LocalAuthentication.
    /// File-based ACL dialogs ("Always Allow") listen to `u_AuthUI=fail`.
    /// The string form avoids the deprecated `kSecUseAuthenticationUI` symbol.
    static func silence(_ query: inout [String: Any]) {
        query[kSecUseAuthenticationContext as String] = denyingInteraction()
        query["u_AuthUI"] = "fail"
    }

    private static func denyingInteraction() -> LAContext {
        let context = LAContext()
        context.interactionNotAllowed = true
        return context
    }
}
