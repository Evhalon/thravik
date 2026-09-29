import Foundation

/// How a web app's own macOS app talks to the browser: the link it opens to
/// bring its window forward, the keys its bundle carries, and the two
/// notifications that keep the pair alive and dead together.
public enum WebAppLink {
    public static let scheme = "redent-webapp"
    /// Info.plist key naming the web app a launcher bundle opens.
    public static let appIDKey = "RedentWebAppID"
    /// Info.plist key naming the browser that serves it.
    public static let hostBundleIDKey = "RedentHostBundleID"
    /// Posted by the browser when an app's window closes; object: the app id.
    public static let windowClosedNotification = "app.redent.webapp.windowClosed"
    /// Posted by the launcher when the user quits it; object: the app id.
    public static let launcherQuitNotification = "app.redent.webapp.launcherQuit"

    public static func url(for appID: UUID) -> URL? {
        URL(string: "\(scheme)://open/\(appID.uuidString)")
    }

    /// The app a link asks for, or nil when it is not a web-app link at all.
    public static func appID(in url: URL) -> UUID? {
        guard url.scheme?.lowercased() == scheme, url.host()?.lowercased() == "open" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
