import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct SyncDeviceCryptographyTests {
    @Test func approvalRoundTripRejectsTamperingAndExpiry() throws {
        let crypto = SyncDeviceCryptography()
        let sender = crypto.generate()
        let recipient = crypto.generate()
        let senderIdentity = try crypto.identity(from: sender)
        let recipientIdentity = try crypto.identity(from: recipient)
        let root = Data(repeating: 7, count: 32)
        let expiry = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down) + 900)
        let request = SyncDeviceRootKeyWrap.Request(accountID: UUID(), rootKey: root, sender: sender,
                                                    recipient: recipientIdentity, requestID: UUID(),
                                                    expiresAt: expiry, keyEpoch: 1)
        let approval = try SyncDeviceRootKeyWrap().seal(request)
        let opened = try SyncDeviceRootKeyWrap().open(approval, accountID: request.accountID, recipient: recipient,
                                                      sender: senderIdentity, now: Date())
        #expect(opened == root)
        let tampered = SyncDeviceApproval(senderDeviceID: approval.senderDeviceID,
                                          recipientDeviceID: approval.recipientDeviceID, requestID: approval.requestID,
                                          expiresAt: approval.expiresAt, keyEpoch: approval.keyEpoch, nonce: approval.nonce,
                                          ciphertext: Data(repeating: 1, count: 32), authenticationTag: approval.authenticationTag,
                                          signature: approval.signature)
        #expect(throws: SyncCryptoError.self) {
            try SyncDeviceRootKeyWrap().open(tampered, accountID: request.accountID, recipient: recipient,
                                             sender: senderIdentity, now: Date())
        }
        #expect(throws: SyncCryptoError.expired) {
            try SyncDeviceRootKeyWrap().open(approval, accountID: request.accountID, recipient: recipient,
                                             sender: senderIdentity, now: expiry.addingTimeInterval(1))
        }
    }

    @Test func mutationSignatureIsBoundToDevice() throws {
        let crypto = SyncDeviceCryptography()
        let device = crypto.generate()
        let identity = try crypto.identity(from: device)
        let record = SyncDeviceRecord(id: identity.id, agreementPublicKey: identity.agreementPublicKey,
                                      signingPublicKey: identity.signingPublicKey, status: .approved, expiresAt: nil)
        let mutation = SyncMutation(identity: SyncRecordIdentity(accountID: UUID(), collection: "credentials",
                                                                  recordID: UUID()), expectedRevision: 0,
                                     encryptedPayload: Data(repeating: 4, count: 40))
        let proof = try SyncDeviceSigner().proof(for: mutation, secrets: device)
        #expect(SyncDeviceSigner().isValid(mutation, signature: proof.signature, device: record))
        let other = crypto.generate()
        let otherIdentity = try crypto.identity(from: other)
        let otherRecord = SyncDeviceRecord(id: otherIdentity.id, agreementPublicKey: otherIdentity.agreementPublicKey,
                                           signingPublicKey: otherIdentity.signingPublicKey, status: .approved,
                                           expiresAt: nil)
        #expect(!SyncDeviceSigner().isValid(mutation, signature: proof.signature, device: otherRecord))
    }

    @Test func fingerprintAndClaimKeyStayInTheirDomains() throws {
        let crypto = SyncDeviceCryptography()
        let secrets = crypto.generate()
        let identity = try crypto.identity(from: secrets)
        let fingerprint = try crypto.fingerprint(agreement: identity.agreementPublicKey, signing: identity.signingPublicKey)
        #expect(try crypto.fingerprint(agreement: identity.agreementPublicKey, signing: identity.signingPublicKey) == fingerprint)
        #expect(fingerprint.split(separator: "-").count == 8)
        let recovery = SyncRecoveryCryptography()
        let account = UUID()
        let bundle = try recovery.createBundle(rootKey: Data(repeating: 3, count: 32), accountID: account)
        let claim = try recovery.claimKey(code: bundle.recoveryCode, accountID: account)
        #expect(claim.count == 32)
        #expect(try recovery.claimKey(code: bundle.recoveryCode, accountID: UUID()) != claim)
    }
}
