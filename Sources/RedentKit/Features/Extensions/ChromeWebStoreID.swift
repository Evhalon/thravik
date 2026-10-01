import Foundation

/// The 32-letter id the Chrome Web Store gives every extension, taken from a
/// store link or typed on its own.
///
/// Ids use only the letters a–p (hex digits shifted into letters), so anything
/// else is rejected outright rather than sent to Google's update service.
public struct ChromeWebStoreID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if Self.isValid(trimmed) {
            rawValue = trimmed
            return
        }
        guard let url = URL(string: trimmed), let id = Self.id(in: url) else { return nil }
        rawValue = id
    }

    public var description: String { rawValue }

    /// Where Chrome itself fetches the package. `prodversion` has to name a
    /// Chrome recent enough for the extension, or the service answers with
    /// nothing at all.
    public var downloadURL: URL? {
        var components = URLComponents(string: "https://clients2.google.com/service/update2/crx")
        components?.queryItems = [
            URLQueryItem(name: "response", value: "redirect"),
            URLQueryItem(name: "prodversion", value: Self.chromeVersion),
            URLQueryItem(name: "acceptformat", value: "crx2,crx3"),
            URLQueryItem(name: "x", value: "id=\(rawValue)&uc")
        ]
        return components?.url
    }

    /// The extension's own page in the store.
    public var storePageURL: URL? {
        URL(string: "https://chromewebstore.google.com/detail/\(rawValue)")
    }

    /// True for the store's extension pages, old domain and new.
    public static func isStorePage(_ url: URL) -> Bool {
        id(in: url) != nil
    }

    static let chromeVersion = "140.0.0.0"

    private static let storeHosts: Set<String> = ["chromewebstore.google.com", "chrome.google.com"]

    private static func id(in url: URL) -> String? {
        guard let host = url.host()?.lowercased(), storeHosts.contains(host) else { return nil }
        return url.pathComponents.last { isValid($0.lowercased()) }?.lowercased()
    }

    private static func isValid(_ text: String) -> Bool {
        text.count == 32 && text.unicodeScalars.allSatisfy { ("a"..."p").contains($0) }
    }
}
