import CommonCrypto
import Foundation
import Testing
@testable import RedentImport

@Suite("ChromiumCrypto")
struct ChromiumCryptoTests {
    /// Encrypts with `CCCrypt` ourselves, prepends the `v10` prefix Chromium
    /// uses, then decrypts through `ChromiumCrypto` to prove the prefix and
    /// space-IV handling match Chromium's own scheme.
    @Test("AES-CBC round trip through the v10 prefix and space IV")
    func roundTripsThroughOwnEncryption() throws {
        let key = ChromiumCrypto.deriveKey(fromSecret: Data("test-secret".utf8))
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
        let plaintext = Array("hunter2".utf8)

        var ciphertext = [UInt8](repeating: 0, count: plaintext.count + kCCBlockSizeAES128)
        var bytesEncrypted = 0
        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            key, key.count,
            iv,
            plaintext, plaintext.count,
            &ciphertext, ciphertext.count,
            &bytesEncrypted
        )
        #expect(status == kCCSuccess)

        var blob = Data("v10".utf8)
        blob.append(contentsOf: ciphertext.prefix(bytesEncrypted))

        let decrypted = try ChromiumCrypto.decrypt(blob, key: key)
        #expect(String(data: decrypted, encoding: .utf8) == "hunter2")
    }

    @Test("PBKDF2 derivation matches a pinned vector")
    func pinnedPBKDF2Vector() {
        // password="peanuts", salt="saltysalt", 1003 iterations, SHA1, 16-byte
        // key — the constant Chromium itself falls back to when no Keychain
        // secret is available. Expected bytes computed independently via
        // Python's hashlib.pbkdf2_hmac, not via CommonCrypto.
        let key = ChromiumCrypto.deriveKey(fromSecret: Data("peanuts".utf8))
        let expected: [UInt8] = [
            0xd9, 0xa0, 0x9d, 0x49, 0x9b, 0x4e, 0x1b, 0x74,
            0x61, 0xf2, 0x8e, 0x67, 0x97, 0x2c, 0x6d, 0xbd
        ]
        #expect(key == expected)
    }
}
