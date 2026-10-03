import Foundation

public struct SyncRemoteRecord: Codable, Sendable, Equatable {
    public let mutation: SyncMutation
    public let revision: Int64
    public let cursor: Int64
    public let signerDeviceID: UUID?
    public let signature: Data?

    public init(mutation: SyncMutation, revision: Int64, cursor: Int64,
                signerDeviceID: UUID? = nil, signature: Data? = nil) {
        self.mutation = mutation
        self.revision = revision
        self.cursor = cursor
        self.signerDeviceID = signerDeviceID
        self.signature = signature
    }
}
