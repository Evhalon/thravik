import Foundation

public protocol BookmarkSyncing: Sendable {
    func synchronize() async throws -> Bool
}
