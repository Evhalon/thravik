import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// A sign-in pill the user closed stays closed until the page changes — a page
/// re-rendering its form must not bring it straight back.
@MainActor
@Suite("Dismissing sign-in pills")
struct PillDismissalTests {
    private let origin = Origin(scheme: "https", host: "example.com")

    @Test("A dismissed fill offer survives the form being detected again")
    func fillOfferStaysDismissed() async {
        let stored = Credential(origin: origin, username: "me", password: "x")
        let coordinator = AutofillCoordinator(store: FakeCredentialStore([stored]), logger: SilentLogger())
        await coordinator.loginFormAppeared(at: origin)
        coordinator.dismissFillOffer()
        #expect(!coordinator.shouldOfferFill)
        await coordinator.loginFormAppeared(at: origin)
        #expect(!coordinator.shouldOfferFill)
    }

    @Test("A new page offers the fill again")
    func fillOfferReturnsOnNewPage() async {
        let stored = Credential(origin: origin, username: "me", password: "x")
        let coordinator = AutofillCoordinator(store: FakeCredentialStore([stored]), logger: SilentLogger())
        await coordinator.loginFormAppeared(at: origin)
        coordinator.dismissFillOffer()
        coordinator.pageChanged()
        await coordinator.loginFormAppeared(at: origin)
        #expect(coordinator.shouldOfferFill)
    }

    @Test("Dismissing the code button hides it until the page changes")
    func codeButtonDismissal() async {
        let account = TOTPAccount(issuer: "example", accountName: "me", secret: Data([9]))
        let coordinator = OTPCoordinator(
            store: FakeTOTPStore([account]), generator: FakeGenerator(), logger: SilentLogger()
        )
        await coordinator.fieldAppeared(at: origin)
        coordinator.dismiss()
        #expect(!coordinator.isVisible)
        #expect(coordinator.isDismissed)
        coordinator.pageChanged()
        #expect(!coordinator.isDismissed)
    }
}
