import CryptoKit
import Foundation
import RedentKit

enum SyncDeviceCanonical {
    static func wrapInfo(accountID: UUID, senderID: UUID, recipientID: UUID, requestID: UUID,
                         expiresAt: Int64, keyEpoch: UInt64) -> Data {
        var data = Data("redent.sync.device.wrap.v1".utf8)
        data.append(UInt16(1).syncBigEndianData)
        data.append(bytes(accountID))
        data.append(bytes(senderID))
        data.append(bytes(recipientID))
        data.append(bytes(requestID))
        data.append(expiresAt.syncBigEndianData)
        data.append(keyEpoch.syncBigEndianData)
        return data
    }

    static func approvalMessage(info: Data, nonce: Data, ciphertext: Data, tag: Data) -> Data {
        var data = Data("redent.sync.device.approve.v1".utf8)
        data.append(info)
        data.append(Data(SHA256.hash(data: nonce + ciphertext + tag)))
        return data
    }

    static func mutation(_ mutation: SyncMutation, deviceID: UUID) -> Data {
        var data = Data("redent.sync.mutation.v1".utf8)
        data.append(UInt16(1).syncBigEndianData)
        data.append(bytes(mutation.identity.accountID))
        data.append(bytes(deviceID))
        data.append(bytes(mutation.id))
        data.append(bytes(mutation.identity.recordID))
        let collection = Data(mutation.identity.collection.utf8)
        data.append(UInt32(collection.count).syncBigEndianData)
        data.append(collection)
        data.append(mutation.expectedRevision.syncBigEndianData)
        data.append(mutation.isDeleted ? 1 : 0)
        data.append(Data(SHA256.hash(data: mutation.encryptedPayload)))
        return data
    }

    private static func bytes(_ id: UUID) -> Data {
        let u = id.uuid
        return Data([u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7, u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15])
    }
}

private extension FixedWidthInteger {
    var syncBigEndianData: Data {
        var value = bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}
