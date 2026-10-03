import Foundation
import RedentKit

public actor WorkspaceSyncStore: WorkspaceSyncing {
    private let accountID: UUID
    private let dependencies: WorkspaceSyncDependencies
    private let publisher: WorkspaceSyncPublisher
    private var busy = false

    public init(accountID: UUID, dependencies: WorkspaceSyncDependencies) {
        self.accountID = accountID
        self.dependencies = dependencies
        publisher = WorkspaceSyncPublisher(accountID: accountID, replica: dependencies.replica)
    }

    public func publish(_ session: BrowserSession) async throws {
        try begin()
        defer { busy = false }
        var context = try await unlocked()
        defer { context.key.resetBytes(in: 0..<context.key.count) }
        try await publisher.publish(session, deviceID: context.deviceID, rootKey: context.key)
    }

    public func synchronize() async throws -> (WorkspaceSyncSnapshot, Bool) {
        try begin()
        defer { busy = false }
        var context = try await unlocked()
        defer { context.key.resetBytes(in: 0..<context.key.count) }
        let page = try await pull(session: context.session)
        if !page.hasMore { try await upload(session: context.session) }
        let snapshot = try await projected(deviceID: context.deviceID, rootKey: context.key)
        let remaining = try await dependencies.replica.pending(accountID: accountID, limit: 100)
            .contains { $0.identity.collection == "workspace" || $0.identity.collection == "device_tabs" }
        return (snapshot, page.hasMore || remaining)
    }

    private func projected(deviceID: UUID, rootKey: Data) async throws -> WorkspaceSyncSnapshot {
        let snapshot = try await WorkspaceSyncReader(accountID: accountID)
            .snapshot(from: dependencies.replica, deviceID: deviceID, rootKey: rootKey)
        if let catalog = snapshot.catalog { await publisher.absorb(catalog) }
        return snapshot
    }

    private func pull(session: AccountSession) async throws -> SyncPage {
        let cursor = try await dependencies.replica.cursor(accountID: accountID)
        let page = try await dependencies.transport.pull(after: cursor, session: session)
        try Task.checkCancellation()
        try SyncPageValidation.validate(page, accountID: accountID, after: cursor)
        try await dependencies.replica.apply(page, accountID: accountID)
        return page
    }

    private func upload(session: AccountSession) async throws {
        try await WorkspaceSyncUploader(accountID: accountID, replica: dependencies.replica,
                                        transport: dependencies.transport).upload(session: session)
    }

    private func unlocked() async throws -> Unlocked {
        guard let session = try await dependencies.sessions.load(), session.accountID == accountID,
              session.expiresAt > Date() else { throw SyncError.unauthorized }
        guard var key = try await dependencies.keys.load(accountID: accountID) else { throw SyncError.unauthorized }
        guard let secrets = try await dependencies.deviceKeys.load(accountID: accountID) else {
            key.resetBytes(in: 0..<key.count)
            throw SyncError.unauthorized
        }
        return Unlocked(key: key, deviceID: secrets.deviceID, session: session)
    }

    private func begin() throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
    }

    private struct Unlocked {
        var key: Data
        let deviceID: UUID
        let session: AccountSession
    }
}
