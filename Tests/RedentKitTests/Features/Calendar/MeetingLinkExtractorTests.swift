import Foundation
import Testing
@testable import RedentKit

@Suite("Meeting link extractor")
struct MeetingLinkExtractorTests {
    @Test("Finds Google Meet, Zoom, Teams, Webex, and FaceTime https links")
    func knownHosts() {
        let samples = [
            "https://meet.google.com/abc-defg-hij",
            "https://us06web.zoom.us/j/123456789",
            "https://zoom.us/j/555",
            "https://www.zoom.com/j/555",
            "https://teams.microsoft.com/l/meetup-join/19%3ameeting",
            "https://teams.live.com/meet/123",
            "https://acme.webex.com/meet/jane",
            "https://facetime.apple.com/join#v=1&id=abc",
        ]
        for sample in samples {
            #expect(MeetingLinkExtractor.meetingURL(in: [sample])?.absoluteString == sample)
        }
    }

    @Test("Ignores http and non-https meeting schemes")
    func httpsOnly() {
        #expect(MeetingLinkExtractor.meetingURL(in: ["http://meet.google.com/abc-defg-hij"]) == nil)
        #expect(MeetingLinkExtractor.meetingURL(in: ["zoommtg://zoom.us/join?confno=1"]) == nil)
        #expect(MeetingLinkExtractor.meetingURL(in: ["facetime://alice@example.com"]) == nil)
    }

    @Test("Skips lookalike hosts that are not meeting products")
    func rejectsLookalikes() {
        #expect(MeetingLinkExtractor.meetingURL(in: ["https://meet.google.com.evil.test/x"]) == nil)
        #expect(MeetingLinkExtractor.meetingURL(in: ["https://notzoom.us/j/1"]) == nil)
        #expect(MeetingLinkExtractor.meetingURL(in: ["https://example.com/meet.google.com"]) == nil)
    }

    @Test("First meeting URL across url, location, then notes wins")
    func sourceOrder() {
        let url = MeetingLinkExtractor.meetingURL(in: [
            "Office",
            "https://acme.webex.com/meet/room",
            "Also https://meet.google.com/abc-defg-hij",
        ])
        #expect(url?.host == "acme.webex.com")
    }

    @Test("Non-meeting https links are ignored when picking a join URL")
    func skipsDocs() {
        let notes = "Agenda https://docs.google.com/doc/1 then https://meet.google.com/abc-defg-hij"
        #expect(MeetingLinkExtractor.meetingURL(in: [notes])?.host == "meet.google.com")
    }
}
