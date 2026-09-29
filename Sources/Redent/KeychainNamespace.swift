/// Debug and release builds carry different signatures, and the legacy
/// Keychain trusts one signature per item: every store rewrites its item for
/// whichever build unlocked it last, so sharing items made each build lock the
/// other out and re-prompt. Debug builds keep vaults of their own instead.
enum KeychainNamespace {
    #if DEBUG
    static let suffix = ".debug"
    #else
    static let suffix = ""
    #endif

    static func service(_ base: String) -> String {
        base + suffix
    }
}
