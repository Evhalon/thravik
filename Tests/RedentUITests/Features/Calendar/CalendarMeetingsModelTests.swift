import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Calendar meetings model")
struct CalendarMeetingsModelTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let now = Date(timeIntervalSince1970: 1_791_028_800)

    @Test("Turned off, the provider is never asked for access or events")
    func offTouchesNothing() async {
        let provider = FakeCalendarEventsProvider(status: .notDetermined)
        let model = CalendarMeetingsModel(provider: provider, isEnabled: false)
        model.tick(now: now, isEnabled: false, calendar: calendar)
        await model.fetchTask?.value
        #expect(await provider.accessRequests == 0)
        #expect(await provider.fetchCount == 0)
        #expect(model.countdown == .none)
    }

    @Test("Enabling asks for access once, then shows the upcoming meeting")
    func enableRequestsAccess() async {
        let provider = FakeCalendarEventsProvider(status: .notDetermined, events: [meeting(minutesFromNow: 5)])
        let model = CalendarMeetingsModel(provider: provider)
        model.setEnabled(true, now: now, calendar: calendar)
        await model.fetchTask?.value
        #expect(await provider.accessRequests == 1)
        #expect(model.countdown.state == .upcoming(minutes: 5))
        #expect(model.brief.count == 1)
    }

    @Test("Ticks within the same day reuse the fetched events")
    func ticksDoNotRefetch() async {
        let provider = FakeCalendarEventsProvider(events: [meeting(minutesFromNow: 10)])
        let model = CalendarMeetingsModel(provider: provider)
        model.setEnabled(true, now: now, calendar: calendar)
        await model.fetchTask?.value
        for second in 1...180 {
            model.tick(now: now.addingTimeInterval(TimeInterval(second)), isEnabled: true, calendar: calendar)
        }
        await model.fetchTask?.value
        #expect(await provider.fetchCount == 1)
        #expect(model.countdown.state == .upcoming(minutes: 7))
    }

    @Test("A calendar change refetches on the next tick")
    func changeRefetches() async {
        let provider = FakeCalendarEventsProvider(events: [meeting(minutesFromNow: 10)])
        let model = CalendarMeetingsModel(provider: provider)
        model.setEnabled(true, now: now, calendar: calendar)
        await model.fetchTask?.value
        provider.announceChange()
        for _ in 0..<20 { await Task.yield() }
        model.tick(now: now.addingTimeInterval(1), isEnabled: true, calendar: calendar)
        await model.fetchTask?.value
        #expect(await provider.fetchCount == 2)
    }

    @Test("Denied access shows nothing and reads no events")
    func deniedShowsNothing() async {
        let provider = FakeCalendarEventsProvider(status: .denied, events: [meeting(minutesFromNow: 5)])
        let model = CalendarMeetingsModel(provider: provider)
        model.setEnabled(true, now: now, calendar: calendar)
        await model.fetchTask?.value
        #expect(await provider.fetchCount == 0)
        #expect(model.countdown == .none)
        #expect(model.brief.isEmpty)
    }

    @Test("Turning off clears the pill and the brief")
    func disableClears() async {
        let provider = FakeCalendarEventsProvider(events: [meeting(minutesFromNow: 5)])
        let model = CalendarMeetingsModel(provider: provider)
        model.setEnabled(true, now: now, calendar: calendar)
        await model.fetchTask?.value
        model.tick(now: now, isEnabled: false, calendar: calendar)
        #expect(model.countdown == .none)
        #expect(model.brief.isEmpty)
    }

    private func meeting(minutesFromNow: Int) -> CalendarEvent {
        let start = now.addingTimeInterval(TimeInterval(minutesFromNow * 60))
        var details = CalendarEvent.Details()
        details.meetingURL = URL(string: "https://meet.google.com/abc-defg-hij")
        return CalendarEvent(id: "meeting", title: "Sync", start: start, end: start.addingTimeInterval(1800), details: details)
    }
}
