import CommonCrypto
import Foundation
import RedentKit

/// Chromium's macOS "safe storage" scheme: PBKDF2-derived AES-128-CBC with a
/// fixed salt and a blank-space IV. Every browser in the family shares it.
enum ChromiumCrypto {
    private static let salt = Array("saltysalt".utf8)
    private static let iterations: UInt32 = 1_003
    private static let keyLength = 16
    private static let prefix = Array("v10".utf8)

    /// Derives the AES key from the Keychain secret. The returned bytes are
    /// the caller's responsibility to zero once decryption is done.
    static func deriveKey(fromSecret secret: Data) -> [UInt8] {
        var key = [UInt8](repeating: 0, count: keyLength)
        let secretBytes = Array(secret)
        _ = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            secretBytes, secretBytes.count,
            salt, salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            iterations,
            &key, keyLength
        )
        return key
    }

    /// Decrypts one `password_value` blob. Throws `.decryptionKeyUnavailable`
    /// on any cryptographic failure — a bad key looks the same as a corrupt
    /// blob from the caller's point of view.
    static func decrypt(_ blob: Data, key: [UInt8]) throws -> Data {
        guard blob.count > prefix.count, Array(blob.prefix(prefix.count)) == prefix else {
            throw ImportError.decryptionKeyUnavailable
        }
        let ciphertext = Array(blob.dropFirst(prefix.count))
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)

        var plaintext = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        var bytesDecrypted = 0
        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            key, key.count,
            iv,
            ciphertext, ciphertext.count,
            &plaintext, plaintext.count,
            &bytesDecrypted
        )
        guard status == kCCSuccess else { throw ImportError.decryptionKeyUnavailable }
        return Data(plaintext.prefix(bytesDecrypted))
    }
}
