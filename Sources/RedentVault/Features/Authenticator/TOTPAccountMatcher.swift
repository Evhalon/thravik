import Foundation
import RedentKit

/// Ranks TOTP accounts against an origin for autofill suggestions.
///
/// Pure and separable from Keychain I/O, so the ranking rules can be reasoned
/// about (and tested) without Security.framework in the loop.
enum TOTPAccountMatcher {
    private enum Tier: Int {
        case linked = 0
        case exactIssuer = 1
        case partialIssuer = 2
    }

    /// Best match first. Accounts that match none of the rules are dropped.
    static func rank(_ accounts: [TOTPAccount], for origin: Origin) -> [TOTPAccount] {
        let domain = origin.registrableDomain
        let firstLabel = domain.split(separator: ".").first.map(String.init) ?? domain

        return accounts
            .compactMap { account -> (Tier, TOTPAccount)? in
                guard let tier = tier(for: account, domain: domain, firstLabel: firstLabel) else { return nil }
                return (tier, account)
            }
            .sorted { $0.0.rawValue < $1.0.rawValue }
            .map(\.1)
    }

    private static func tier(for account: TOTPAccount, domain: String, firstLabel: String) -> Tier? {
        if account.linkedDomains.contains(domain) { return .linked }

        let issuer = normalize(account.issuer)
        guard !issuer.isEmpty else { return nil }

        if issuer == normalize(firstLabel) { return .exactIssuer }
        if containsFuzzy(normalize(domain), issuer) { return .partialIssuer }
        return nil
    }

    /// True when the shorter of the two strings is contained in the longer
    /// one and is at least 4 characters — guards against a short issuer like
    /// "X" matching every domain.
    private static func containsFuzzy(_ domain: String, _ issuer: String) -> Bool {
        let (shorter, longer) = issuer.count <= domain.count ? (issuer, domain) : (domain, issuer)
        guard shorter.count >= 4 else { return false }
        return longer.contains(shorter)
    }

    /// Lowercased, letters and digits only — strips spaces and punctuation so
    /// "GitHub, Inc." and "github" compare equal.
    static func normalize(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Normalization for `linkedDomains`: lowercased and trimmed only. These
    /// are compared for exact equality against `Origin.registrableDomain`,
    /// never fuzzy-matched, so dots and hyphens must survive.
    static func normalizeDomain(_ domain: String) -> String {
        domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
