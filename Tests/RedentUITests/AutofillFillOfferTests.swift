import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Offering a saved login to fill")
struct AutofillFillOfferTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    private func makeCoordinator(_ store: FakeCredentialStore) -> AutofillCoordinator {
        AutofillCoordinator(store: store, logger: SilentLogger())
    }

    @Test("Only credentials for the same registrable domain are suggested")
    func suggestionScoping() async {
        let store = FakeCredentialStore([
            Credential(origin: origin, username: "mine", password: "a"),
            Credential(origin: Origin(scheme: "https", host: "evil-example.com"),
                       username: "theirs", password: "b")
        ])
        let coordinator = makeCoordinator(store)
        await coordinator.loginFormAppeared(at: Origin(scheme: "https", host: "app.example.com"))
        #expect(coordinator.suggestions.map(\.username) == ["mine"])
        #expect(coordinator.shouldOfferFill)
    }

    @Test("A login form on this origin is offered as a fill choice")
    func offersFillOnLoginForm() async {
        let stored = Credential(origin: origin, username: "me", password: "hunter2")
        let coordinator = makeCoordinator(FakeCredentialStore([stored]))
        await coordinator.loginFormAppeared(at: origin)
        #expect(coordinator.shouldOfferFill)
        #expect(coordinator.suggestions.map(\.username) == ["me"])
    }

    @Test("Navigating to a new host hides the fill offer until that page's form")
    func originChangeHidesOffer() async {
        let coordinator = makeCoordinator(FakeCredentialStore([
            Credential(origin: origin, username: "me", password: "x")
        ]))
        await coordinator.loginFormAppeared(at: origin)
        coordinator.observe(Origin(scheme: "https", host: "other.example"))
        #expect(!coordinator.shouldOfferFill)
        #expect(!coordinator.isLoginFormPresent)
    }

    @Test("A later observe of the same host does not hide an already-shown offer")
    func observeDoesNotClobberForm() async {
        let coordinator = makeCoordinator(FakeCredentialStore([
            Credential(origin: origin, username: "me", password: "x")
        ]))
        await coordinator.loginFormAppeared(at: origin)
        coordinator.observe(origin)
        #expect(coordinator.shouldOfferFill)
    }

    @Test("The fill offer disappears when the login fields leave the page")
    func formGoneHidesOffer() async {
        let coordinator = makeCoordinator(FakeCredentialStore([
            Credential(origin: origin, username: "me", password: "x")
        ]))
        await coordinator.loginFormAppeared(at: origin)
        coordinator.loginFormDisappeared()
        #expect(!coordinator.shouldOfferFill)
        #expect(coordinator.hasSuggestions)
    }

    @Test("Filling a credential immediately hides the fill offer")
    func filledHidesOffer() async {
        let stored = Credential(origin: origin, username: "me", password: "x")
        let store = FakeCredentialStore([stored])
        let coordinator = makeCoordinator(store)
        await coordinator.loginFormAppeared(at: origin)

        await coordinator.credentialFilled(stored)

        #expect(!coordinator.shouldOfferFill)
        #expect(!coordinator.isLoginFormPresent)
        #expect(await store.markUsedCalls == [stored.id])
    }
}
