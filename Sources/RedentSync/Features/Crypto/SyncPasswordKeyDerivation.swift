import CommonCrypto
import CryptoKit
import Foundation

struct SyncPasswordKeyDerivation {
    static let iterations: UInt32 = 600_000

    func derive(password: String, salt: Data) throws -> SymmetricKey {
        var passwordBytes = Data(password.utf8)
        var output = Data(count: 32)
        defer {
            passwordBytes.resetBytes(in: 0..<passwordBytes.count)
            output.resetBytes(in: 0..<output.count)
        }
        let status = passwordBytes.withUnsafeBytes { input in
            salt.withUnsafeBytes { saltBytes in
                output.withUnsafeMutableBytes { result in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                        input.bindMemory(to: Int8.self).baseAddress, input.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress, saltBytes.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), Self.iterations,
                        result.bindMemory(to: UInt8.self).baseAddress, result.count)
                }
            }
        }
        guard status == kCCSuccess else { throw SyncPasswordCryptographyError.derivationFailed }
        return SymmetricKey(data: output)
    }
}
