import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct CloudVaultAccessTests {
    @Test func requiresConfirmationAndRecoversOnAnotherDevice() async throws {
        let sessions = RecoverySessions()
        let envelopes = RecoveryEnvelopes()
        let keys = RecoveryKeys()
        let access = CloudVaultAccess(configuration: .init(keys: keys, sessions: sessions, envelopes: envelopes))
        #expect(try await access.status() == .needsCreation)
        let code = try await access.prepareVault()
        #expect(await keys.load(accountID: sessions.value.accountID) == nil)
        #expect(await envelopes.load(session: sessions.value) == nil)
        try await access.activateVault()
        #expect(try await access.status() == .ready)
        let otherKeys = RecoveryKeys()
        let other = CloudVaultAccess(configuration: .init(keys: otherKeys, sessions: sessions, envelopes: envelopes))
        #expect(try await other.status() == .needsRecovery)
        try await other.recover(code: code)
        let restored = await otherKeys.load(accountID: sessions.value.accountID)
        let original = await keys.load(accountID: sessions.value.accountID)
        #expect(restored == original)
    }

    @Test func racingCreationNeverReplacesRoot() async throws {
        let sessions = RecoverySessions()
        let envelopes = RecoveryEnvelopes()
        let first = CloudVaultAccess(configuration: .init(keys: RecoveryKeys(), sessions: sessions, envelopes: envelopes))
        let second = CloudVaultAccess(configuration: .init(keys: RecoveryKeys(), sessions: sessions, envelopes: envelopes))
        let code = try await first.prepareVault()
        _ = try await second.prepareVault()
        try await first.activateVault()
        await #expect(throws: SyncError.revisionConflict) { try await second.activateVault() }
        try await second.recover(code: code)
        #expect(try await second.status() == .ready)
    }

    @Test func keychainFailureRetainsSameRecoveryCodeForRetry() async throws {
        let sessions = RecoverySessions()
        let keys = RecoveryKeys()
        let access = CloudVaultAccess(configuration: .init(keys: keys, sessions: sessions, envelopes: RecoveryEnvelopes()))
        let code = try await access.prepareVault()
        await keys.failNextSave()
        await #expect(throws: SyncError.unavailable) { try await access.activateVault() }
        #expect(try await access.prepareVault() == code)
        try await access.activateVault()
        #expect(try await access.status() == .ready)
    }

    @Test func recoveryCodeIsBoundToAccount() async throws {
        let firstID = UUID()
        let secondID = UUID()
        let crypto = SyncRecoveryCryptography()
        let bundle = try crypto.createBundle(rootKey: Data(repeating: 1, count: 32), accountID: firstID)
        #expect(throws: (any Error).self) {
            try crypto.recoverRootKey(code: bundle.recoveryCode, accountID: secondID,
                                      envelope: bundle.wrappedRootKey)
        }
    }

    @Test func localRootAllowsOfflineAccessWithExpiredSession() async throws {
        let cached = AccountSession(accountID: UUID(), accessToken: "expired", refreshToken: "test",
                                    expiresAt: .distantPast)
        let keys = RecoveryKeys()
        try await keys.save(Data(repeating: 1, count: 32), accountID: cached.accountID)
        let access = CloudVaultAccess(configuration: .init(keys: keys,
            sessions: OfflineRecoverySession(value: cached), envelopes: OfflineRecoveryEnvelopes()))
        #expect(try await access.status() == .ready)
    }

    @Test func wrongCodeNeverStoresRoot() async throws {
        let sessions = RecoverySessions()
        let envelopes = RecoveryEnvelopes()
        let access = CloudVaultAccess(configuration: .init(keys: RecoveryKeys(), sessions: sessions, envelopes: envelopes))
        _ = try await access.prepareVault()
        try await access.activateVault()
        let keys = RecoveryKeys()
        let other = CloudVaultAccess(configuration: .init(keys: keys, sessions: sessions, envelopes: envelopes))
        await #expect(throws: SyncCryptoError.invalidRecoveryCode) { try await other.recover(code: "wrong") }
        #expect(await keys.load(accountID: sessions.value.accountID) == nil)
    }
}

private actor RecoveryKeys: SyncKeyStoring {
    var values: [UUID: Data] = [:]
    var fails = false
    func failNextSave() { fails = true }
    func load(accountID: UUID) -> Data? { values[accountID] }
    func save(_ key: Data, accountID: UUID) throws {
        if fails { fails = false; throw SyncError.unavailable }
        values[accountID] = key
    }
    func delete(accountID: UUID) { values[accountID] = nil }
}

private actor RecoveryEnvelopes: RecoveryEnvelopeStoring {
    var values: [UUID: SyncEncryptedEnvelope] = [:]
    func load(session: AccountSession) -> SyncEncryptedEnvelope? { values[session.accountID] }
    func saveIfAbsent(_ envelope: SyncEncryptedEnvelope, session: AccountSession) -> Bool {
        if let existing = values[session.accountID] { return existing == envelope }
        values[session.accountID] = envelope
        return true
    }
}

private actor RecoverySessions: AccountSessionStoring {
    nonisolated let value = AccountSession(accountID: UUID(), accessToken: "test", refreshToken: "test",
                                           expiresAt: .distantFuture)
    func load() -> AccountSession? { value }
    func save(_ session: AccountSession) {}
    func clear() {}
}

private struct OfflineRecoverySession: AccountSessionStoring {
    let value: AccountSession
    func load() async throws -> AccountSession? { value }
    func save(_ session: AccountSession) async throws {}
    func clear() async throws {}
}

private struct OfflineRecoveryEnvelopes: RecoveryEnvelopeStoring {
    func load(session: AccountSession) async throws -> SyncEncryptedEnvelope? { throw SyncError.unavailable }
    func saveIfAbsent(_ envelope: SyncEncryptedEnvelope, session: AccountSession) async throws -> Bool {
        throw SyncError.unavailable
    }
}
