import Foundation
import Testing
@testable import RedentKit

@Suite("Deciding what a submitted password means")
struct CredentialSaveDeciderTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    private func candidate(
        _ username: String, _ password: String, changing: Bool = false
    ) -> CredentialCandidate {
        CredentialCandidate(
            origin: origin, username: username, password: password, isPasswordChange: changing
        )
    }

    @Test("An unseen login is offered as a new entry")
    func newLogin() {
        let outcome = CredentialSaveDecider.outcome(for: candidate("me", "hunter2"), stored: [])
        #expect(outcome == .save(candidate("me", "hunter2")))
    }

    @Test("An empty password is never offered")
    func emptyPassword() {
        #expect(CredentialSaveDecider.outcome(for: candidate("me", ""), stored: []) == nil)
    }

    @Test("A login we already hold is only marked as used")
    func unchanged() {
        let stored = Credential(origin: origin, username: "me", password: "hunter2")
        let outcome = CredentialSaveDecider.outcome(for: candidate("me", "hunter2"), stored: [stored])
        #expect(outcome == .alreadyStored(id: stored.id))
    }

    @Test("A username matches its stored entry whatever the casing")
    func caseInsensitiveIdentity() {
        let stored = Credential(origin: origin, username: "Me@Example.com", password: "old")
        let outcome = CredentialSaveDecider.outcome(for: candidate("me@example.com", "new"), stored: [stored])
        #expect(outcome == .update(existing: stored, candidate: candidate("me@example.com", "new").named("Me@Example.com")))
    }

    @Test("A change-password form with no username updates the entry we hold")
    func passwordChangeWithoutUsername() {
        let stored = Credential(origin: origin, username: "me", password: "old")
        let outcome = CredentialSaveDecider.outcome(
            for: candidate("", "new", changing: true), stored: [stored]
        )
        guard case .update(let existing, let resolved) = outcome else {
            Issue.record("expected an update, got \(String(describing: outcome))")
            return
        }
        #expect(existing.id == stored.id)
        #expect(resolved.username == "me")
        #expect(resolved.password == "new")
    }

    @Test("A change-password form attributes to the most-recently-used entry")
    func passwordChangePicksMostRecentlyUsed() {
        let recent = Credential(origin: origin, username: "current", password: "old")
        let stale = Credential(origin: origin, username: "retired", password: "older")
        let outcome = CredentialSaveDecider.outcome(
            for: candidate("", "new", changing: true), stored: [recent, stale]
        )
        guard case .update(let existing, _) = outcome else {
            Issue.record("expected an update, got \(String(describing: outcome))")
            return
        }
        #expect(existing.id == recent.id)
    }

    @Test("The username seen earlier on the origin wins over the ranking")
    func identityHintWins() {
        let recent = Credential(origin: origin, username: "first", password: "old")
        let other = Credential(origin: origin, username: "second", password: "older")
        let outcome = CredentialSaveDecider.outcome(
            for: candidate("", "new", changing: true), stored: [recent, other], identityHint: "second"
        )
        guard case .update(let existing, _) = outcome else {
            Issue.record("expected an update, got \(String(describing: outcome))")
            return
        }
        #expect(existing.id == other.id)
    }

    @Test("A nameless sign-in is never attributed to a stored entry")
    func namelessLoginIsNotAChange() {
        let stored = Credential(origin: origin, username: "me", password: "old")
        let outcome = CredentialSaveDecider.outcome(for: candidate("", "new"), stored: [stored])
        #expect(outcome == .save(candidate("", "new")))
    }

    @Test("A change on an origin we hold nothing for is offered as a new entry")
    func passwordChangeWithNothingStored() {
        let outcome = CredentialSaveDecider.outcome(
            for: candidate("", "new", changing: true), stored: [], identityHint: "me"
        )
        #expect(outcome == .save(candidate("", "new", changing: true).named("me")))
    }
}
