import Foundation
import Security
import RedentKit

/// Maps `OSStatus` results from Security.framework onto `VaultError`.
enum KeychainStatus {
    static func check(_ status: OSStatus) throws {
        guard status != errSecSuccess else { return }
        throw error(for: status)
    }

    static func error(for status: OSStatus) -> VaultError {
        switch status {
        case errSecItemNotFound: .itemNotFound
        case errSecDuplicateItem: .duplicateItem
        case errSecAuthFailed, errSecInteractionNotAllowed: .authenticationFailed
        default: .keychain(status: status)
        }
    }
}
