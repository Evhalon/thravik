import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Picking and auto-filling a TOTP account by email")
struct OTPCoordinatorIdentityTests {
    private let origin = Origin(scheme: "https", host: "github.com")

    private func makeCoordinator(_ store: FakeTOTPStore) -> OTPCoordinator {
        OTPCoordinator(store: store, generator: FakeGenerator(), logger: SilentLogger())
    }

    @Test("Two site matches wait for a tap unless the email picks one")
    func twoMatchesNeedEmail() async {
        let store = FakeTOTPStore([
            TOTPAccount(issuer: "github", accountName: "a@x.com", secret: Data([1])),
            TOTPAccount(issuer: "github", accountName: "b@x.com", secret: Data([2]))
        ])
        let coordinator = makeCoordinator(store)
        await coordinator.fieldAppeared(at: origin)
        #expect(!coordinator.shouldAutoFill)
        #expect(coordinator.suggestions.count == 2)

        await coordinator.fieldAppeared(at: origin, username: "b@x.com")
        #expect(coordinator.shouldAutoFill)
        #expect(coordinator.primary?.account.accountName == "b@x.com")
    }

    @Test("A unique email on an unknown site still auto-fills")
    func uniqueEmailOnUnknownSite() async {
        let store = FakeTOTPStore([
            TOTPAccount(issuer: "github", accountName: "me@x.com", secret: Data([1]))
        ])
        let coordinator = makeCoordinator(store)
        await coordinator.fieldAppeared(
            at: Origin(scheme: "https", host: "octane.internal.example"),
            username: "me@x.com"
        )
        #expect(coordinator.shouldAutoFill)
        #expect(!coordinator.originMatched)
        #expect(coordinator.primary?.account.accountName == "me@x.com")
    }

    @Test("Several emails on an unknown site do not auto-fill")
    func severalEmailsStayAChoice() async {
        let store = FakeTOTPStore([
            TOTPAccount(issuer: "github", accountName: "me@x.com", secret: Data([1])),
            TOTPAccount(issuer: "dropbox", accountName: "me@x.com", secret: Data([2]))
        ])
        let coordinator = makeCoordinator(store)
        await coordinator.fieldAppeared(
            at: Origin(scheme: "https", host: "octane.internal.example"),
            username: "me@x.com"
        )
        #expect(!coordinator.shouldAutoFill)
        #expect(coordinator.isUnmatched)
        #expect(coordinator.suggestions.count == 2)
    }
}
