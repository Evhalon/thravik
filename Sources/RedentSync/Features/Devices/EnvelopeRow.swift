import Foundation
import RedentKit

struct EnvelopeRow: Decodable {
    let senderDeviceID: UUID
    let recipientDeviceID: UUID
    let requestID: UUID
    let expiresAt: Int64
    let keyEpoch: UInt64
    let nonce: String
    let ciphertext: String
    let authenticationTag: String
    let signature: String

    enum CodingKeys: String, CodingKey {
        case senderDeviceID = "sender_device_id", recipientDeviceID = "recipient_device_id"
        case requestID = "request_id", expiresAt = "expires_at", keyEpoch = "key_epoch"
        case nonce, ciphertext, authenticationTag = "authentication_tag", signature
    }

    func approval() throws -> SyncDeviceApproval {
        guard let nonceData = Data(base64Encoded: nonce), nonceData.count == 12,
              let cipher = Data(base64Encoded: ciphertext), cipher.count == 32,
              let tag = Data(base64Encoded: authenticationTag), tag.count == 16,
              let signatureData = Data(base64Encoded: signature), signatureData.count == 64 else {
            throw SyncError.invalidResponse
        }
        return SyncDeviceApproval(senderDeviceID: senderDeviceID, recipientDeviceID: recipientDeviceID,
                                  requestID: requestID, expiresAt: Date(timeIntervalSince1970: TimeInterval(expiresAt)),
                                  keyEpoch: keyEpoch, nonce: nonceData, ciphertext: cipher,
                                  authenticationTag: tag, signature: signatureData)
    }
}
