import Foundation
import RedentKit

enum CalendarEventFixtures {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    static let now = date(year: 2026, month: 10, day: 3, hour: 12, minute: 0)

    static func event(
        id: String = "event",
        title: String = "Standup",
        start: Date,
        end: Date,
        configure: (inout CalendarEvent.Details) -> Void = { _ in }
    ) -> CalendarEvent {
        var details = CalendarEvent.Details()
        configure(&details)
        return CalendarEvent(id: id, title: title, start: start, end: end, details: details)
    }

    static func url(_ value: String) -> URL {
        URL(string: value) ?? URL(fileURLWithPath: "/missing")
    }
}
