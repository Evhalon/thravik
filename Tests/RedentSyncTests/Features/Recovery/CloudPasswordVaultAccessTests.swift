import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct CloudPasswordVaultAccessTests {
    @Test func masterPasswordRestoresTenIndependentMacs() async throws {
        let backend = PasswordVaultFixture()
        let firstKeys = PasswordVaultKeys()
        let first = backend.access(keys: firstKeys)
        let code = try await first.prepareVault(password: "ten Macs share this long password")
        #expect(await firstKeys.load(accountID: backend.session.accountID) == nil)
        try await first.activateVault()
        #expect(try await first.passwordConfigured())
        let expected = await firstKeys.load(accountID: backend.session.accountID)

        for _ in 0..<10 {
            let keys = PasswordVaultKeys()
            let next = backend.access(keys: keys)
            #expect(try await next.status() == .needsRecovery)
            #expect(try await next.unlock(password: "ten Macs share this long password") == code)
            #expect(await keys.load(accountID: backend.session.accountID) == expected)
        }
    }

    @Test func wrongMasterPasswordNeverStoresRoot() async throws {
        let backend = PasswordVaultFixture()
        let first = backend.access(keys: PasswordVaultKeys())
        _ = try await first.prepareVault(password: "a strong sync password")
        try await first.activateVault()
        let keys = PasswordVaultKeys()
        let next = backend.access(keys: keys)
        await #expect(throws: PasswordStorageError.invalidSyncPassword) {
            try await next.unlock(password: "the wrong sync password")
        }
        #expect(await keys.load(accountID: backend.session.accountID) == nil)
    }

    @Test func recoveryBackupResetsPasswordWithoutChangingRoot() async throws {
        let backend = PasswordVaultFixture()
        let keys = PasswordVaultKeys()
        let first = backend.access(keys: keys)
        let code = try await first.prepareVault(password: "original sync password")
        try await first.activateVault()
        let root = await keys.load(accountID: backend.session.accountID)
        try await first.enablePassword(password: "replacement sync password", recoveryCode: code)
        let otherKeys = PasswordVaultKeys()
        let next = backend.access(keys: otherKeys)
        await #expect(throws: PasswordStorageError.invalidSyncPassword) {
            try await next.unlock(password: "original sync password")
        }
        _ = try await next.unlock(password: "replacement sync password")
        #expect(await otherKeys.load(accountID: backend.session.accountID) == root)
    }

    @Test func interruptedPasswordPublicationCanRetryActivation() async throws {
        let backend = PasswordVaultFixture()
        let first = backend.access(keys: PasswordVaultKeys())
        _ = try await first.prepareVault(password: "a strong sync password")
        await backend.passwords.failNextSave()
        await #expect(throws: SyncError.unavailable) { try await first.activateVault() }
        try await first.activateVault()
        #expect(try await first.passwordConfigured())
    }

    @Test func existingRecoveryVaultGainsMasterPasswordWithoutChangingRoot() async throws {
        let backend = PasswordVaultFixture()
        let keys = PasswordVaultKeys()
        let legacy = backend.legacy(keys: keys)
        let code = try await legacy.prepareVault()
        try await legacy.activateVault()
        let root = await keys.load(accountID: backend.session.accountID)
        let upgraded = backend.access(keys: keys)
        await #expect(throws: PasswordStorageError.invalidRecoveryCode) {
            try await upgraded.enablePassword(password: "a strong sync password", recoveryCode: "wrong")
        }
        #expect(!(try await upgraded.passwordConfigured()))
        try await upgraded.enablePassword(password: "a strong sync password", recoveryCode: code)
        let otherKeys = PasswordVaultKeys()
        _ = try await backend.access(keys: otherKeys).unlock(password: "a strong sync password")
        #expect(await otherKeys.load(accountID: backend.session.accountID) == root)
    }
}

private struct PasswordVaultFixture {
    let session = AccountSession(accountID: UUID(), accessToken: "test", refreshToken: "test", expiresAt: .distantFuture)
    let recovery = PasswordVaultRecovery()
    let passwords = PasswordVaultEnvelopes()

    func legacy(keys: PasswordVaultKeys) -> CloudVaultAccess {
        CloudVaultAccess(configuration: .init(keys: keys, sessions: PasswordVaultSessions(value: session), envelopes: recovery))
    }

    func access(keys: PasswordVaultKeys) -> CloudPasswordVaultAccess {
        CloudPasswordVaultAccess(underlying: legacy(keys: keys), sessions: PasswordVaultSessions(value: session),
                                 envelopes: passwords, recovery: recovery)
    }
}

private actor PasswordVaultKeys: SyncKeyStoring {
    private var values: [UUID: Data] = [:]
    func load(accountID: UUID) -> Data? { values[accountID] }
    func save(_ key: Data, accountID: UUID) { values[accountID] = key }
    func delete(accountID: UUID) { values[accountID] = nil }
}

private actor PasswordVaultRecovery: RecoveryEnvelopeStoring {
    private var values: [UUID: SyncEncryptedEnvelope] = [:]
    func load(session: AccountSession) -> SyncEncryptedEnvelope? { values[session.accountID] }
    func saveIfAbsent(_ envelope: SyncEncryptedEnvelope, session: AccountSession) -> Bool {
        if let current = values[session.accountID] { return current == envelope }
        values[session.accountID] = envelope
        return true
    }
}

private actor PasswordVaultEnvelopes: PasswordEnvelopeStoring {
    private var values: [UUID: PasswordKeyEnvelope] = [:]
    private var fail = false
    func failNextSave() { fail = true }
    func load(session: AccountSession) -> PasswordKeyEnvelope? { values[session.accountID] }
    func replace(_ envelope: PasswordKeyEnvelope, expected: PasswordKeyEnvelope,
                 claimKey: Data, session: AccountSession) async throws -> Bool {
        guard claimKey.count == 32, values[session.accountID] == expected else { return false }
        values[session.accountID] = envelope
        return true
    }
    func saveIfAbsent(_ envelope: PasswordKeyEnvelope, session: AccountSession) throws -> Bool {
        if fail { fail = false; throw SyncError.unavailable }
        if let current = values[session.accountID] { return current == envelope }
        values[session.accountID] = envelope
        return true
    }
}

private struct PasswordVaultSessions: AccountSessionStoring {
    let value: AccountSession
    func load() async -> AccountSession? { value }
    func save(_ session: AccountSession) async {}
    func clear() async {}
}
