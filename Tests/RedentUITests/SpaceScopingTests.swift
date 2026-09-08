import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// A Space is a profile: what one Space knows must not surface in another.
@MainActor
@Suite("Spaces keep their logins and saved pages to themselves")
struct SpaceScopingTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    @Test("Autofill offers only the logins saved in this Space")
    func autofillIsScoped() async {
        let work = Credential(origin: origin, username: "me@work", password: "a", spaceID: BrowserSpace.workID)
        let personal = Credential(
            origin: origin, username: "me@home", password: "b", spaceID: BrowserSpace.personalID
        )
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([work, personal]), logger: SilentLogger()
        )
        coordinator.setSpace(BrowserSpace.personalID)
        await coordinator.loginFormAppeared(at: origin)
        #expect(coordinator.suggestions.map(\.username) == ["me@home"])
    }

    @Test("The same login in another Space is offered for saving here")
    func sameLoginInAnotherSpaceIsNew() async {
        let elsewhere = Credential(
            origin: origin, username: "me", password: "hunter2", spaceID: BrowserSpace.travelID
        )
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([elsewhere]), logger: SilentLogger()
        )
        coordinator.setSpace(BrowserSpace.workID)
        await coordinator.credentialSubmitted(
            CredentialCandidate(origin: origin, username: "me", password: "hunter2")
        )
        #expect(coordinator.pendingSave?.kind == .new)
        #expect(coordinator.pendingSave?.resolvedCredential.spaceID == BrowserSpace.workID)
    }

    @Test("Switching Space clears what the old one had on offer")
    func switchingSpaceClearsSuggestions() async {
        let work = Credential(origin: origin, username: "me@work", password: "a", spaceID: BrowserSpace.workID)
        let coordinator = AutofillCoordinator(
            store: FakeCredentialStore([work]), logger: SilentLogger()
        )
        coordinator.setSpace(BrowserSpace.workID)
        await coordinator.loginFormAppeared(at: origin)
        #expect(coordinator.hasSuggestions)
        coordinator.setSpace(BrowserSpace.travelID)
        #expect(coordinator.hasSuggestions == false)
    }
}
