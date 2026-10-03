import CryptoKit
import Foundation
import RedentKit

public struct SyncDeviceSigner: Sendable {
    public init() {}

    public func proof(for mutation: SyncMutation, secrets: SyncDeviceSecrets) throws -> SyncDeviceProof {
        let signature = try sign(SyncDeviceCanonical.mutation(mutation, deviceID: secrets.deviceID),
                                 privateKey: secrets.signingPrivateKey)
        return SyncDeviceProof(deviceID: secrets.deviceID, credential: secrets.credential, signature: signature)
    }

    public func isValid(_ mutation: SyncMutation, signature: Data, device: SyncDeviceRecord) -> Bool {
        isValid(signature, message: SyncDeviceCanonical.mutation(mutation, deviceID: device.id),
                publicKey: device.signingPublicKey)
    }

    func signApproval(info: Data, nonce: Data, ciphertext: Data, tag: Data, secrets: SyncDeviceSecrets) throws -> Data {
        try sign(SyncDeviceCanonical.approvalMessage(info: info, nonce: nonce, ciphertext: ciphertext, tag: tag),
                 privateKey: secrets.signingPrivateKey)
    }

    func isValidApproval(info: Data, approval: SyncDeviceApproval, publicKey: Data) -> Bool {
        isValid(approval.signature, message: SyncDeviceCanonical.approvalMessage(
            info: info, nonce: approval.nonce, ciphertext: approval.ciphertext, tag: approval.authenticationTag),
                publicKey: publicKey)
    }

    private func sign(_ message: Data, privateKey: Data) throws -> Data {
        guard let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: privateKey) else {
            throw SyncCryptoError.invalidKeyLength
        }
        return try key.signature(for: message)
    }

    private func isValid(_ signature: Data, message: Data, publicKey: Data) -> Bool {
        guard signature.count == 64, let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
        else { return false }
        return key.isValidSignature(signature, for: message)
    }
}
