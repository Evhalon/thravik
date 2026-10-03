import CryptoKit
import Foundation
import RedentKit

public struct SyncDeviceRootKeyWrap: Sendable {
    public struct Request: Sendable {
        public let accountID: UUID
        public let rootKey: Data
        public let sender: SyncDeviceSecrets
        public let recipient: SyncDevicePublicIdentity
        public let requestID: UUID
        public let expiresAt: Date
        public let keyEpoch: UInt64

        public init(accountID: UUID, rootKey: Data, sender: SyncDeviceSecrets, recipient: SyncDevicePublicIdentity,
                    requestID: UUID, expiresAt: Date, keyEpoch: UInt64) {
            self.accountID = accountID
            self.rootKey = rootKey
            self.sender = sender
            self.recipient = recipient
            self.requestID = requestID
            self.expiresAt = expiresAt
            self.keyEpoch = keyEpoch
        }
    }

    public init() {}

    public func seal(_ request: Request) throws -> SyncDeviceApproval {
        guard request.rootKey.count == 32, request.keyEpoch > 0 else { throw SyncCryptoError.invalidKeyLength }
        let sender = try SyncDeviceCryptography().identity(from: request.sender)
        let expiry = try Self.expiry(request.expiresAt, now: Date())
        let info = Self.info(request, senderID: sender.id, expiry: expiry)
        let sealed = try Self.box(request.rootKey, privateKey: request.sender.agreementPrivateKey,
                                  publicKey: request.recipient.agreementPublicKey, info: info)
        let signature = try SyncDeviceSigner().signApproval(info: info, nonce: Data(sealed.nonce),
                                                            ciphertext: sealed.ciphertext, tag: sealed.tag,
                                                            secrets: request.sender)
        return SyncDeviceApproval(senderDeviceID: sender.id, recipientDeviceID: request.recipient.id,
                                  requestID: request.requestID,
                                  expiresAt: Date(timeIntervalSince1970: TimeInterval(expiry)),
                                  keyEpoch: request.keyEpoch, nonce: Data(sealed.nonce),
                                  ciphertext: sealed.ciphertext, authenticationTag: sealed.tag, signature: signature)
    }

    public func open(_ approval: SyncDeviceApproval, accountID: UUID, recipient: SyncDeviceSecrets,
                     sender: SyncDevicePublicIdentity, now: Date) throws -> Data {
        guard approval.recipientDeviceID == recipient.deviceID, approval.keyEpoch > 0 else {
            throw SyncCryptoError.invalidContext
        }
        let expiry = try Self.expiry(approval.expiresAt, now: now)
        let info = SyncDeviceCanonical.wrapInfo(accountID: accountID, senderID: sender.id,
                                                recipientID: approval.recipientDeviceID,
                                                requestID: approval.requestID, expiresAt: expiry,
                                                keyEpoch: approval.keyEpoch)
        guard SyncDeviceSigner().isValidApproval(info: info, approval: approval,
                                                 publicKey: sender.signingPublicKey) else {
            throw SyncCryptoError.authenticationFailed
        }
        return try Self.openBox(approval, privateKey: recipient.agreementPrivateKey,
                                publicKey: sender.agreementPublicKey, info: info)
    }

    private static func expiry(_ date: Date, now: Date) throws -> Int64 {
        let expiry = Int64(date.timeIntervalSince1970.rounded(.down))
        guard TimeInterval(expiry) > now.timeIntervalSince1970 else { throw SyncCryptoError.expired }
        return expiry
    }

    private static func info(_ request: Request, senderID: UUID, expiry: Int64) -> Data {
        SyncDeviceCanonical.wrapInfo(accountID: request.accountID, senderID: senderID,
                                     recipientID: request.recipient.id, requestID: request.requestID,
                                     expiresAt: expiry, keyEpoch: request.keyEpoch)
    }

    private static func box(_ plaintext: Data, privateKey: Data, publicKey: Data, info: Data) throws -> AES.GCM.SealedBox {
        try AES.GCM.seal(plaintext, using: try sharedKey(privateKey: privateKey, publicKey: publicKey, info: info),
                         authenticating: info)
    }

    private static func openBox(_ approval: SyncDeviceApproval, privateKey: Data, publicKey: Data, info: Data) throws -> Data {
        do {
            let key = try sharedKey(privateKey: privateKey, publicKey: publicKey, info: info)
            let sealed = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: approval.nonce),
                                               ciphertext: approval.ciphertext, tag: approval.authenticationTag)
            return try AES.GCM.open(sealed, using: key, authenticating: info)
        } catch SyncCryptoError.invalidKeyLength { throw SyncCryptoError.invalidKeyLength }
        catch { throw SyncCryptoError.authenticationFailed }
    }

    private static func sharedKey(privateKey: Data, publicKey: Data, info: Data) throws -> SymmetricKey {
        guard let local = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey),
              let remote = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey) else {
            throw SyncCryptoError.invalidKeyLength
        }
        let shared = try local.sharedSecretFromKeyAgreement(with: remote)
        return shared.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data("redent.sync.device.hkdf.v1".utf8),
                                              sharedInfo: info, outputByteCount: 32)
    }
}
