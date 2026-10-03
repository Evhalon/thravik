import Foundation

struct RevokeBody: Encodable {
    struct Request: Encodable {
        let deviceID: UUID
        let approverDeviceID: UUID
        let approverCredential: String

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id", approverDeviceID = "approver_device_id"
            case approverCredential = "approver_credential"
        }
    }

    let request: Request

    init(deviceID: UUID, approverID: UUID, credential: Data) {
        request = Request(deviceID: deviceID, approverDeviceID: approverID,
                          approverCredential: credential.base64EncodedString())
    }
}
