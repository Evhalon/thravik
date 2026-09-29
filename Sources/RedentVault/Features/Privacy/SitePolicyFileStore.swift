import Foundation
import RedentKit

/// Per-site decisions in one JSON file, held in memory between writes.
///
/// A handful of rows read whole is what a single file is for. A missing or
/// corrupt file yields no decisions — every site falls back to Ask, which is
/// the safe direction to fail in.
actor SitePolicyFileStore {
    private let fileURL: URL
    private var cache: [SitePolicy]?

    init(fileURL: URL) { self.fileURL = fileURL }

    func all() -> [SitePolicy] { loaded() }

    func policy(for key: SiteKey) -> SitePolicy {
        loaded().first { $0.key == key } ?? SitePolicy(key: key)
    }

    /// Storing an all-default policy would grow the file with rows that say
    /// nothing, so an emptied policy is removed instead.
    func save(_ policy: SitePolicy) {
        var entries = loaded().filter { $0.key != policy.key }
        if !policy.isEmpty { entries.append(policy) }
        cache = entries
        write(entries)
    }

    private func loaded() -> [SitePolicy] {
        if let cache { return cache }
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([SitePolicy].self, from: data)
        else {
            cache = []
            return []
        }
        cache = entries
        return entries
    }

    private func write(_ entries: [SitePolicy]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }
}

public struct JSONSitePolicyStore: SitePolicyStoring {
    private let store: SitePolicyFileStore

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/site-policies.json`.
    public init(fileURL: URL? = nil) {
        let resolved = fileURL ?? RedentSupportDirectory.defaultFileURL(named: "site-policies.json")
        store = SitePolicyFileStore(fileURL: resolved)
    }

    public func policy(for key: SiteKey) async -> SitePolicy { await store.policy(for: key) }
    public func save(_ policy: SitePolicy) async { await store.save(policy) }
    public func all() async -> [SitePolicy] { await store.all() }
}
