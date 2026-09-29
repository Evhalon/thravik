import Foundation
import RedentKit

/// One successful scan: the accounts decoded from that QR, plus how many
/// were new versus already in the vault.
struct AuthenticatorImportOutcome: Equatable {
    let accounts: [TOTPAccount]
    let added: Int
    let alreadyPresent: Int

    var headline: String {
        if added == 0 { return "Already saved" }
        return added == 1 ? "Account saved" : "\(added) accounts saved"
    }

    var detail: String {
        if added == 0 {
            return "These were already in your Authenticator list."
        }
        if alreadyPresent == 0 {
            return added == 1
                ? "Ready to fill when this email signs in."
                : "Ready to fill when these emails sign in."
        }
        return "\(alreadyPresent) already stored."
    }
}
