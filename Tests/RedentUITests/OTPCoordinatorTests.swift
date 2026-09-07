import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Driving the floating one-time-code button")
struct OTPCoordinatorTests {
    private let origin = Origin(scheme: "https", host: "github.com")

    private func makeCoordinator(_ store: FakeTOTPStore) -> OTPCoordinator {
        OTPCoordinator(store: store, generator: FakeGenerator(), logger: SilentLogger())
    }

    private var account: TOTPAccount {
        TOTPAccount(issuer: "github", accountName: "me", secret: Data([9]))
    }

    @Test("No matching account means no button")
    func noAccounts() async {
        let coordinator = makeCoordinator(FakeTOTPStore())
        await coordinator.fieldAppeared(at: origin)
        #expect(!coordinator.isVisible)
    }

    @Test("A matching account produces a live code")
    func showsCode() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        #expect(coordinator.isVisible)
        #expect(coordinator.primary?.code.digits == "123456")
        #expect(coordinator.shouldAutoFill)
    }

    @Test("The button disappears with the field")
    func hidesAgain() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        coordinator.fieldDisappeared()
        #expect(!coordinator.isVisible)
        #expect(coordinator.origin == nil)
    }

    @Test("Choosing an account pins it to the site for next time")
    func remembersChoice() async throws {
        let store = FakeTOTPStore([account])
        let coordinator = makeCoordinator(store)
        await coordinator.fieldAppeared(at: origin)
        let suggestion = try #require(coordinator.primary)
        await coordinator.remember(suggestion)
        #expect(coordinator.pinnedAccountID == suggestion.id)
        #expect(await store.links.first?.1 == "github.com")
    }

    @Test("Ticking inside the window leaves the code alone")
    func tickWithinWindow() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        let before = coordinator.primary?.code.validFrom
        coordinator.tick(.now.addingTimeInterval(1))
        #expect(coordinator.primary?.code.validFrom == before)
    }

    @Test("A site nothing matches still offers every account to choose from")
    func unmatchedSiteFallsBack() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: Origin(scheme: "https", host: "octane.internal.example"))
        #expect(coordinator.isVisible)
        #expect(coordinator.isUnmatched)
        #expect(!coordinator.shouldAutoFill)
    }

    @Test("A matched site is not flagged as a guess")
    func matchedSiteIsNotFlagged() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        #expect(!coordinator.isUnmatched)
    }

    @Test("With no accounts at all there is nothing to offer")
    func noAccountsAtAll() async {
        let coordinator = makeCoordinator(FakeTOTPStore())
        await coordinator.fieldAppeared(at: Origin(scheme: "https", host: "dropbox.com"))
        #expect(!coordinator.isVisible)
        #expect(!coordinator.isUnmatched)
    }

    @Test("Choosing an account for an unmatched site clears the guess flag")
    func rememberClearsUnmatched() async throws {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: Origin(scheme: "https", host: "octane.internal.example"))
        let suggestion = try #require(coordinator.primary)
        await coordinator.remember(suggestion)
        #expect(!coordinator.isUnmatched)
    }

    @Test("Leaving the page after a fill hides the button")
    func hidesAfterFilledNavigation() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        let filled = URL(string: "https://github.com/sessions/two-factor")
        coordinator.markFilled(at: filled)
        #expect(coordinator.isVisible)
        #expect(!coordinator.shouldAutoFill)
        coordinator.dismissIfPageChanged(URL(string: "https://github.com/"))
        #expect(!coordinator.isVisible)
    }

    @Test("Staying on the challenge page after a fill keeps the button")
    func staysOnSameURLAfterFill() async {
        let coordinator = makeCoordinator(FakeTOTPStore([account]))
        await coordinator.fieldAppeared(at: origin)
        let url = URL(string: "https://github.com/sessions/two-factor")
        coordinator.markFilled(at: url)
        coordinator.dismissIfPageChanged(url)
        #expect(coordinator.isVisible)
    }
}
