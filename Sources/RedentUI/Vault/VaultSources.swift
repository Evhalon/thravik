import RedentKit

/// What the vault window needs to render itself.
public struct VaultSources {
    public let credentials: any CredentialStoring
    public let totp: any TOTPAccountStoring
    public let generator: any TOTPGenerating

    public init(
        credentials: any CredentialStoring,
        totp: any TOTPAccountStoring,
        generator: any TOTPGenerating
    ) {
        self.credentials = credentials
        self.totp = totp
        self.generator = generator
    }
}
