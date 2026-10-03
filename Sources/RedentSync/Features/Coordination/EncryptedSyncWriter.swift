import Foundation
import RedentKit

public actor EncryptedSyncWriter {
    private let cipher: any SyncMutationCiphering
    private let keys: any SyncKeyStoring
    private let local: any AuthenticatedSyncStoring

    public init(cipher: any SyncMutationCiphering, keys: any SyncKeyStoring, local: any AuthenticatedSyncStoring) {
        self.cipher = cipher
        self.keys = keys
        self.local = local
    }

    public func enqueue(_ request: SyncWriteRequest) async throws -> SyncMutation {
        guard var key = try await keys.load(accountID: request.identity.accountID)
        else { throw SyncError.unauthorized }
        defer { key.resetBytes(in: 0..<key.count) }
        let mutation = try cipher.encrypt(request, rootKey: key)
        try await local.enqueue(mutation)
        return mutation
    }
}
