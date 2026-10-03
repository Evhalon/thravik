import Foundation

public struct SyncPage: Sendable, Equatable {
    public let records: [SyncRemoteRecord]
    public let nextCursor: Int64
    public let hasMore: Bool

    public init(records: [SyncRemoteRecord], nextCursor: Int64, hasMore: Bool) {
        self.records = records
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}
