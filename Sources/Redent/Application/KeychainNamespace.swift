import Foundation

/// The legacy Keychain trusts one signature per item, and every store rewrites
/// its item for whichever build unlocked it last, so builds sharing items lock
/// each other out and re-prompt on every switch. Each bundle ID — and so each
/// signature — keeps vaults of its own; only the release keeps the bare names.
enum KeychainNamespace {
    static let releaseBundleID = "app.redent.browser"

    static func service(_ base: String) -> String {
        base + suffix(forBundleID: Bundle.main.bundleIdentifier)
    }

    /// Xcode and `swift run` launch the bare executable, which has no bundle ID.
    static func suffix(forBundleID bundleID: String?) -> String {
        guard let bundleID, !bundleID.isEmpty else { return ".debug" }
        guard bundleID != releaseBundleID else { return "" }
        let variantPrefix = releaseBundleID + "."
        guard bundleID.hasPrefix(variantPrefix) else { return "." + bundleID }
        return "." + bundleID.dropFirst(variantPrefix.count)
    }
}
