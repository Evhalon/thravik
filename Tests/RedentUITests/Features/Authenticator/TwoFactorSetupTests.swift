import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Saving a site's two-factor setup")
struct TwoFactorSetupTests {
    private let origin = Origin(scheme: "https", host: "accounts.example.com")
    private let account = TOTPAccount(issuer: "Example", accountName: "me@example.com", secret: Data([1, 2, 3, 4]))
    private let setupQR = "otpauth://totp/Example:me@example.com?secret=AEBAGBA&issuer=Example"

    private func coordinator(
        store: FakeTOTPStore, payloads: [String], decoded: [TOTPAccount]
    ) -> TwoFactorSetupCoordinator {
        TwoFactorSetupCoordinator(
            importer: FakeOTPAuthImporter(result: decoded),
            store: store,
            logger: SilentLogger(),
            readQRCodes: { _ in payloads }
        )
    }

    @Test("The setup QR code is saved and linked to the site that showed it")
    func savesAndLinks() async throws {
        let store = FakeTOTPStore()
        let setup = coordinator(store: store, payloads: [setupQR], decoded: [account])
        setup.setupAppeared(at: origin)
        #expect(setup.phase == .offered)

        let linked = await setup.capture(pageImage: Data([0]))

        #expect(linked == origin)
        #expect(setup.phase == .saved(accountName: account.displayName))
        #expect(try await store.allAccounts().map(\.secret) == [account.secret])
        #expect(await store.links.map(\.1) == ["example.com"])
    }

    @Test("A QR code that is not an authenticator account is never imported")
    func ignoresOtherCodes() async throws {
        let store = FakeTOTPStore()
        let setup = coordinator(store: store, payloads: ["https://apps.apple.com/app/id1"], decoded: [account])
        setup.setupAppeared(at: origin)

        #expect(await setup.capture(pageImage: Data([0])) == nil)
        #expect(setup.phase == .notFound)
        #expect(try await store.allAccounts().isEmpty)
    }

    @Test("A page that could not be captured asks the user to try again")
    func missingImage() async {
        let setup = coordinator(store: FakeTOTPStore(), payloads: [setupQR], decoded: [account])
        setup.setupAppeared(at: origin)
        #expect(await setup.capture(pageImage: nil) == nil)
        #expect(setup.phase == .notFound)
    }

    @Test("An account already in the vault is linked, not duplicated")
    func linksExistingAccount() async throws {
        let existing = TOTPAccount(issuer: "Example", accountName: "me", secret: account.secret)
        let store = FakeTOTPStore([existing])
        let setup = coordinator(store: store, payloads: [setupQR], decoded: [account])
        setup.setupAppeared(at: origin)

        _ = await setup.capture(pageImage: Data([0]))

        #expect(try await store.allAccounts().count == 1)
        #expect(await store.links.map(\.0) == [existing.id])
    }

    @Test("The QR code leaving hides the offer but not a confirmation still on screen")
    func goneKeepsConfirmation() async {
        let setup = coordinator(store: FakeTOTPStore(), payloads: [setupQR], decoded: [account])
        setup.setupAppeared(at: origin)
        setup.setupGone()
        #expect(setup.phase == .hidden)

        setup.setupAppeared(at: origin)
        _ = await setup.capture(pageImage: Data([0]))
        setup.setupGone()
        #expect(setup.isVisible)
        setup.pageChanged()
        #expect(!setup.isVisible)
    }

    @Test("Nothing is captured before a setup page was seen")
    func needsSetupPage() async {
        let setup = coordinator(store: FakeTOTPStore(), payloads: [setupQR], decoded: [account])
        #expect(await setup.capture(pageImage: Data([0])) == nil)
        #expect(setup.phase == .hidden)
    }
}
