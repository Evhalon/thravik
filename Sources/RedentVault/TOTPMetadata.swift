import Foundation
import RedentKit

/// JSON payload stored in `kSecAttrGeneric` for a TOTP item. The raw seed
/// lives only in `kSecValueData`.
struct TOTPMetadata: Codable {
    let issuer: String
    let accountName: String
    let algorithm: TOTPAlgorithm
    let digits: Int
    let period: Int
    var linkedDomains: Set<String>

    init(account: TOTPAccount) {
        issuer = account.issuer
        accountName = account.accountName
        algorithm = account.algorithm
        digits = account.digits
        period = account.period
        linkedDomains = account.linkedDomains
    }

    func account(id: UUID, secret: Data) -> TOTPAccount {
        TOTPAccount(
            id: id,
            issuer: issuer,
            accountName: accountName,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period,
            linkedDomains: linkedDomains
        )
    }
}
