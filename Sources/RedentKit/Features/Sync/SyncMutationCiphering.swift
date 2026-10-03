import Foundation

public protocol SyncMutationCiphering: Sendable {
    func encrypt(_ request: SyncWriteRequest, rootKey: Data) throws -> SyncMutation
    func decrypt(_ mutation: SyncMutation, rootKey: Data) throws -> Data
}
