import WebKit

/// Downloads and caches favicons by host, off the main actor. Twenty tabs on
/// one site fetch the icon once.
actor FaviconFetcher {
    private var cache: [String: Data] = [:]
    private let maxBytes = 100 * 1024

    func favicon(host: String, candidates: [URL]) async -> Data? {
        if let cached = cache[host] { return cached }
        for url in candidates {
            if let data = await download(url) {
                cache[host] = data
                return data
            }
        }
        return nil
    }

    private func download(_ url: URL) async -> Data? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty, data.count <= maxBytes
        else { return nil }
        return data
    }
}

extension WebTab {
    /// Called from the navigation delegate on `didFinish`. Fire-and-forget —
    /// a slow or failed favicon fetch must never hold up navigation state.
    func handleDidFinishNavigation(webView: WKWebView) {
        Task { [weak self] in
            await self?.fetchFavicon(webView: webView)
        }
    }

    private func fetchFavicon(webView: WKWebView) async {
        // The favicon fetcher shares one URLSession cache across every tab. A
        // temporary tab must not deposit its browsing there, so it goes without.
        guard !snapshot.isTemporary else { return }
        guard let pageURL = webView.url, let host = pageURL.host() else { return }

        var candidates: [URL] = []
        if let discovered = await discoveredFavicon(in: webView),
           let url = URL(string: discovered) {
            candidates.append(url)
        }
        if let fallback = URL(string: "/favicon.ico", relativeTo: pageURL) {
            candidates.append(fallback)
        }
        guard !candidates.isEmpty, let fetcher = controller?.faviconFetcher,
              let data = await fetcher.favicon(host: host, candidates: candidates)
        else { return }
        snapshot.faviconData = data
    }

    private func discoveredFavicon(in webView: WKWebView) async -> String? {
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(Self.faviconLookupJS, in: nil, in: PageScripts.contentWorld) { result in
                guard case .success(let value) = result else { continuation.resume(returning: nil); return }
                continuation.resume(returning: value as? String)
            }
        }
    }

    private static let faviconLookupJS =
        "(function(){var l=document.querySelector('link[rel~=\"icon\"]');return l?l.href:'';})();"
}
