import Foundation

public protocol WorkspaceSyncing: AnyObject, Sendable {
    func publish(_ session: BrowserSession) async throws
    func synchronize() async throws -> (WorkspaceSyncSnapshot, Bool)
}
