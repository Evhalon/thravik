import Foundation
import RedentKit

/// Imports history, bookmarks and passwords from Comet and other
/// Chromium-family browsers installed on this Mac.
public struct ChromiumImporter: BrowserImporting {
    public init() {}

    public func availableBrowsers() -> [ImportableBrowser] {
        ChromiumProfileLocator.availableBrowsers()
    }

    public func readHistory(from browser: ImportableBrowser) async throws -> [HistoryEntry] {
        let copy = try TempDatabaseCopy(fileName: "History", in: browser.profileURL)
        defer { copy.cleanUp() }
        return try HistoryTableReader.read(from: copy.databaseURL)
    }

    public func readBookmarks(from browser: ImportableBrowser) async throws -> [Bookmark] {
        let fileURL = browser.profileURL.appending(path: "Bookmarks")
        return try BookmarksJSONReader.read(from: fileURL)
    }

    public func readPasswords(from browser: ImportableBrowser) async throws -> [Credential] {
        let secret = try SafeStorageKeychain.secret(service: browser.safeStorageService)
        var key = ChromiumCrypto.deriveKey(fromSecret: secret)
        defer { key.zeroize() }
        return try ChromiumPasswordReader.read(from: browser.profileURL, key: key)
    }
}

extension [UInt8] {
    /// Best-effort scrub of derived key material once it's no longer needed
    /// (AGENTS.md §5). `Array` storage isn't guaranteed non-relocatable, but
    /// this removes the plaintext from the buffer we know we used.
    mutating func zeroize() {
        for index in indices { self[index] = 0 }
    }
}
