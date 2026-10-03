import Foundation

public struct SyncDevicePublicIdentity: Sendable, Equatable, Codable {
    public let id: UUID
    public let agreementPublicKey: Data
    public let signingPublicKey: Data

    public init(id: UUID, agreementPublicKey: Data, signingPublicKey: Data) {
        self.id = id
        self.agreementPublicKey = agreementPublicKey
        self.signingPublicKey = signingPublicKey
    }
}
