import Foundation
import RedentKit

/// The raw replica never advances past unauthenticated ciphertext.
public actor AuthenticatedSyncLocalStore: AuthenticatedSyncStoring {
    private let underlying: any SyncLocalStoring
    private let cipher: any SyncMutationCiphering
    private let keys: any SyncKeyStoring

    public init(underlying: any SyncLocalStoring, cipher: any SyncMutationCiphering, keys: any SyncKeyStoring) {
        self.underlying = underlying
        self.cipher = cipher
        self.keys = keys
    }

    public func enqueue(_ mutation: SyncMutation) async throws {
        try await authenticate([mutation], accountID: mutation.identity.accountID)
        try await underlying.enqueue(mutation)
    }

    public func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) async throws {
        try await authenticate([mutation], accountID: mutation.identity.accountID)
        if let replacement {
            guard replacement.identity == mutation.identity else { throw SyncError.accountMismatch }
            try await authenticate([replacement], accountID: mutation.identity.accountID)
        }
        try await underlying.replacePending(mutation, with: replacement)
    }

    public func pending(accountID: UUID, limit: Int) async throws -> [SyncMutation] {
        let pending = try await underlying.pending(accountID: accountID, limit: limit)
        try await authenticate(pending, accountID: accountID)
        return pending
    }

    public func acknowledge(_ record: SyncRemoteRecord) async throws {
        try await authenticate([record.mutation], accountID: record.mutation.identity.accountID)
        try await underlying.acknowledge(record)
    }

    public func cursor(accountID: UUID) async throws -> Int64 {
        try await underlying.cursor(accountID: accountID)
    }

    public func apply(_ page: SyncPage, accountID: UUID) async throws {
        try await authenticate(page.records.map(\.mutation), accountID: accountID)
        try await underlying.apply(page, accountID: accountID)
    }

    public func records(accountID: UUID) async throws -> [SyncRemoteRecord] {
        let records = try await underlying.records(accountID: accountID)
        try await authenticate(records.map(\.mutation), accountID: accountID)
        return records
    }

    private func authenticate(_ mutations: [SyncMutation], accountID: UUID) async throws {
        guard !mutations.isEmpty else { return }
        guard var key = try await keys.load(accountID: accountID) else { throw SyncError.unauthorized }
        defer { key.resetBytes(in: 0..<key.count) }
        for mutation in mutations {
            guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
            var plaintext = try cipher.decrypt(mutation, rootKey: key)
            plaintext.resetBytes(in: 0..<plaintext.count)
        }
    }
}
