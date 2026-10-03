import Foundation

public struct SyncDeviceProof: Sendable, Equatable {
    public let deviceID: UUID
    public let credential: Data
    public let signature: Data

    public init(deviceID: UUID, credential: Data, signature: Data) {
        self.deviceID = deviceID
        self.credential = credential
        self.signature = signature
    }
}
