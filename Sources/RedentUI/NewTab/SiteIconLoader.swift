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
    private var inflight: [String: Task<Data?, Never>] = [:]
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
        if let onDisk = readDisk(host) {
            memory[host] = onDisk
            return onDisk
        }
        if let existing = inflight[host] { return await existing.value }

        let task = Task { await self.download(host: host) }
        inflight[host] = task
        let data = await task.value
        inflight[host] = nil
        memory[host] = data ?? Data()
        if let data { try? data.write(to: fileURL(for: host), options: .atomic) }
        return data
    }

    private func download(host: String) async -> Data? {
        var tried = Set<URL>()
        for url in SiteIconProbe.urls(for: host) {
            tried.insert(url)
            if let data = await fetch(url) { return data }
        }
        guard let html = await homepage(host) else { return nil }
        for url in SiteIconHTML.iconURLs(in: html, host: host) where tried.insert(url).inserted {
            if let data = await fetch(url) { return data }
        }
        return nil
    }

    private func homepage(_ host: String) async -> String? {
        guard let url = URL(string: "https://\(host)/") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let html = String(data: data.prefix(80_000), encoding: .utf8)
        else { return nil }
        return html
    }

    private func fetch(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.httpShouldHandleCookies = false
        request.setValue(
            "image/png,image/x-icon,image/svg+xml,image/webp,image/*;q=0.8,*/*;q=0.5",
            forHTTPHeaderField: "Accept"
        )
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              data.count <= Self.maxBytes,
              SiteIconProbe.isImage(data)
        else { return nil }
        return data
    }

    private func readDisk(_ host: String) -> Data? {
        let url = fileURL(for: host)
        guard let onDisk = try? Data(contentsOf: url), !onDisk.isEmpty else { return nil }
        guard SiteIconProbe.isImage(onDisk) else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return onDisk
    }

    private func fileURL(for host: String) -> URL {
        let safe = host.replacingOccurrences(of: "/", with: "_")
        return directory.appending(path: "\(safe).ico")
    }
}
