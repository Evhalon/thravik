import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// Passwords are one global vault even when browsing data belongs to Spaces.
@MainActor
@Suite("Passwords are shared across Spaces")
struct SpaceScopingTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    @Test("Autofill offers logins saved from every Space")
    func autofillIsGlobal() async {
        let work = Credential(origin: origin, username: "me@work", password: "a", spaceID: BrowserSpace.workID)
        let personal = Credential(
            origin: origin, username: "me@home", password: "b", spaceID: BrowserSpace.personalID
        )
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([work, personal]), logger: SilentLogger()
        )
        await coordinator.loginFormAppeared(at: origin)
        #expect(Set(coordinator.suggestions.map(\.username)) == Set(["me@work", "me@home"]))
    }

    @Test("The same login saved in another Space is already known")
    func sameLoginInAnotherSpaceIsKnown() async {
        let elsewhere = Credential(
            origin: origin, username: "me", password: "hunter2", spaceID: BrowserSpace.travelID
        )
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([elsewhere]), logger: SilentLogger()
        )
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "hunter2")
        )
        #expect(coordinator.pendingSave == nil)
    }

    @Test("A saved login remains available without Space context")
    func loginNeedsNoSpaceContext() async {
        let work = Credential(origin: origin, username: "me@work", password: "a", spaceID: BrowserSpace.workID)
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([work]), logger: SilentLogger()
        )
        await coordinator.loginFormAppeared(at: origin)
        #expect(coordinator.hasSuggestions)
    }
}
