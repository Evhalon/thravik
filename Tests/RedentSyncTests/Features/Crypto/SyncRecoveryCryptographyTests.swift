import Foundation
import Testing
@testable import RedentSync

struct SyncRecoveryCryptographyTests {
    @Test func recoveryCodeRestoresWrappedRootKey() throws {
        let recovery = SyncRecoveryCryptography()
        let rootKey = Data((0..<32).map(UInt8.init))
        let accountID = UUID()
        let bundle = try recovery.createBundle(rootKey: rootKey, accountID: accountID)

        #expect(try recovery.recoverRootKey(code: bundle.recoveryCode, accountID: accountID,
                                            envelope: bundle.wrappedRootKey) == rootKey)
        #expect(throws: SyncCryptoError.self) {
            try recovery.recoverRootKey(code: bundle.recoveryCode, accountID: UUID(),
                                        envelope: bundle.wrappedRootKey)
        }
    }

    @Test func rejectsCorruptRecoveryChecksumAndWrappedKey() throws {
        let recovery = SyncRecoveryCryptography()
        let accountID = UUID()
        let bundle = try recovery.createBundle(rootKey: Data(repeating: 9, count: 32), accountID: accountID)
        let codeBytes = Array(bundle.recoveryCode)
        let alteredCode = String(codeBytes.dropLast(1)) + (codeBytes.last == "0" ? "1" : "0")
        let alteredEnvelope = SyncEncryptedEnvelope(protocolVersion: bundle.wrappedRootKey.protocolVersion,
                                                    nonce: bundle.wrappedRootKey.nonce,
                                                    ciphertext: bundle.wrappedRootKey.ciphertext,
                                                    authenticationTag: Data(repeating: 0, count: 16))

        #expect(throws: SyncCryptoError.self) {
            try recovery.recoverRootKey(code: alteredCode, accountID: accountID,
                                        envelope: bundle.wrappedRootKey)
        }
        #expect(throws: SyncCryptoError.self) {
            try recovery.recoverRootKey(code: bundle.recoveryCode, accountID: accountID,
                                        envelope: alteredEnvelope)
        }
    }
}
