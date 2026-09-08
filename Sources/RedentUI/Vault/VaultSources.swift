import Foundation
import RedentKit

/// What the vault window needs to render itself: the two stores, the code
/// generator, and the Space names, so a login saved in two profiles reads as
/// two logins rather than a duplicate.
public struct VaultSources {
    public let credentials: any CredentialStoring
    public let totp: any TOTPAccountStoring
    public let generator: any TOTPGenerating
    public let spaceNames: [UUID: String]

    public init(
        credentials: any CredentialStoring,
        totp: any TOTPAccountStoring,
        generator: any TOTPGenerating,
        spaceNames: [UUID: String] = [:]
    ) {
        self.credentials = credentials
        self.totp = totp
        self.generator = generator
        self.spaceNames = spaceNames
    }
}
