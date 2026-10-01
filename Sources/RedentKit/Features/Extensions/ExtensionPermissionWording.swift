/// Turns manifest permissions into the sentences shown before install, in the
/// spirit of Chrome's own warnings: what the extension can reach, not the
/// API names it asked for.
public enum ExtensionPermissionWording {
    public static func lines(permissions: Set<String>, hostPatterns: Set<String>) -> [String] {
        var lines: [String] = []
        if let hosts = hostLine(hostPatterns) { lines.append(hosts) }
        // Several APIs share one warning; the user should read it once.
        for line in permissions.sorted().compactMap({ wording[$0] }) where !lines.contains(line) {
            lines.append(line)
        }
        return lines
    }

    /// Names a Chrome API WebKit dropped from the manifest, falling back to
    /// the API name itself for ones without a friendlier label.
    public static func featureNames(_ permissions: [String]) -> [String] {
        permissions.sorted().map { featureWording[$0] ?? $0 }
    }

    private static let featureWording: [String: String] = [
        "debugger": "Debugger",
        "desktopCapture": "Screen capture",
        "identity": "Google sign-in",
        "nativeMessaging": "Messaging with desktop apps",
        "offscreen": "Offscreen documents",
        "pageCapture": "Saving pages",
        "proxy": "Proxy settings",
        "sidePanel": "Side panel",
        "tabCapture": "Tab audio and video capture",
        "tabGroups": "Tab groups",
        "tts": "Text to speech"
    ]

    private static func hostLine(_ patterns: Set<String>) -> String? {
        guard !patterns.isEmpty else { return nil }
        if patterns.contains(where: isAllSites) { return "Read and change all your data on all websites" }
        let hosts = Set(patterns.compactMap(host(of:))).sorted()
        guard !hosts.isEmpty else { return nil }
        let shown = hosts.prefix(3).joined(separator: ", ")
        let more = hosts.count > 3 ? " and \(hosts.count - 3) more" : ""
        return "Read and change your data on \(shown)\(more)"
    }

    private static func isAllSites(_ pattern: String) -> Bool {
        pattern == "<all_urls>" || pattern.hasPrefix("*://*/") || pattern.hasPrefix("http://*/")
            || pattern.hasPrefix("https://*/")
    }

    /// `*://*.example.com/*` reads as `example.com`.
    private static func host(of pattern: String) -> String? {
        guard let schemeEnd = pattern.range(of: "://") else { return nil }
        let rest = pattern[schemeEnd.upperBound...]
        let host = rest.prefix { $0 != "/" }
        let trimmed = host.hasPrefix("*.") ? host.dropFirst(2) : host
        return trimmed.isEmpty ? nil : String(trimmed)
    }

    private static let wording: [String: String] = [
        "bookmarks": "Read and change your bookmarks",
        "clipboardRead": "Read data you copy and paste",
        "clipboardWrite": "Change data you copy and paste",
        "cookies": "Read and change cookies",
        "declarativeNetRequest": "Block content on any page",
        "downloads": "Manage your downloads",
        "geolocation": "Detect your physical location",
        "history": "Read and change your browsing history",
        "management": "Manage your other extensions",
        "nativeMessaging": "Communicate with cooperating native apps",
        "notifications": "Display notifications",
        "scripting": "Run scripts on the pages it can access",
        "tabs": "Read your browsing history",
        "webNavigation": "Read your browsing history",
        "webRequest": "Observe your network traffic"
    ]
}
