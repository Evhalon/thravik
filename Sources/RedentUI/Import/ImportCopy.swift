import RedentKit

/// The words shown next to each import option.
///
/// Passwords get an explicit warning because macOS will put up a Keychain
/// prompt, and an unexplained system dialog during an import reads as an attack.
enum ImportCopy {
    static func title(for kind: ImportKind) -> String {
        switch kind {
        case .history: "Browsing history"
        case .bookmarks: "Bookmarks and favorites"
        case .passwords: "Saved passwords"
        }
    }

    static func detail(for kind: ImportKind) -> String {
        switch kind {
        case .history: "Powers address bar suggestions and the new-tab page."
        case .bookmarks: "Bookmarks-bar entries become favorites."
        case .passwords: "macOS will ask permission to read the other browser's key."
        }
    }
}
