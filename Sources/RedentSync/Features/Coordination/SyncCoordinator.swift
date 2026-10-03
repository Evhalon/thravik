import Foundation
import RedentKit

/// Explicitly event-driven: foreground/reconnect callers trigger bounded work.
public actor SyncCoordinator {
    private let transport: any SyncTransporting
    private let local: any AuthenticatedSyncStoring
    private var running = false

    public init(transport: any SyncTransporting, local: any AuthenticatedSyncStoring) {
        self.transport = transport
        self.local = local
    }

    public func synchronize(session: AccountSession) async throws -> SyncRunResult {
        guard !running else { throw SyncError.alreadyRunning }
        running = true
        defer { running = false }
        try Task.checkCancellation()
        let cursor = try await local.cursor(accountID: session.accountID)
        let page = try await transport.pull(after: cursor, session: session)
        try Task.checkCancellation()
        try SyncPageValidation.validate(page, accountID: session.accountID, after: cursor)
        try await local.apply(page, accountID: session.accountID)
        let uploaded = page.hasMore ? 0 : try await upload(session: session)
        let remaining = try await local.pending(accountID: session.accountID, limit: 1)
        return SyncRunResult(uploaded: uploaded, downloaded: page.records.count,
                             hasMore: page.hasMore || !remaining.isEmpty)
    }

    private func upload(session: AccountSession) async throws -> Int {
        let pending = try await local.pending(accountID: session.accountID, limit: 100)
        for mutation in pending {
            try Task.checkCancellation()
            guard mutation.identity.accountID == session.accountID else { throw SyncError.accountMismatch }
            let accepted = try await transport.push(mutation, session: session)
            guard accepted.mutation == mutation, accepted.revision == mutation.expectedRevision + 1,
                  accepted.cursor > 0 else { throw SyncError.invalidResponse }
            try Task.checkCancellation()
            try await local.acknowledge(accepted)
        }
        return pending.count
    }
}
