import Foundation

public struct SyncRecordIdentity: Codable, Sendable, Hashable {
    public let accountID: UUID
    public let collection: String
    public let recordID: UUID

    public init(accountID: UUID, collection: String, recordID: UUID) {
        self.accountID = accountID
        self.collection = collection
        self.recordID = recordID
    }
}
