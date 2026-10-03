import Foundation
import Testing
@testable import RedentKit

@Suite("Meeting link scanning")
struct MeetingLinkExtractorScanTests {
    @Test("Strips trailing punctuation and angle-bracket wrappers")
    func punctuation() {
        let notes = "Join <https://meet.google.com/abc-defg-hij> now."
        #expect(
            MeetingLinkExtractor.meetingURL(in: [notes])?.absoluteString
                == "https://meet.google.com/abc-defg-hij"
        )
        let zoom = "See https://zoom.us/j/123)."
        #expect(MeetingLinkExtractor.meetingURL(in: [zoom])?.absoluteString == "https://zoom.us/j/123")
    }

    @Test("Keeps query and fragment on the first https URL")
    func queryAndFragment() {
        let raw = "https://meet.google.com/abc-defg-hij?authuser=0#success"
        #expect(MeetingLinkExtractor.httpsURLs(in: "Notes \(raw)").first?.absoluteString == raw)
    }

    @Test("Collects every distinct https URL in notes")
    func allHTTPS() {
        let notes = """
        Deck https://docs.google.com/doc/1
        Meet https://meet.google.com/abc-defg-hij
        Copy https://docs.google.com/doc/1
        """
        let urls = MeetingLinkExtractor.httpsURLs(in: notes)
        #expect(urls.map(\.host) == ["docs.google.com", "meet.google.com"])
    }

    @Test("Matches hosts case-insensitively")
    func caseInsensitive() {
        #expect(MeetingLinkExtractor.meetingURL(in: ["HTTPS://MEET.GOOGLE.COM/XYZ"]) != nil)
    }

    @Test("Empty or URL-free text yields nothing")
    func empty() {
        #expect(MeetingLinkExtractor.meetingURL(in: ["", "lunch downstairs"]) == nil)
        #expect(MeetingLinkExtractor.httpsURLs(in: "no links here").isEmpty)
    }
}
