import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Deciding when to offer to save a password")
struct AutofillCoordinatorTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    private func makeCoordinator(_ store: FakeCredentialStore) -> AutofillCoordinator {
        AutofillCoordinator(store: store, logger: SilentLogger())
    }

    @Test("An unseen login is offered for saving")
    func newLogin() async {
        let coordinator = makeCoordinator(FakeCredentialStore())
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "hunter2")
        )
        #expect(coordinator.pendingSave?.kind == .new)
    }

    @Test("Re-entering a password we already have prompts nothing")
    func unchangedLogin() async {
        let stored = Credential(origin: origin, username: "me", password: "hunter2")
        let coordinator = makeCoordinator(FakeCredentialStore([stored]))
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "hunter2")
        )
        #expect(coordinator.pendingSave == nil)
    }

    @Test("A changed password is offered as an update, reusing the same entry")
    func changedPassword() async {
        let stored = Credential(origin: origin, username: "me", password: "old")
        let coordinator = makeCoordinator(FakeCredentialStore([stored]))
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "new")
        )
        #expect(coordinator.pendingSave?.kind == .updatedPassword)
        #expect(coordinator.pendingSave?.existingID == stored.id)
    }

    @Test("Changing a password on a settings page is offered as an update")
    func passwordChangedOnSettingsPage() async {
        let stored = Credential(origin: origin, username: "me", password: "old")
        let store = FakeCredentialStore([stored])
        let coordinator = makeCoordinator(store)
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "", password: "new", isPasswordChange: true)
        )
        #expect(coordinator.pendingSave?.kind == .updatedPassword)
        #expect(coordinator.pendingSave?.existingID == stored.id)
        #expect(coordinator.pendingSave?.candidate.username == "me")
    }

    @Test("Accepting an update keeps the entry's history instead of resetting it")
    func updateKeepsRanking() async throws {
        let used = Date(timeIntervalSince1970: 1_000)
        let stored = Credential(
            origin: origin, username: "me", password: "old",
            createdAt: Date(timeIntervalSince1970: 1), lastUsedAt: used, useCount: 7
        )
        let store = FakeCredentialStore([stored])
        let coordinator = makeCoordinator(store)
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "new")
        )
        await coordinator.confirmPendingSave()

        let saved = try #require(await store.credentials(for: origin, in: nil).first)
        #expect(saved.id == stored.id)
        #expect(saved.password == "new")
        #expect(saved.useCount == 7)
        #expect(saved.lastUsedAt == used)
        #expect(saved.createdAt == stored.createdAt)
    }

    @Test("An empty password is never offered")
    func emptyPassword() async {
        let coordinator = makeCoordinator(FakeCredentialStore())
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "")
        )
        #expect(coordinator.pendingSave == nil)
    }

    @Test("Turning the feature off suppresses the prompt")
    func disabled() async {
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore(), logger: SilentLogger(), isEnabled: false
        )
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "x")
        )
        #expect(coordinator.pendingSave == nil)
    }
}
