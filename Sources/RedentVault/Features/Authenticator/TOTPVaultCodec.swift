import Foundation
import RedentKit

enum TOTPVaultCodec {
    private struct Entry: Codable {
        let id: UUID
        let issuer: String
        let accountName: String
        let secret: Data
        let algorithm: TOTPAlgorithm
        let digits: Int
        let period: Int
        var linkedDomains: Set<String>

        init(_ account: TOTPAccount) {
            id = account.id
            issuer = account.issuer
            accountName = account.accountName
            secret = account.secret
            algorithm = account.algorithm
            digits = account.digits
            period = account.period
            linkedDomains = account.linkedDomains
        }

        var account: TOTPAccount {
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

    static func encode(_ accounts: [TOTPAccount]) throws -> Data {
        try JSONEncoder().encode(accounts.map(Entry.init))
    }

    static func decode(_ data: Data) throws -> [TOTPAccount] {
        do {
            return try JSONDecoder().decode([Entry].self, from: data).map(\.account)
        } catch {
            throw VaultError.invalidData
        }
    }
}
