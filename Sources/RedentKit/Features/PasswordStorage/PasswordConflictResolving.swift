import Foundation

public protocol PasswordConflictResolving: Sendable {
    func conflicts() async throws -> [PasswordConflict]
    func resolveConflict(id: UUID, keepingLocal: Bool) async throws
}
