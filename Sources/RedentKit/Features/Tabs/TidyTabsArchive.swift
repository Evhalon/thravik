import Foundation

public enum TidyTabsArchive {
    public static let namePrefix = "Archived "

    public static func isArchivedGroupName(_ name: String) -> Bool {
        name.hasPrefix(namePrefix)
    }

    public static func groupName(now: Date, calendar: Calendar = .current) -> String {
        let day = calendar.startOfDay(for: now)
        let formatted = Self.dayFormatter.string(from: day)
        return namePrefix + formatted
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
