import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Matching Authenticator accounts to sites")
struct TOTPAccountMatcherTests {
    private func account(
        issuer: String,
        name: String = "me@example.com",
        linked: Set<String> = []
    ) -> TOTPAccount {
        TOTPAccount(issuer: issuer, accountName: name, secret: Data([1, 2, 3]), linkedDomains: linked)
    }

    private func origin(_ host: String) throws -> Origin {
        let url = try #require(URL(string: "https://\(host)"))
        return try #require(Origin(url: url))
    }

    @Test("An issuer matching the site's name is offered")
    func exactIssuer() throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: "GitHub")], for: try origin("github.com"))
        #expect(ranked.count == 1)
    }

    @Test("Issuer matching ignores case and spacing")
    func normalizedIssuer() throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: "Git Hub")], for: try origin("github.com"))
        #expect(ranked.count == 1)
    }

    @Test("A subdomain still resolves to the site")
    func subdomain() throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: "GitHub")], for: try origin("gist.github.com"))
        #expect(ranked.count == 1)
    }

    @Test("An explicitly linked domain outranks a name match")
    func linkedWins() throws {
        let linked = account(issuer: "Work SSO", name: "a", linked: ["github.com"])
        let named = account(issuer: "GitHub", name: "b")
        let ranked = TOTPAccountMatcher.rank([named, linked], for: try origin("github.com"))
        #expect(ranked.first?.accountName == "a")
        #expect(ranked.count == 2)
    }

    @Test("Unrelated accounts are dropped, not merely ranked low")
    func unrelatedDropped() throws {
        let ranked = TOTPAccountMatcher.rank(
            [account(issuer: "Dropbox"), account(issuer: "Fastmail")],
            for: try origin("github.com")
        )
        #expect(ranked.isEmpty)
    }

    @Test("A very short issuer does not match everything", arguments: ["X", "AWS", "Ok"])
    func shortIssuerIsNotAWildcard(_ issuer: String) throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: issuer)], for: try origin("github.com"))
        #expect(ranked.isEmpty)
    }

    @Test("A lookalike host does not surface the real account")
    func lookalikeHost() throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: "GitHub")], for: try origin("github.com.evil.tld"))
        #expect(ranked.isEmpty)
    }

    @Test("Multi-label suffixes resolve to the right site")
    func multiLabelSuffix() throws {
        let ranked = TOTPAccountMatcher.rank([account(issuer: "Monzo")], for: try origin("app.monzo.co.uk"))
        #expect(ranked.count == 1)
    }
}
