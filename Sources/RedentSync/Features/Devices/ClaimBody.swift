import Foundation

struct ClaimBody: Encodable {
    struct Request: Encodable {
        let deviceID: UUID
        let credential: String
        let claimKey: String

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id", credential, claimKey = "claim_key"
        }
    }

    let request: Request

    init(deviceID: UUID, credential: Data, claimKey: Data) {
        request = Request(deviceID: deviceID, credential: credential.base64EncodedString(),
                          claimKey: claimKey.base64EncodedString())
    }
}
