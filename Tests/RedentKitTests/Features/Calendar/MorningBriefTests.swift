import Foundation
import Testing
@testable import RedentKit

@Suite("Morning brief")
struct MorningBriefTests {
    private let calendar = CalendarEventFixtures.calendar
    private let now = CalendarEventFixtures.now

    @Test("Today's events are sorted all-day first, then by start")
    func sortsAllDayFirst() {
        let late = named("Late", hour: 16, minute: 0)
        let early = named("Early", hour: 9, minute: 0)
        let allDay = CalendarEventFixtures.event(
            id: "all",
            title: "Holiday",
            start: calendar.startOfDay(for: now),
            end: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
                ?? now.addingTimeInterval(86_400)
        ) { $0.isAllDay = true }
        let selected = MorningBrief.select(events: [late, allDay, early], now: now, calendar: calendar)
        #expect(selected.map(\.title) == ["Holiday", "Early", "Late"])
    }

    @Test("Keeps at most five events")
    func capsAtFive() {
        let events = (8...14).map { named("M\($0)", hour: $0, minute: 0) }
        #expect(MorningBrief.select(events: events, now: now, calendar: calendar).count == 5)
        #expect(MorningBrief.select(events: events, now: now, calendar: calendar).map(\.title) == [
            "M8", "M9", "M10", "M11", "M12",
        ])
    }

    @Test("Drops yesterday, tomorrow, cancelled, and declined")
    func filters() {
        let today = named("Today", hour: 13, minute: 0)
        let yesterday = CalendarEventFixtures.event(
            id: "y", title: "Old", start: now.addingTimeInterval(-86_400), end: now.addingTimeInterval(-85_000)
        )
        let tomorrow = CalendarEventFixtures.event(
            id: "t", title: "Next", start: now.addingTimeInterval(86_400), end: now.addingTimeInterval(87_000)
        )
        let cancelled = named("Nope", hour: 10, minute: 0) { $0.isCancelled = true }
        let declined = named("Skip", hour: 11, minute: 0) { $0.isDeclined = true }
        let selected = MorningBrief.select(
            events: [today, yesterday, tomorrow, cancelled, declined],
            now: now,
            calendar: calendar
        )
        #expect(selected.map(\.title) == ["Today"])
    }

    @Test("Empty day yields an empty brief")
    func empty() {
        #expect(MorningBrief.select(events: [], now: now, calendar: calendar).isEmpty)
    }

    private func named(
        _ title: String,
        hour: Int,
        minute: Int,
        configure: (inout CalendarEvent.Details) -> Void = { _ in }
    ) -> CalendarEvent {
        let start = CalendarEventFixtures.date(year: 2026, month: 10, day: 3, hour: hour, minute: minute)
        return CalendarEventFixtures.event(
            id: title, title: title, start: start, end: start.addingTimeInterval(1800), configure: configure
        )
    }
}
