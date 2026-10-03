import Foundation

/// How long a background tab may sit unused before Tidy Tabs may archive it.
public enum TidyTabsThreshold: String, Codable, Sendable, CaseIterable, Identifiable {
    case off
    case twelveHours
    case oneDay
    case threeDays
    case sevenDays

    public var id: String { rawValue }

    public var inactivityInterval: TimeInterval? {
        switch self {
        case .off: nil
        case .twelveHours: 12 * 3600
        case .oneDay: 24 * 3600
        case .threeDays: 3 * 24 * 3600
        case .sevenDays: 7 * 24 * 3600
        }
    }

    public var label: String {
        switch self {
        case .off: "Off"
        case .twelveHours: "12 hours"
        case .oneDay: "1 day"
        case .threeDays: "3 days"
        case .sevenDays: "7 days"
        }
    }

    /// Manual tidy when the preference is off.
    public static let manualFallbackInterval: TimeInterval = 24 * 3600
}
