import Foundation
import Observation
import RedentKit

/// Fetches today's events once per day and again whenever the calendar
/// changes; the window clock only re-evaluates the cached events.
@MainActor
@Observable
public final class CalendarMeetingsModel {
    public private(set) var countdown = MeetingCountdown.none
    public private(set) var brief: [CalendarEvent] = []

    @ObservationIgnored private let provider: (any CalendarEventsProviding)?
    @ObservationIgnored private var cached: [CalendarEvent] = []
    @ObservationIgnored private var fetchedDay: DateComponents?
    @ObservationIgnored private(set) var fetchTask: Task<Void, Never>?
    @ObservationIgnored private var changeTask: Task<Void, Never>?

    public init(provider: (any CalendarEventsProviding)?, isEnabled: Bool = false) {
        self.provider = provider
        if isEnabled { refresh(now: .now, calendar: .current) }
    }

    public func tick(now: Date, isEnabled: Bool, calendar: Calendar = .current) {
        guard isEnabled else {
            clear()
            return
        }
        if fetchedDay != dayStamp(now, calendar: calendar) {
            refresh(now: now, calendar: calendar)
        } else {
            apply(now: now, calendar: calendar)
        }
    }

    public func setEnabled(_ enabled: Bool, now: Date, calendar: Calendar = .current) {
        if enabled {
            refresh(now: now, calendar: calendar)
        } else {
            clear()
        }
    }

    private func refresh(now: Date, calendar: Calendar) {
        fetchedDay = dayStamp(now, calendar: calendar)
        fetchTask?.cancel()
        guard let provider else {
            apply(now: now, calendar: calendar)
            return
        }
        observeChanges(provider)
        let window = Self.dayWindow(now: now, calendar: calendar)
        fetchTask = Task { [weak self] in
            let events = await Self.load(provider: provider, window: window)
            guard !Task.isCancelled, let self else { return }
            cached = events
            apply(now: now, calendar: calendar)
        }
    }

    /// A change only invalidates the cache; the next tick refetches with its
    /// own clock, so a burst of changes costs one query.
    private func observeChanges(_ provider: any CalendarEventsProviding) {
        guard changeTask == nil else { return }
        let changes = provider.changes()
        changeTask = Task { [weak self] in
            for await _ in changes { self?.fetchedDay = nil }
        }
    }

    private func apply(now: Date, calendar: Calendar) {
        let next = MeetingCountdown.evaluate(events: cached, now: now)
        let items = MorningBrief.select(events: cached, now: now, calendar: calendar)
        if countdown != next { countdown = next }
        if brief != items { brief = items }
    }

    private func clear() {
        fetchTask?.cancel()
        fetchTask = nil
        changeTask?.cancel()
        changeTask = nil
        fetchedDay = nil
        cached = []
        if countdown != .none { countdown = .none }
        if !brief.isEmpty { brief = [] }
    }

    private func dayStamp(_ now: Date, calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.era, .year, .month, .day], from: now)
    }

    private static func load(provider: any CalendarEventsProviding, window: DateInterval) async -> [CalendarEvent] {
        var status = await provider.authorizationStatus()
        if status == .notDetermined { status = await provider.requestAccess() }
        guard status == .authorized else { return [] }
        return (try? await provider.events(in: window)) ?? []
    }

    private static func dayWindow(now: Date, calendar: Calendar) -> DateInterval {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }
}
