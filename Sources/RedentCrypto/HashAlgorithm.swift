import Foundation

/// The HMAC hash function underneath HOTP/TOTP generation.
public enum HashAlgorithm: String, Sendable, Hashable {
    case sha1, sha256, sha512
}
