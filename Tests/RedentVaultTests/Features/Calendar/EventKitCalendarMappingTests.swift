import EventKit
import Foundation
import Testing
@testable import RedentVault

@Suite("EventKit calendar mapping")
struct EventKitCalendarMappingTests {
    @Test("Two occurrences of one recurring event get distinct, stable ids")
    func occurrenceIDs() {
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = Date(timeIntervalSince1970: 1_791_000_000)
        event.endDate = event.startDate.addingTimeInterval(1800)
        let first = EventKitCalendarMapping.occurrenceID(event)
        #expect(EventKitCalendarMapping.occurrenceID(event) == first)
        event.startDate = event.startDate.addingTimeInterval(3600)
        #expect(EventKitCalendarMapping.occurrenceID(event) != first)
    }

    @Test("Meeting link comes from the event URL; other note links follow")
    func mapsLinks() {
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = Date(timeIntervalSince1970: 1_791_000_000)
        event.endDate = event.startDate.addingTimeInterval(1800)
        event.url = URL(string: "https://us02web.zoom.us/j/1")
        event.notes = "Deck https://docs.example.com/d then https://us02web.zoom.us/j/1"
        let mapped = EventKitCalendarMapping.event(event)
        #expect(mapped.meetingURL?.host == "us02web.zoom.us")
        #expect(mapped.relatedURLs.map(\.host) == ["docs.example.com"])
        #expect(mapped.title == "Event")
    }
}
