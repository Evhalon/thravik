import Foundation

struct AdblockListDownloader: Sendable {
    private let maximumBytes = 12_000_000

    func fetch(_ source: AdblockFilterSource) async -> String? {
        var request = URLRequest(url: source.url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadRevalidatingCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200, data.count <= maximumBytes,
              let text = String(data: data, encoding: .utf8),
              text.contains("[Adblock Plus") || text.contains("! Title:")
        else { return nil }
        return text
    }
}
