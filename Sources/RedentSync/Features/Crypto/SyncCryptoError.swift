public enum SyncCryptoError: Error, Equatable {
    case invalidKeyLength
    case unsupportedProtocolVersion
    case invalidRecoveryCode
    case authenticationFailed
    case invalidContext
    case expired
}
