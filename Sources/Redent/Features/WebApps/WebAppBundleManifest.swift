import Foundation
import RedentKit

/// What a web app's own bundle is called and what its Info.plist says.
struct WebAppBundleManifest {
    static let executableName = "WebApp"
    static let iconName = "AppIcon"

    let app: WebApp
    let host: WebAppHost

    /// The name in Finder and the Dock. Path separators would split it into
    /// folders, and a leading dot would hide it.
    var displayName: String {
        let cleaned = app.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".")))
        return cleaned.isEmpty ? "Web App" : cleaned
    }

    var bundleFileName: String { "\(displayName).app" }

    /// Unique per app and stable across reinstalls, so the Dock keeps a pinned
    /// app pinned after its icon or name is refreshed.
    var bundleIdentifier: String {
        "\(host.bundleID).webapp.\(app.id.uuidString.lowercased().replacingOccurrences(of: "-", with: ""))"
    }

    var infoPlist: [String: Any] {
        [
            "CFBundleName": displayName,
            "CFBundleDisplayName": displayName,
            "CFBundleExecutable": Self.executableName,
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundlePackageType": "APPL",
            "CFBundleIconFile": Self.iconName,
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "LSMinimumSystemVersion": "26.0",
            "NSPrincipalClass": "NSApplication",
            "NSHighResolutionCapable": true,
            WebAppLink.appIDKey: app.id.uuidString,
            WebAppLink.hostBundleIDKey: host.bundleID
        ]
    }
}

/// The browser the installed apps call back into, and the launcher executable
/// it ships for them.
struct WebAppHost: Sendable {
    let bundleID: String
    let name: String
    let launcher: URL?

    /// Inside the packaged app the launcher sits in `Contents/Helpers`; in a
    /// development build it sits beside the browser's own executable.
    static func current(bundle: Bundle = .main) -> WebAppHost {
        let packaged = bundle.bundleURL.appending(path: "Contents/Helpers/RedentAppShim")
        let sibling = bundle.executableURL?.deletingLastPathComponent().appending(path: "RedentAppShim")
        let launcher = [packaged, sibling].compactMap { $0 }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
        return WebAppHost(
            bundleID: bundle.bundleIdentifier ?? "app.redent.browser",
            name: bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Redent",
            launcher: launcher
        )
    }
}
