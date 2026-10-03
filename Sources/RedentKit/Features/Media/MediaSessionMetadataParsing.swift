import Foundation

public enum MediaSessionMetadataParsing {
    public static let maxTextLength = 200

    public static func parse(_ payload: MediaSessionPayload) -> ParsedMediaSession {
        ParsedMediaSession(
            title: cleaned(payload.title),
            artist: cleaned(payload.artist),
            artworkURL: artworkURL(from: payload.artwork)
        )
    }

    public static func decode(_ data: Data) throws -> ParsedMediaSession {
        parse(try JSONDecoder().decode(MediaSessionPayload.self, from: data))
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxTextLength))
    }

    private static func artworkURL(from raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else { return nil }
        guard scheme == "https" || scheme == "http", url.host != nil else { return nil }
        return url
    }
}
