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

    func all() -> [Bookmark] {
        loaded()
    }

    func favorites() -> [Bookmark] {
        loaded().filter(\.isFavorite).sorted { $0.addedAt > $1.addedAt }
    }

    func search(_ query: String, limit: Int) -> [Bookmark] {
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        return loaded()
            .filter { matches($0, needle: needle) }
            .prefix(limit)
            .map { $0 }
    }

    func bookmark(for url: URL) -> Bookmark? {
        let key = BookmarkKey.normalized(url)
        return loaded().first { BookmarkKey.normalized($0.url) == key }
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
        var existingKeys = Set(entries.map { BookmarkKey.normalized($0.url) })
        var addedCount = 0
        for bookmark in bookmarks {
            let key = BookmarkKey.normalized(bookmark.url)
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

    private static func readFromDisk(_ fileURL: URL) -> [Bookmark] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return [] }
        return entries
    }
}
