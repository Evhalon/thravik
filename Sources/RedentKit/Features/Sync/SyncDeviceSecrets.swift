import Foundation

public struct SyncDeviceSecrets: Sendable, Equatable {
    public let deviceID: UUID
    public let agreementPrivateKey: Data
    public let signingPrivateKey: Data
    public let credential: Data

    public init(deviceID: UUID, agreementPrivateKey: Data, signingPrivateKey: Data, credential: Data) {
        self.deviceID = deviceID
        self.agreementPrivateKey = agreementPrivateKey
        self.signingPrivateKey = signingPrivateKey
        self.credential = credential
    }
}
