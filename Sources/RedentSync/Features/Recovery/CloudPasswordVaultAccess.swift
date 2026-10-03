import Foundation
import RedentKit

public actor CloudPasswordVaultAccess: PasswordVaultAccessing {
    private struct Pending {
        let accountID: UUID
        let envelope: PasswordKeyEnvelope
        var activated = false
    }

    private let underlying: CloudVaultAccess
    private let sessions: any AccountSessionStoring
    private let envelopes: any PasswordEnvelopeStoring
    private let recovery: any RecoveryEnvelopeStoring
    private var pending: Pending?
    private var busy = false
    private let crypto = SyncPasswordCryptography()

    public init(underlying: CloudVaultAccess, sessions: any AccountSessionStoring,
                envelopes: any PasswordEnvelopeStoring, recovery: any RecoveryEnvelopeStoring) {
        self.underlying = underlying
        self.sessions = sessions
        self.envelopes = envelopes
        self.recovery = recovery
    }

    public func status() async throws -> PasswordVaultState { try await underlying.status() }
    public func prepareVault() async throws -> String { try await underlying.prepareVault() }
    public func recover(code: String) async throws {
        do { try await underlying.recover(code: code) }
        catch SyncCryptoError.invalidRecoveryCode { throw PasswordStorageError.invalidRecoveryCode }
        catch SyncCryptoError.authenticationFailed { throw PasswordStorageError.invalidRecoveryCode }
    }

    public func passwordConfigured() async throws -> Bool {
        let session = try await session()
        let configured = try await envelopes.load(session: session) != nil
        try await validate(session.accountID)
        return configured
    }

    public func prepareVault(password: String) async throws -> String {
        try begin()
        defer { busy = false }
        let session = try await session()
        guard try await envelopes.load(session: session) == nil else { throw SyncError.revisionConflict }
        let code = try await underlying.prepareVault()
        let envelope = try wrap(code: code, password: password, accountID: session.accountID)
        try await validate(session.accountID)
        pending = Pending(accountID: session.accountID, envelope: envelope)
        return code
    }

    public func activateVault() async throws {
        try begin()
        defer { busy = false }
        let session = try await session()
        guard var pending, pending.accountID == session.accountID else { throw SyncError.accountMismatch }
        if !pending.activated {
            try await underlying.activateVault()
            pending.activated = true
            self.pending = pending
        }
        guard try await envelopes.saveIfAbsent(pending.envelope, session: session) else {
            throw SyncError.revisionConflict
        }
        try await validate(session.accountID)
        self.pending = nil
    }

    public func unlock(password: String) async throws -> String {
        try begin()
        defer { busy = false }
        let session = try await session()
        guard let envelope = try await envelopes.load(session: session) else { throw SyncError.invalidResponse }
        let code: String
        do { code = try crypto.unwrap(envelope: envelope, password: password, accountID: session.accountID) }
        catch SyncPasswordCryptographyError.authenticationFailed { throw PasswordStorageError.invalidSyncPassword }
        catch SyncPasswordCryptographyError.invalidPassword { throw PasswordStorageError.weakSyncPassword }
        try await validate(session.accountID)
        try await underlying.recover(code: code)
        try await validate(session.accountID)
        return code
    }

    public func enablePassword(password: String, recoveryCode: String) async throws {
        try begin()
        defer { busy = false }
        let session = try await session()
        let existing = try await envelopes.load(session: session)
        guard let recoveryEnvelope = try await recovery.load(session: session) else { throw SyncError.invalidResponse }
        var root: Data
        do {
            root = try SyncRecoveryCryptography().recoverRootKey(
                code: recoveryCode, accountID: session.accountID, envelope: recoveryEnvelope)
        } catch { throw PasswordStorageError.invalidRecoveryCode }
        defer { root.resetBytes(in: 0..<root.count) }
        let envelope = try wrap(code: recoveryCode, password: password, accountID: session.accountID)
        try await validate(session.accountID)
        let accepted: Bool
        if let existing {
            let claimKey = try SyncRecoveryCryptography().claimKey(code: recoveryCode, accountID: session.accountID)
            accepted = try await envelopes.replace(envelope, expected: existing, claimKey: claimKey, session: session)
        } else {
            accepted = try await envelopes.saveIfAbsent(envelope, session: session)
        }
        guard accepted else { throw SyncError.revisionConflict }
        try await validate(session.accountID)
    }

    private func begin() throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
    }

    private func wrap(code: String, password: String, accountID: UUID) throws -> PasswordKeyEnvelope {
        do { return try crypto.wrap(recoveryCode: code, password: password, accountID: accountID) }
        catch SyncPasswordCryptographyError.invalidPassword { throw PasswordStorageError.weakSyncPassword }
    }

    private func session() async throws -> AccountSession {
        guard let session = try await sessions.load(), session.expiresAt > Date() else { throw SyncError.unauthorized }
        return session
    }

    private func validate(_ accountID: UUID) async throws {
        guard try await session().accountID == accountID else { throw SyncError.accountMismatch }
    }
}
