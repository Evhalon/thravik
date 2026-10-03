import Foundation

public enum SyncPasswordCryptographyError: Error, Equatable {
    case invalidPassword
    case invalidEnvelope
    case derivationFailed
    case authenticationFailed
}
