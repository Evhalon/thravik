import Foundation

/// Another browser Redent can take data from.
public struct ImportableBrowser: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// The profile directory holding `History`, `Bookmarks` and `Login Data`.
    public let profileURL: URL
    /// Keychain service holding this browser's password-encryption key.
    public let safeStorageService: String

    public init(id: String, name: String, profileURL: URL, safeStorageService: String) {
        self.id = id
        self.name = name
        self.profileURL = profileURL
        self.safeStorageService = safeStorageService
    }
}

/// What one import run produced. Counts only — never the data itself, so this
/// is safe to log and to show.
public struct ImportSummary: Sendable, Hashable {
    public var history: Int
    public var bookmarks: Int
    public var passwords: Int

    public init(history: Int = 0, bookmarks: Int = 0, passwords: Int = 0) {
        self.history = history
        self.bookmarks = bookmarks
        self.passwords = passwords
    }

    public var isEmpty: Bool { history == 0 && bookmarks == 0 && passwords == 0 }

    /// Folds another profile's counts in, so several profiles report as one run.
    public mutating func add(_ other: Self) {
        history += other.history
        bookmarks += other.bookmarks
        passwords += other.passwords
    }
}

public enum ImportKind: String, CaseIterable, Sendable, Identifiable {
    case history, bookmarks, passwords
    public var id: String { rawValue }
}

public enum ImportError: Error, Sendable, Equatable {
    case profileUnreadable
    case databaseUnreadable(String)
    case decryptionKeyUnavailable
    case malformedBookmarks
}

/// Reads another browser's profile. Implementations copy locked databases
/// before reading — a running browser holds an exclusive lock on them.
public protocol BrowserImporting: Sendable {
    /// Browsers actually present on this Mac.
    func availableBrowsers() -> [ImportableBrowser]
    func readHistory(from browser: ImportableBrowser) async throws -> [HistoryEntry]
    func readBookmarks(from browser: ImportableBrowser) async throws -> [Bookmark]
    /// Requires the browser's Keychain key; macOS will ask the user to allow it.
    func readPasswords(from browser: ImportableBrowser) async throws -> [Credential]
}
