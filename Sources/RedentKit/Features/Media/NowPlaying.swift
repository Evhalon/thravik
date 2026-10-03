import Foundation

/// Compact playback card for a background tab.
///
/// `canSkip` stays false: `MediaSession` action handlers live in the page
/// world, and isolated-world scripts cannot invoke them.
public struct NowPlaying: Sendable, Equatable {
    public var tabID: UUID
    public var title: String
    public var artist: String?
    public var artworkURL: URL?
    public var isPlaying: Bool
    public var canSkip = false
    public var updatedAt: Date

    public init(
        tabID: UUID,
        title: String,
        artist: String? = nil,
        artworkURL: URL? = nil,
        isPlaying: Bool,
        updatedAt: Date
    ) {
        self.tabID = tabID
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.isPlaying = isPlaying
        self.updatedAt = updatedAt
    }
}
