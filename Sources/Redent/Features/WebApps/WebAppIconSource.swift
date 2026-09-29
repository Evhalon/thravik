import Foundation
import RedentKit

/// A tab's favicon is often 16 or 32 pixels — a smudge at Dock size. Most
/// sites also publish a 180-pixel touch icon at a well-known address; that one
/// is used whenever it is there and larger.
enum WebAppIconSource {
    static func bestIcon(for app: WebApp) async -> Data? {
        let stored = app.faviconData
        guard let touchIcon = await fetchTouchIcon(for: app.url),
              let fetched = WebAppIconRenderer.decode(touchIcon), fetched.width >= 64
        else { return stored }
        let storedWidth = stored.flatMap(WebAppIconRenderer.decode)?.width ?? 0
        return fetched.width > storedWidth ? touchIcon : stored
    }

    private static func fetchTouchIcon(for url: URL) async -> Data? {
        guard let origin = Origin(url: url),
              let address = URL(string: "\(origin.scheme)://\(origin.host)/apple-touch-icon.png") else { return nil }
        var request = URLRequest(url: address, timeoutInterval: 6)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }
}
