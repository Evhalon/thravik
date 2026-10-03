import Foundation
import RedentKit

struct EnvelopeQuery: Encodable {
    let deviceID: UUID
    let credential: String

    enum CodingKeys: String, CodingKey { case deviceID = "device_id", credential }

    init(deviceID: UUID, credential: Data) {
        self.deviceID = deviceID
        self.credential = credential.base64EncodedString()
    }
}
