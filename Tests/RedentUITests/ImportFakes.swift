import Foundation
import RedentKit

/// A stand-in for another browser on disk: each profile hands back a fixed
/// number of rows, or throws if it was seeded to fail.
struct FakeBrowserImporter: BrowserImporting {
    struct Profile: Sendable {
        var history: Int = 0
        var bookmarks: Int = 0
        var passwords: Int = 0
        var passwordError: ImportError?
    }

    var profiles: [String: Profile] = [:]
    var browsers: [ImportableBrowser] = []

    func availableBrowsers() -> [ImportableBrowser] { browsers }

    func readHistory(from browser: ImportableBrowser) async throws -> [HistoryEntry] {
        (0..<count(browser, \.history)).map { index in
            HistoryEntry(url: url(browser, "page", index))
        }
    }

    func readBookmarks(from browser: ImportableBrowser) async throws -> [Bookmark] {
        (0..<count(browser, \.bookmarks)).map { index in
            Bookmark(url: url(browser, "mark", index))
        }
    }

    func readPasswords(from browser: ImportableBrowser) async throws -> [Credential] {
        if let error = profiles[browser.id]?.passwordError { throw error }
        return try (0..<count(browser, \.passwords)).map { index in
            guard let origin = Origin(url: url(browser, "login", index)) else {
                throw ImportError.profileUnreadable
            }
            return Credential(origin: origin, username: "user\(index)", password: "secret")
        }
    }

    private func count(_ browser: ImportableBrowser, _ key: KeyPath<Profile, Int>) -> Int {
        profiles[browser.id]?[keyPath: key] ?? 0
    }

    /// Each profile gets its own host, so nothing is deduplicated away by
    /// accident and a per-profile count stays visible in the total.
    private func url(_ browser: ImportableBrowser, _ kind: String, _ index: Int) -> URL {
        let host = browser.id.lowercased().filter { $0.isLetter || $0.isNumber }
        return URL(string: "https://\(host).example.com/\(kind)/\(index)") ?? URL(fileURLWithPath: "/")
    }
}

actor RecordingHistoryStore: HistoryStoring {
    private(set) var merged: [HistoryEntry] = []

    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async { merged.append(contentsOf: entries) }
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

actor RecordingBookmarkStore: BookmarkStoring {
    private(set) var merged: [Bookmark] = []

    func all(in spaceID: UUID?) async -> [Bookmark] { merged }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func save(_ bookmark: Bookmark) async { merged.append(bookmark) }
    func merge(_ bookmarks: [Bookmark]) async -> Int {
        let fresh = bookmarks.filter { candidate in !merged.contains { $0.url == candidate.url } }
        merged.append(contentsOf: fresh)
        return fresh.count
    }
    func delete(_ id: UUID) async {}
}

extension ImportableBrowser {
    static func fake(_ id: String, name: String? = nil) -> Self {
        Self(
            id: id,
            name: name ?? id,
            profileURL: URL(fileURLWithPath: "/tmp/\(id)"),
            safeStorageService: "Fake Safe Storage"
        )
    }
}
