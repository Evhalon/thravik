import Foundation

public struct SyncRunResult: Sendable, Equatable {
    public let uploaded: Int
    public let downloaded: Int
    public let hasMore: Bool
}
