import Foundation

struct ClaimKeyBody: Encodable {
    let claimKey: String

    enum CodingKeys: String, CodingKey { case claimKey = "claim_key" }

    init(claimKey: Data) { self.claimKey = claimKey.base64EncodedString() }
}
