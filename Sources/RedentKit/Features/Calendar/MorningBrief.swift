import Foundation

public enum MorningBrief: Sendable {
    public static let itemLimit = 5

    public static func select(
        events: [CalendarEvent],
        now: Date,
        calendar: Calendar,
        limit: Int = itemLimit
    ) -> [CalendarEvent] {
        let visible = events.filter { isVisible($0, now: now, calendar: calendar) }
        return Array(visible.sorted(by: briefOrder).prefix(max(limit, 0)))
    }

    private static func isVisible(_ event: CalendarEvent, now: Date, calendar: Calendar) -> Bool {
        guard !event.isCancelled, !event.isDeclined else { return false }
        return overlapsToday(event, now: now, calendar: calendar)
    }

    private static func overlapsToday(_ event: CalendarEvent, now: Date, calendar: Calendar) -> Bool {
        let dayStart = calendar.startOfDay(for: now)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }
        return event.start < dayEnd && event.end > dayStart
    }

    private static func briefOrder(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay && !rhs.isAllDay }
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}
