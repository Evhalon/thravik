import Foundation

/// Fetches a site's favicon for the new-tab grid.
///
/// Straight from the site's own origin — never through a third-party favicon
/// service, which would hand a list of the user's frequent sites to someone
/// else (AGENTS.md §5). Results are cached on disk, so the grid costs nothing
/// after the first render.
public actor SiteIconLoader {
    public static let shared = SiteIconLoader()

    private var memory: [String: Data] = [:]
    private var inFlight: Set<String> = []
    private let directory: URL

    private static let maxBytes = 200_000

    public init(directory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Redent/Icons", directoryHint: .isDirectory)
        self.directory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    public func icon(for host: String) async -> Data? {
        if let cached = memory[host] { return cached.isEmpty ? nil : cached }
        if let onDisk = try? Data(contentsOf: fileURL(for: host)) {
            memory[host] = onDisk
            return onDisk.isEmpty ? nil : onDisk
        }
        guard !inFlight.contains(host) else { return nil }
        inFlight.insert(host)
        defer { inFlight.remove(host) }

        let data = await download(host: host)
        // An empty entry is a negative cache: a site with no icon must not be
        // re-fetched on every render.
        memory[host] = data ?? Data()
        try? (data ?? Data()).write(to: fileURL(for: host), options: .atomic)
        return data
    }

    /// Warms the small set of icons a hovered folder is about to reveal.
    public func preload(hosts: [String]) async {
        let candidates = Array(Set(hosts).prefix(12))
        await withTaskGroup(of: Void.self) { group in
            for host in candidates {
                group.addTask { [self] in _ = await icon(for: host) }
            }
        }
    }

    private func download(host: String) async -> Data? {
        guard let url = URL(string: "https://\(host)/favicon.ico") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              !data.isEmpty, data.count <= Self.maxBytes
        else { return nil }
        return data
    }

    private func fileURL(for host: String) -> URL {
        let safe = host.replacingOccurrences(of: "/", with: "_")
        return directory.appending(path: "\(safe).ico")
    }
}
