import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Saving scanned authenticator codes immediately")
struct AuthenticatorImportModelTests {
    private var sample: TOTPAccount {
        TOTPAccount(issuer: "GitHub", accountName: "me@x.com", secret: Data([9, 9, 9]))
    }

    @Test("A valid payload is written to the vault")
    func persistsValidPayload() async throws {
        let store = FakeTOTPStore()
        let model = AuthenticatorImportModel(
            importer: FakeOTPAuthImporter(result: [sample]),
            store: store
        )
        _ = await model.collector.add(payloadText: "otpauth://totp/GitHub:me")
        await model.persistNewAccounts()
        let saved = try await store.allAccounts()
        #expect(model.addedCount == 1)
        #expect(saved.count == 1)
        #expect(model.outcome?.accounts.map(\.accountName) == ["me@x.com"])
        #expect(model.outcome?.added == 1)
        #expect(!model.isScanning)
    }

    @Test("The same payload is not imported twice")
    func skipsAlreadyPersisted() async throws {
        let store = FakeTOTPStore()
        let model = AuthenticatorImportModel(
            importer: FakeOTPAuthImporter(result: [sample]),
            store: store
        )
        _ = await model.collector.add(payloadText: "otpauth://totp/GitHub:me")
        await model.persistNewAccounts()
        await model.persistNewAccounts()
        let saved = try await store.allAccounts()
        #expect(model.addedCount == 1)
        #expect(saved.count == 1)
    }

    @Test("A seed already in the vault is counted as already present")
    func reportsAlreadyStored() async throws {
        let store = FakeTOTPStore([sample])
        let model = AuthenticatorImportModel(
            importer: FakeOTPAuthImporter(result: [sample]),
            store: store
        )
        _ = await model.collector.add(payloadText: "otpauth://totp/GitHub:me")
        await model.persistNewAccounts()
        #expect(model.addedCount == 0)
        #expect(model.alreadyPresentCount == 1)
        #expect(model.outcome?.headline == "Already saved")
        #expect(!model.isScanning)
    }

    @Test("Garbage text does not touch the vault")
    func invalidPayloadIsIgnored() async throws {
        let store = FakeTOTPStore()
        let model = AuthenticatorImportModel(
            importer: FakeOTPAuthImporter(error: .malformedPayload),
            store: store
        )
        _ = await model.collector.add(payloadText: "not-a-qr")
        await model.persistNewAccounts()
        let saved = try await store.allAccounts()
        #expect(model.addedCount == 0)
        #expect(saved.isEmpty)
        #expect(model.outcome == nil)
        #expect(model.isScanning)
    }

    @Test("Add another returns to a fresh scan")
    func scanAgainClearsOutcome() async throws {
        let store = FakeTOTPStore()
        let model = AuthenticatorImportModel(
            importer: FakeOTPAuthImporter(result: [sample]),
            store: store
        )
        _ = await model.collector.add(payloadText: "otpauth://totp/GitHub:me")
        await model.persistNewAccounts()
        model.scanAgain()
        #expect(model.outcome == nil)
        #expect(model.isScanning)
        #expect(model.collector.isEmpty)
    }
}
