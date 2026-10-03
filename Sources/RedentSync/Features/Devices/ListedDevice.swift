import Foundation
import RedentKit

struct ListedDevice: Decodable {
    let deviceID: UUID
    let agreementPublicKey: String
    let signingPublicKey: String
    let status: SyncDeviceStatus
    let expiresAt: Int64?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id", agreementPublicKey = "agreement_public_key"
        case signingPublicKey = "signing_public_key", status, expiresAt = "expires_at"
    }

    func record() throws -> SyncDeviceRecord {
        guard let agreement = Data(base64Encoded: agreementPublicKey), agreement.count == 32,
              let signing = Data(base64Encoded: signingPublicKey), signing.count == 32 else {
            throw SyncError.invalidResponse
        }
        let expiry = expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        return SyncDeviceRecord(id: deviceID, agreementPublicKey: agreement, signingPublicKey: signing,
                                status: status, expiresAt: expiry)
    }
}
