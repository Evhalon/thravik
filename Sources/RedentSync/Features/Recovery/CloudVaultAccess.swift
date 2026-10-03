import CryptoKit
import Foundation
import RedentKit

public actor CloudVaultAccess: PasswordVaultAccessing {
    public struct Configuration: Sendable {
        let keys: any SyncKeyStoring
        let sessions: any AccountSessionStoring
        let envelopes: any RecoveryEnvelopeStoring
        let claims: (any RecoveryClaimPublishing)?

        public init(keys: any SyncKeyStoring, sessions: any AccountSessionStoring,
                    envelopes: any RecoveryEnvelopeStoring, claims: (any RecoveryClaimPublishing)? = nil) {
            self.keys = keys
            self.sessions = sessions
            self.envelopes = envelopes
            self.claims = claims
        }
    }

    private struct Pending {
        let accountID: UUID
        let root: Data
        let bundle: RecoveryKeyBundle
    }

    private let configuration: Configuration
    private var pending: Pending?
    private var busy = false
    private let crypto = SyncRecoveryCryptography()

    public init(configuration: Configuration) { self.configuration = configuration }

    public func status() async throws -> CloudVaultStatus {
        guard let cached = try await configuration.sessions.load() else { throw SyncError.unauthorized }
        if var key = try await configuration.keys.load(accountID: cached.accountID) {
            defer { key.resetBytes(in: 0..<key.count) }
            guard key.count == 32 else { throw SyncCryptoError.invalidKeyLength }
            guard try await configuration.sessions.load()?.accountID == cached.accountID
            else { throw SyncError.accountMismatch }
            return .ready
        }
        let session = try await session()
        let key = try await configuration.keys.load(accountID: session.accountID)
        let envelope = try await configuration.envelopes.load(session: session)
        try await validateAccount(session.accountID)
        guard envelope != nil else { return .needsCreation }
        guard let key else { return .needsRecovery }
        guard key.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        return .ready
    }

    public func prepareVault() async throws -> String {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
        defer { busy = false }
        let session = try await session()
        if let pending, pending.accountID == session.accountID { return pending.bundle.recoveryCode }
        pending = nil
        guard try await configuration.envelopes.load(session: session) == nil else {
            throw SyncError.revisionConflict
        }
        let existing = try await configuration.keys.load(accountID: session.accountID)
        let root = existing ?? SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let bundle = try crypto.createBundle(rootKey: root, accountID: session.accountID)
        try await validateAccount(session.accountID)
        pending = Pending(accountID: session.accountID, root: root, bundle: bundle)
        return bundle.recoveryCode
    }

    public func activateVault() async throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
        defer { busy = false }
        let session = try await session()
        guard let pending, pending.accountID == session.accountID else { throw SyncError.accountMismatch }
        guard try await configuration.envelopes.saveIfAbsent(pending.bundle.wrappedRootKey,
                                                             session: session) else {
            self.pending = nil
            throw SyncError.revisionConflict
        }
        if let claims = configuration.claims {
            let claimKey = try crypto.claimKey(code: pending.bundle.recoveryCode, accountID: session.accountID)
            try await claims.publish(claimKey: claimKey, session: session)
        }
        try await validateAccount(session.accountID)
        try await configuration.keys.save(pending.root, accountID: session.accountID)
        try await validateAccount(session.accountID)
        self.pending = nil
    }

    public func recover(code: String) async throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
        defer { busy = false }
        let session = try await session()
        guard let envelope = try await configuration.envelopes.load(session: session) else {
            throw SyncError.invalidResponse
        }
        let root = try crypto.recoverRootKey(code: code, accountID: session.accountID, envelope: envelope)
        guard root.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        try await validateAccount(session.accountID)
        try await configuration.keys.save(root, accountID: session.accountID)
        try await validateAccount(session.accountID)
        pending = nil
    }

    private func session() async throws -> AccountSession {
        guard let session = try await configuration.sessions.load(), session.expiresAt > Date() else {
            throw SyncError.unauthorized
        }
        return session
    }

    private func validateAccount(_ accountID: UUID) async throws {
        guard try await session().accountID == accountID else { throw SyncError.accountMismatch }
    }
}
