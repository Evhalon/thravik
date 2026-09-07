import Foundation
import RedentKit

/// Resolves which TOTP accounts to offer for a challenge page.
enum OTPSuggestionLoader {
    struct Result {
        let accounts: [TOTPAccount]
        let originMatched: Bool
        let isUnmatched: Bool
        let identityMatched: Bool
        let pinnedAccountID: UUID?
    }

    static func load(
        from store: any TOTPAccountStoring,
        origin: Origin,
        username: String
    ) async throws -> Result {
        let matched = try await store.accounts(for: origin)
        if !matched.isEmpty { return originMatches(matched, username: username) }
        return try await identityFallback(from: store, username: username)
    }

    private static func originMatches(_ matched: [TOTPAccount], username: String) -> Result {
        let ranked = OTPIdentityRanker.prioritize(matched, matching: username)
        let identityMatched = OTPIdentityRanker.identitiesMatch(ranked.first?.accountName ?? "", username)
        return Result(
            accounts: ranked,
            originMatched: true,
            isUnmatched: false,
            identityMatched: identityMatched,
            pinnedAccountID: identityMatched ? ranked.first?.id : nil
        )
    }

    private static func identityFallback(from store: any TOTPAccountStoring, username: String) async throws -> Result {
        let all = try await store.allAccounts()
        let emailHits = OTPIdentityRanker.matching(all, username: username)
        if emailHits.count == 1 {
            return Result(
                accounts: emailHits,
                originMatched: false,
                isUnmatched: false,
                identityMatched: true,
                pinnedAccountID: nil
            )
        }
        return Result(
            accounts: emailHits.isEmpty ? all : emailHits,
            originMatched: false,
            isUnmatched: !all.isEmpty,
            identityMatched: false,
            pinnedAccountID: nil
        )
    }
}
