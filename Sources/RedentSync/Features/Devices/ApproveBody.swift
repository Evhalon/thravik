import Foundation
import RedentKit

struct ApproveBody: Encodable {
    let approval: SyncDeviceApproval
    let credential: Data

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        var request = container.nestedContainer(keyedBy: Key.self, forKey: .request)
        try request.encode(approval.senderDeviceID, forKey: .approverDeviceID)
        try request.encode(credential.base64EncodedString(), forKey: .approverCredential)
        try request.encode(approval.senderDeviceID, forKey: .senderDeviceID)
        try request.encode(approval.recipientDeviceID, forKey: .recipientDeviceID)
        try request.encode(approval.requestID, forKey: .requestID)
        try request.encode(Int64(approval.expiresAt.timeIntervalSince1970.rounded(.down)), forKey: .expiresAt)
        try request.encode(approval.keyEpoch, forKey: .keyEpoch)
        try request.encode(approval.nonce.base64EncodedString(), forKey: .nonce)
        try request.encode(approval.ciphertext.base64EncodedString(), forKey: .ciphertext)
        try request.encode(approval.authenticationTag.base64EncodedString(), forKey: .authenticationTag)
        try request.encode(approval.signature.base64EncodedString(), forKey: .signature)
    }

    private enum Key: String, CodingKey {
        case request
        case approverDeviceID = "approver_device_id"
        case approverCredential = "approver_credential"
        case senderDeviceID = "sender_device_id"
        case recipientDeviceID = "recipient_device_id"
        case requestID = "request_id"
        case expiresAt = "expires_at"
        case keyEpoch = "key_epoch"
        case nonce, ciphertext
        case authenticationTag = "authentication_tag"
        case signature
    }
}
