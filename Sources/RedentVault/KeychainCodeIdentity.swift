import Foundation
import Security

/// Ad-hoc `make app` has no Team ID. Data-protection Keychain items are
/// partitioned by that identity, so they vanish on the next rebuild.
enum KeychainCodeIdentity {
    static var usesDataProtection: Bool { teamIdentifier != nil }

    static var teamIdentifier: String? {
        var code: SecCode?
        guard SecCodeCopySelf(SecCSFlags(), &code) == errSecSuccess, let code else {
            return nil
        }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode
        else { return nil }
        var info: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &info) == errSecSuccess else {
            return nil
        }
        let team = (info as NSDictionary?)?[kSecCodeInfoTeamIdentifier] as? String
        guard let team, !team.isEmpty else { return nil }
        return team
    }
}
