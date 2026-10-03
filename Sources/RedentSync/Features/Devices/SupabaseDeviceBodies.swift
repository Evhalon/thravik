import Foundation
import RedentKit

struct DeviceBody: Encodable {
    struct Fields: Encodable {
        let deviceID: UUID
        let agreementPublicKey: String
        let signingPublicKey: String
        let credential: String
        let expiresAt: Int64?

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id", agreementPublicKey = "agreement_public_key"
            case signingPublicKey = "signing_public_key", credential, expiresAt = "expires_at"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(deviceID, forKey: .deviceID)
            try container.encode(agreementPublicKey, forKey: .agreementPublicKey)
            try container.encode(signingPublicKey, forKey: .signingPublicKey)
            try container.encode(credential, forKey: .credential)
            try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        }
    }

    let device: Fields

    init(identity: SyncDevicePublicIdentity, credential: Data, expiresAt: Date? = nil) {
        device = Fields(deviceID: identity.id, agreementPublicKey: identity.agreementPublicKey.base64EncodedString(),
                        signingPublicKey: identity.signingPublicKey.base64EncodedString(),
                        credential: credential.base64EncodedString(),
                        expiresAt: expiresAt.map { Int64($0.timeIntervalSince1970.rounded(.down)) })
    }
}
