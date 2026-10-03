import CryptoKit
import Foundation
import RedentKit

public struct SyncDeviceCryptography: Sendable {
    public init() {}

    public func generate(deviceID: UUID = UUID()) -> SyncDeviceSecrets {
        let agreement = Curve25519.KeyAgreement.PrivateKey()
        let signing = Curve25519.Signing.PrivateKey()
        let credential = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        return SyncDeviceSecrets(deviceID: deviceID, agreementPrivateKey: agreement.rawRepresentation,
                                 signingPrivateKey: signing.rawRepresentation, credential: credential)
    }

    public func identity(from secrets: SyncDeviceSecrets) throws -> SyncDevicePublicIdentity {
        guard secrets.credential.count == 32,
              let agreement = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: secrets.agreementPrivateKey),
              let signing = try? Curve25519.Signing.PrivateKey(rawRepresentation: secrets.signingPrivateKey)
        else { throw SyncCryptoError.invalidKeyLength }
        return SyncDevicePublicIdentity(id: secrets.deviceID,
                                        agreementPublicKey: agreement.publicKey.rawRepresentation,
                                        signingPublicKey: signing.publicKey.rawRepresentation)
    }

    public func fingerprint(agreement: Data, signing: Data) throws -> String {
        guard agreement.count == 32, signing.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        let hex = SHA256.hash(data: agreement + signing).prefix(16).map { String(format: "%02X", $0) }.joined()
        return stride(from: 0, to: hex.count, by: 4).map { offset in
            let start = hex.index(hex.startIndex, offsetBy: offset)
            return String(hex[start..<hex.index(start, offsetBy: 4)])
        }.joined(separator: "-")
    }
}
