import Foundation
import RedentKit

/// Form history in one JSON file, read whole on first use and kept in memory.
///
/// Only values `FormEntry` accepted reach it — never passwords, card or
/// one-time codes. The file is still readable by its owner alone, since an
/// address or phone number is nobody else's business.
actor FormHistoryFileStore {
    private let fileURL: URL
    private var cache: FormHistoryIndex?

    init(fileURL: URL) { self.fileURL = fileURL }

    func record(_ entries: [FormEntry], at date: Date) {
        var index = loaded()
        index.record(entries, at: date)
        save(index)
    }

    func suggestions(for key: FormFieldKey, matching prefix: String, limit: Int) -> [String] {
        loaded().suggestions(for: key, matching: prefix, limit: limit)
    }

    func remove(_ value: String, for key: FormFieldKey) {
        var index = loaded()
        index.remove(value, for: key)
        save(index)
    }

    func removeAll() {
        cache = FormHistoryIndex()
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// A missing or unreadable file is an empty history: forgetting is the
    /// safe direction to fail in.
    private func loaded() -> FormHistoryIndex {
        if let cache { return cache }
        let index = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode(FormHistoryIndex.self, from: $0) } ?? FormHistoryIndex()
        cache = index
        return index
    }

    private func save(_ index: FormHistoryIndex) {
        cache = index
        guard let data = try? JSONEncoder().encode(index) else { return }
        let manager = FileManager.default
        try? manager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard (try? data.write(to: fileURL, options: .atomic)) != nil else { return }
        try? manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}

public struct JSONFormHistoryStore: FormHistoryStoring {
    private let store: FormHistoryFileStore

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/form-history.json`.
    public init(fileURL: URL? = nil) {
        store = FormHistoryFileStore(fileURL: fileURL ?? RedentSupportDirectory.defaultFileURL(named: "form-history.json"))
    }

    public func record(_ entries: [FormEntry], at date: Date) async { await store.record(entries, at: date) }

    public func suggestions(for key: FormFieldKey, matching prefix: String, limit: Int) async -> [String] {
        await store.suggestions(for: key, matching: prefix, limit: limit)
    }

    public func remove(_ value: String, for key: FormFieldKey) async { await store.remove(value, for: key) }
    public func removeAll() async { await store.removeAll() }
}
