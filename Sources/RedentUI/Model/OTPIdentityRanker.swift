import Foundation
import RedentKit

/// Puts TOTP accounts whose `accountName` matches a typed or saved login
/// identity (usually an email) ahead of the rest. Comparison is exact after
/// trim + lowercase — never a substring, so one address cannot pull in another.
enum OTPIdentityRanker {
    static func prioritize(_ accounts: [TOTPAccount], matching username: String) -> [TOTPAccount] {
        let hits = matching(accounts, username: username)
        guard !hits.isEmpty else { return accounts }
        let hitIDs = Set(hits.map(\.id))
        return hits + accounts.filter { !hitIDs.contains($0.id) }
    }

    static func matching(_ accounts: [TOTPAccount], username: String) -> [TOTPAccount] {
        accounts.filter { identitiesMatch($0.accountName, username) }
    }

    static func identitiesMatch(_ accountName: String, _ username: String) -> Bool {
        let left = normalize(accountName)
        let right = normalize(username)
        guard !left.isEmpty, !right.isEmpty else { return false }
        return left == right
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
