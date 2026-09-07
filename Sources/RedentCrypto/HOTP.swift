import Foundation
import CryptoKit

/// RFC 4226 HMAC-based one-time password.
public enum HOTP {
    public static func generate(
        secret: Data, counter: UInt64, digits: Int, algorithm: HashAlgorithm
    ) -> String {
        let counterBytes = withUnsafeBytes(of: counter.bigEndian) { Data($0) }
        let mac = authenticationCode(key: secret, message: counterBytes, algorithm: algorithm)
        let code = dynamicTruncate(mac) % pow10(digits)
        let codeString = String(code)
        guard codeString.count < digits else { return codeString }
        return String(repeating: "0", count: digits - codeString.count) + codeString
    }

    /// RFC 4226 §5.3: use the low nibble of the last byte as an offset into
    /// the HMAC, then mask off the high bit of the 4-byte window so the
    /// result is always a non-negative 31-bit integer.
    private static func dynamicTruncate(_ mac: Data) -> UInt64 {
        let bytes = [UInt8](mac)
        let offset = Int(bytes[bytes.count - 1] & 0x0F)
        let truncated = (UInt32(bytes[offset] & 0x7F) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
        return UInt64(truncated)
    }

    private static func pow10(_ n: Int) -> UInt64 {
        var result: UInt64 = 1
        for _ in 0..<n { result *= 10 }
        return result
    }

    private static func authenticationCode(
        key: Data, message: Data, algorithm: HashAlgorithm
    ) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        switch algorithm {
        case .sha1:
            // RFC 6238 mandates SHA-1 as TOTP's default MAC. It is used here
            // only as a keyed HMAC, not for content hashing — do not "fix" this.
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: symmetricKey))
        case .sha256:
            return Data(HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey))
        case .sha512:
            return Data(HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey))
        }
    }
}
