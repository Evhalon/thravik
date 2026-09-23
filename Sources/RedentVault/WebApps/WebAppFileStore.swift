import Foundation
import RedentKit

/// Saved web apps in one JSON file, held in memory between writes.
///
/// A handful of rows read whole is what a single file is for. A missing or
/// corrupt file yields no apps rather than a crash; the sites are one ⌘K away
/// from being saved again.
actor WebAppFileStore {
    private let fileURL: URL
    private var cache: [WebApp]?

    init(fileURL: URL) { self.fileURL = fileURL }

    func all() -> [WebApp] { loaded() }

    func save(_ app: WebApp) {
        var entries = loaded()
        if let index = entries.firstIndex(where: { $0.id == app.id }) {
            entries[index] = app
        } else {
            entries.append(app)
        }
        write(entries)
    }

    func delete(_ id: UUID) {
        write(loaded().filter { $0.id != id })
    }

    private func loaded() -> [WebApp] {
        if let cache { return cache }
        let entries = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([WebApp].self, from: $0) } ?? []
        cache = entries
        return entries
    }

    private func write(_ entries: [WebApp]) {
        cache = entries
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }
}

public struct JSONWebAppStore: WebAppStoring {
    private let store: WebAppFileStore

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/web-apps.json`.
    public init(fileURL: URL? = nil) {
        let resolved = fileURL ?? RedentSupportDirectory.defaultFileURL(named: "web-apps.json")
        store = WebAppFileStore(fileURL: resolved)
    }

    public func all() async -> [WebApp] { await store.all() }
    public func save(_ app: WebApp) async { await store.save(app) }
    public func delete(_ id: UUID) async { await store.delete(id) }
}
