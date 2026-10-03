import Foundation

public struct RecoveryKeyBundle: Sendable, Equatable {
    public let recoveryCode: String
    public let wrappedRootKey: SyncEncryptedEnvelope

    public init(recoveryCode: String, wrappedRootKey: SyncEncryptedEnvelope) {
        self.recoveryCode = recoveryCode
        self.wrappedRootKey = wrappedRootKey
    }
}
