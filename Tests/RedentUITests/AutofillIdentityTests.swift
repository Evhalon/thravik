import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Remembering the login identity for TOTP matching")
struct AutofillIdentityTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    @Test("Filling a saved login remembers its username")
    func filledCredentialSetsHint() async {
        let stored = Credential(origin: origin, username: "me@x.com", password: "x")
        let coordinator = AutofillCoordinator(store: FakeCredentialStore([stored]), logger: SilentLogger())
        await coordinator.credentialFilled(stored)
        #expect(coordinator.identityHint == "me@x.com")
    }

    @Test("A typed identity wins over the saved login")
    func typedIdentityWins() async {
        let stored = Credential(origin: origin, username: "saved@x.com", password: "x")
        let coordinator = AutofillCoordinator(store: FakeCredentialStore([stored]), logger: SilentLogger())
        await coordinator.loginFormAppeared(at: origin)
        coordinator.captureIdentity("typed@x.com")
        #expect(coordinator.identityHint == "typed@x.com")
    }

    @Test("Changing origin clears the remembered identity")
    func originChangeClearsHint() async {
        let coordinator = AutofillCoordinator(store: FakeCredentialStore(), logger: SilentLogger())
        coordinator.captureIdentity("me@x.com")
        coordinator.observe(Origin(scheme: "https", host: "other.com"))
        #expect(coordinator.identityHint.isEmpty)
    }
}
