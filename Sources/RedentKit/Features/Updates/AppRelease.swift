import Foundation

/// A published build the app could move to.
public struct AppRelease: Sendable, Equatable {
    public let version: AppVersion
    /// The disk image to download. Always `https`.
    public let downloadURL: URL
    /// The human-readable release page, for the "What's new" link.
    public let pageURL: URL?

    public init(version: AppVersion, downloadURL: URL, pageURL: URL? = nil) {
        self.version = version
        self.downloadURL = downloadURL
        self.pageURL = pageURL
    }
}
