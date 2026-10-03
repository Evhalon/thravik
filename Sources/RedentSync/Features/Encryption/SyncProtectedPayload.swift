import Foundation
import RedentKit

/// Metadata duplicated inside the authenticated ciphertext cannot be changed by the server.
struct SyncProtectedPayload: Codable {
    let mutation: UUID
    let expectedRevision: Int64
    let deleted: Bool
    let value: Data

    func verify(_ request: SyncMutation) throws {
        guard mutation == request.id, expectedRevision == request.expectedRevision,
              deleted == request.isDeleted else { throw SyncCryptoError.authenticationFailed }
    }
}
