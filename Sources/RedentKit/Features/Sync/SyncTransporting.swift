import Foundation

public protocol SyncTransporting: Sendable {
    func push(_ mutation: SyncMutation, session: AccountSession) async throws -> SyncRemoteRecord
    func pull(after cursor: Int64, session: AccountSession) async throws -> SyncPage
}
