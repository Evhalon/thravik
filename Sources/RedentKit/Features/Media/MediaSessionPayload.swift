import Foundation

/// Wire shape posted by the isolated-world now-playing script.
public struct MediaSessionPayload: Codable, Sendable, Equatable {
    public var title: String?
    public var artist: String?
    public var artwork: String?

    public init(title: String? = nil, artist: String? = nil, artwork: String? = nil) {
        self.title = title
        self.artist = artist
        self.artwork = artwork
    }
}
