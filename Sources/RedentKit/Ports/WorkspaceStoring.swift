import Foundation

public protocol WorkspaceStoring: Sendable {
    func loadWorkspace() throws -> WorkspaceSnapshot
    func saveWorkspace(_ workspace: WorkspaceSnapshot) throws
}
