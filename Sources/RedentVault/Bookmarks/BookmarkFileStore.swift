import Foundation
import RedentKit

/// Owns the decoded bookmark list in memory and the JSON file backing it.
///
/// Hundreds of rows read whole on every new-tab render is exactly what one
/// file in memory is for — no need for SQLite here. A missing or corrupt
/// file yields an empty list, never a crash.
actor BookmarkFileStore {
    private let fileURL: URL
    private var cache: [Bookmark]?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func all(in spaceID: UUID?) -> [Bookmark] {
        scoped(to: spaceID)
    }

    func favorites(in spaceID: UUID?) -> [Bookmark] {
        scoped(to: spaceID).filter(\.isFavorite).sorted { $0.addedAt > $1.addedAt }
    }

    func search(_ query: String, in spaceID: UUID?, limit: Int) -> [Bookmark] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return scoped(to: spaceID)
            .filter { matches($0, needle: needle) }
            .prefix(limit)
            .map { $0 }
    }

    func bookmark(for url: URL, in spaceID: UUID?) -> Bookmark? {
        let key = BookmarkKey.normalized(url)
        return scoped(to: spaceID).first { BookmarkKey.normalized($0.url) == key }
    }

    private func scoped(to spaceID: UUID?) -> [Bookmark] {
        guard let spaceID else { return loaded() }
        return loaded().filter { $0.spaceID == spaceID }
    }

    func save(_ bookmark: Bookmark) {
        var entries = loaded()
        if let index = entries.firstIndex(where: { $0.id == bookmark.id }) {
            entries[index] = bookmark
        } else {
            entries.append(bookmark)
        }
        persist(entries)
    }

    @discardableResult
    func merge(_ bookmarks: [Bookmark]) -> Int {
        var entries = loaded()
        var existingKeys = Set(entries.map(Self.dedupeKey))
        var addedCount = 0
        for bookmark in bookmarks {
            let key = Self.dedupeKey(bookmark)
            guard !existingKeys.contains(key) else { continue }
            existingKeys.insert(key)
            entries.append(bookmark)
            addedCount += 1
        }
        persist(entries)
        return addedCount
    }

    func delete(_ id: UUID) {
        persist(loaded().filter { $0.id != id })
    }

    /// The same page in two Spaces is two bookmarks, so the Space is part of
    /// the key: importing into Personal must not be swallowed by Work.
    private static func dedupeKey(_ bookmark: Bookmark) -> String {
        "\(bookmark.spaceID?.uuidString ?? "-")|\(BookmarkKey.normalized(bookmark.url))"
    }

    private func matches(_ bookmark: Bookmark, needle: String) -> Bool {
        bookmark.title.lowercased().contains(needle)
            || (bookmark.origin?.host.contains(needle) ?? false)
            || bookmark.folderPath.joined(separator: "/").lowercased().contains(needle)
    }

    private func loaded() -> [Bookmark] {
        if let cache { return cache }
        let entries = Self.readFromDisk(fileURL)
        cache = entries
        return entries
    }

    private func persist(_ entries: [Bookmark]) {
        cache = entries
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Bookmarks written before Spaces became profiles carry no Space. They
    /// join Work, which is also the Space that kept the existing cookies.
    private static func readFromDisk(_ fileURL: URL) -> [Bookmark] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return [] }
        return entries.map { bookmark in
            guard bookmark.spaceID == nil else { return bookmark }
            var adopted = bookmark
            adopted.spaceID = BrowserSpace.workID
            return adopted
        }
    }
}
