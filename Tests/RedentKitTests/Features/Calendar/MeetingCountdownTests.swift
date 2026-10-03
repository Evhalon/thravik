import Foundation
import Testing
@testable import RedentKit

@Suite("Meeting countdown")
struct MeetingCountdownTests {
    private let now = CalendarEventFixtures.now

    @Test("Empty or far-away events are none")
    func none() {
        #expect(MeetingCountdown.evaluate(events: [], now: now) == .none)
        let later = event(minutesFromNow: 16, duration: 30)
        #expect(MeetingCountdown.evaluate(events: [later], now: now).state == .none)
    }

    @Test("Upcoming within 15 minutes reports remaining minutes")
    func upcoming() {
        let soon = event(minutesFromNow: 5, duration: 30)
        let result = MeetingCountdown.evaluate(events: [soon], now: now)
        #expect(result.event?.id == soon.id)
        #expect(result.state == .upcoming(minutes: 5))
        #expect(result.pillText == "Standup · in 5 min")
    }

    @Test("Exactly 15 minutes counts as upcoming; 16 does not")
    func windowEdge() {
        let edge = event(minutesFromNow: 15, duration: 30)
        #expect(MeetingCountdown.evaluate(events: [edge], now: now).state == .upcoming(minutes: 15))
    }

    @Test("A meeting that has started is live")
    func live() {
        let current = event(minutesFromNow: -10, duration: 30)
        let result = MeetingCountdown.evaluate(events: [current], now: now)
        #expect(result.state == .live)
        #expect(result.pillText == "Standup · now")
    }

    @Test("Live wins over a later upcoming meeting")
    func preferLive() {
        let current = event(id: "live", minutesFromNow: -5, duration: 30)
        let soon = event(id: "soon", minutesFromNow: 4, duration: 30)
        let result = MeetingCountdown.evaluate(events: [soon, current], now: now)
        #expect(result.event?.id == "live")
        #expect(result.state == .live)
    }

    @Test("Soonest upcoming wins when none are live")
    func soonest() {
        let later = event(id: "later", minutesFromNow: 12, duration: 30)
        let sooner = event(id: "sooner", minutesFromNow: 3, duration: 30)
        #expect(MeetingCountdown.evaluate(events: [later, sooner], now: now).event?.id == "sooner")
    }

    @Test("All-day, cancelled, declined, and ended meetings are skipped")
    func skipped() {
        let allDay = event(minutesFromNow: 2, duration: 30) { $0.isAllDay = true }
        let cancelled = event(minutesFromNow: 2, duration: 30) { $0.isCancelled = true }
        let declined = event(minutesFromNow: 2, duration: 30) { $0.isDeclined = true }
        let ended = event(minutesFromNow: -40, duration: 30)
        let result = MeetingCountdown.evaluate(events: [allDay, cancelled, declined, ended], now: now)
        #expect(result == .none)
    }

    @Test("Sub-minute remaining still shows one minute")
    func roundsUp() {
        let meeting = event(minutesFromNow: 0, duration: 30, startOffset: 20)
        #expect(MeetingCountdown.evaluate(events: [meeting], now: now).state == .upcoming(minutes: 1))
    }

    @Test("A link-less block does not hide a joinable meeting inside it")
    func skipsUnjoinable() {
        let focus = event(id: "focus", minutesFromNow: -30, duration: 120) { $0.meetingURL = nil }
        let call = event(id: "call", minutesFromNow: 5, duration: 30)
        let result = MeetingCountdown.evaluate(events: [focus, call], now: now)
        #expect(result.event?.id == "call")
        #expect(result.state == .upcoming(minutes: 5))
    }

    private func event(
        id: String = "event",
        minutesFromNow: Int,
        duration: Int,
        startOffset: TimeInterval = 0,
        configure: (inout CalendarEvent.Details) -> Void = { _ in }
    ) -> CalendarEvent {
        let start = now.addingTimeInterval(TimeInterval(minutesFromNow * 60) + startOffset)
        let end = start.addingTimeInterval(TimeInterval(duration * 60))
        return CalendarEventFixtures.event(id: id, start: start, end: end) { details in
            details.meetingURL = CalendarEventFixtures.url("https://meet.google.com/abc-defg-hij")
            configure(&details)
        }
    }
}
