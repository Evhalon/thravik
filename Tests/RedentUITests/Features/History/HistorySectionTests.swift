import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("History day sections")
struct HistorySectionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()
    /// 2026-09-23 15:00 UTC, a Wednesday.
    private let now = Date(timeIntervalSince1970: 1_790_175_600)

    private func visit(hoursAgo: Double) -> HistoryEntry {
        HistoryEntry(
            url: URL(string: "https://example.com") ?? URL(fileURLWithPath: "/"),
            lastVisit: now.addingTimeInterval(-hoursAgo * 3600)
        )
    }

    @Test("Visits are split at midnight, newest day first")
    func groupsByDay() {
        let entries = [visit(hoursAgo: 1), visit(hoursAgo: 3), visit(hoursAgo: 20), visit(hoursAgo: 60)]
        let sections = HistorySection.byDay(entries, now: now, calendar: calendar)
        #expect(sections.map(\.entries.count) == [2, 1, 1])
        #expect(sections.prefix(2).map(\.title) == ["Today", "Yesterday"])
    }

    @Test("Nothing visited, no sections")
    func emptyHasNoSections() {
        #expect(HistorySection.byDay([], now: now, calendar: calendar).isEmpty)
    }

    @Test("Older than a week reads as a date, not a weekday")
    func olderDaysAreDated() {
        let day = calendar.startOfDay(for: now.addingTimeInterval(-10 * 86_400))
        let title = HistorySection.title(for: day, now: now, calendar: calendar)
        #expect(title != "Today" && title != "Yesterday")
        #expect(title.contains("13"))
    }
}
