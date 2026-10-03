import Foundation
import RedentKit
import Testing

@Suite("Media session metadata parsing")
struct MediaSessionMetadataParsingTests {
    @Test("JSON payload keeps title, artist, and https artwork")
    func decodesHonestPayload() throws {
        let data = Data(#"{"title":"Night Drive","artist":"Nova","artwork":"https://cdn.example/art.jpg"}"#.utf8)
        let parsed = try MediaSessionMetadataParsing.decode(data)
        #expect(parsed.title == "Night Drive")
        #expect(parsed.artist == "Nova")
        #expect(parsed.artworkURL?.absoluteString == "https://cdn.example/art.jpg")
    }

    @Test("Blank and oversized fields collapse to safe values")
    func cleansText() {
        let long = String(repeating: "a", count: 400)
        let parsed = MediaSessionMetadataParsing.parse(
            MediaSessionPayload(title: "  \(long)  ", artist: "   ", artwork: "https://cdn.example/a.png")
        )
        #expect(parsed.title?.count == MediaSessionMetadataParsing.maxTextLength)
        #expect(parsed.artist == nil)
        #expect(parsed.artworkURL?.host == "cdn.example")
    }

    @Test("Artwork rejects javascript, data, blob, and hostless URLs")
    func rejectsUnsafeArtwork() {
        let schemes = ["javascript:alert(1)", "data:image/png;base64,xx", "blob:https://example/1", "not-a-url"]
        for raw in schemes {
            let parsed = MediaSessionMetadataParsing.parse(MediaSessionPayload(artwork: raw))
            #expect(parsed.artworkURL == nil)
        }
        #expect(MediaSessionMetadataParsing.parse(MediaSessionPayload(artwork: "http://ok.example/a.jpg")).artworkURL != nil)
    }

    @Test("Missing keys decode as empty metadata")
    func emptyJSON() throws {
        let parsed = try MediaSessionMetadataParsing.decode(Data(#"{}"#.utf8))
        #expect(parsed.title == nil)
        #expect(parsed.artist == nil)
        #expect(parsed.artworkURL == nil)
    }
}
