import Foundation

public struct ParsedMediaSession: Sendable, Equatable {
    public var title: String?
    public var artist: String?
    public var artworkURL: URL?

    public init(title: String? = nil, artist: String? = nil, artworkURL: URL? = nil) {
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
    }
}
