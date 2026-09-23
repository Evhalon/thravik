import Foundation
import RedentKit

/// A run of history shown under one heading: a day while browsing, or the
/// single "Best matches" block while searching.
struct HistorySection: Identifiable, Equatable {
    let id: String
    let title: String
    let entries: [HistoryEntry]

    /// Groups newest-first entries by the calendar day of their last visit.
    /// Pure, with the clock and calendar injected, so "Today" is testable.
    static func byDay(
        _ entries: [HistoryEntry], now: Date, calendar: Calendar = .current
    ) -> [HistorySection] {
        var sections: [HistorySection] = []
        var currentDay: Date?
        var bucket: [HistoryEntry] = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.lastVisit)
            if day != currentDay, let previous = currentDay {
                sections.append(section(for: previous, bucket, now: now, calendar: calendar))
                bucket = []
            }
            currentDay = day
            bucket.append(entry)
        }
        if let currentDay {
            sections.append(section(for: currentDay, bucket, now: now, calendar: calendar))
        }
        return sections
    }

    private static func section(
        for day: Date, _ entries: [HistoryEntry], now: Date, calendar: Calendar
    ) -> HistorySection {
        HistorySection(
            id: "day-\(Int(day.timeIntervalSinceReferenceDate))",
            title: title(for: day, now: now, calendar: calendar),
            entries: entries
        )
    }

    /// "Today", "Yesterday", a weekday within the last week, then a date.
    static func title(for day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: day, to: today).day ?? 0
        if days == 1 { return "Yesterday" }
        if days < 7 { return day.formatted(.dateTime.weekday(.wide)) }
        let sameYear = calendar.component(.year, from: day) == calendar.component(.year, from: now)
        return sameYear
            ? day.formatted(.dateTime.weekday(.wide).day().month(.wide))
            : day.formatted(.dateTime.day().month(.wide).year())
    }
}
