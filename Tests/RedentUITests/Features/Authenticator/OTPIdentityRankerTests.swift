import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Matching TOTP accounts to a typed login identity")
struct OTPIdentityRankerTests {
    private func account(_ name: String, issuer: String = "GitHub") -> TOTPAccount {
        TOTPAccount(issuer: issuer, accountName: name, secret: Data(name.utf8))
    }

    @Test("The matching email is sorted first")
    func matchingEmailLeads() {
        let ranked = OTPIdentityRanker.prioritize(
            [account("other@x.com"), account("me@x.com")],
            matching: "me@x.com"
        )
        #expect(ranked.first?.accountName == "me@x.com")
        #expect(ranked.count == 2)
    }

    @Test("Comparison is case-insensitive and trims whitespace")
    func normalizedMatch() {
        #expect(OTPIdentityRanker.identitiesMatch("Me@X.com", "  me@x.com "))
    }

    @Test("A substring of an email is not a match")
    func noSubstring() {
        #expect(!OTPIdentityRanker.identitiesMatch("me@x.com", "me"))
        #expect(!OTPIdentityRanker.identitiesMatch("other@x.com", "me@x.com"))
    }

    @Test("An empty identity never matches")
    func emptyNeverMatches() {
        #expect(!OTPIdentityRanker.identitiesMatch("me@x.com", ""))
        #expect(OTPIdentityRanker.matching([account("me@x.com")], username: "").isEmpty)
    }
}
