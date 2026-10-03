import Foundation

/// Applying a pulled page and advancing its cursor must be one durable commit.
public protocol SyncLocalStoring: Sendable {
    func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) async throws
    func enqueue(_ mutation: SyncMutation) async throws
    func pending(accountID: UUID, limit: Int) async throws -> [SyncMutation]
    func acknowledge(_ record: SyncRemoteRecord) async throws
    func cursor(accountID: UUID) async throws -> Int64
    func apply(_ page: SyncPage, accountID: UUID) async throws
    func records(accountID: UUID) async throws -> [SyncRemoteRecord]
}

extension SyncLocalStoring {
    public func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) async throws {
        throw SyncError.unavailable
    }
}
