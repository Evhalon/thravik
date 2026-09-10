import Foundation

/// Where the tab strip lives. Dia-style rail on the side, or Chrome-style row on top.
public enum TabLayout: String, Codable, Sendable, CaseIterable, Identifiable {
    case sidebar
    case top

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .sidebar: "Sidebar"
        case .top: "Top bar"
        }
    }

    public var symbol: String {
        switch self {
        case .sidebar: "sidebar.left"
        case .top: "rectangle.topthird.inset.filled"
        }
    }
}

/// How aggressively idle tabs are torn down to reclaim memory.
public enum HibernationPolicy: String, Codable, Sendable, CaseIterable, Identifiable {
    case off
    case balanced
    case aggressive
    case thirtyMinutes
    case fortyFiveMinutes
    case sixtyMinutes
    case custom

    public var id: String { rawValue }

    /// Idle time before a background tab's web view is released.
    public var idleThreshold: TimeInterval? {
        switch self {
        case .off: nil
        case .balanced: 15 * 60
        case .aggressive: 3 * 60
        case .thirtyMinutes: 30 * 60
        case .fortyFiveMinutes: 45 * 60
        case .sixtyMinutes: 60 * 60
        case .custom: nil
        }
    }

    public var label: String {
        switch self {
        case .off: "Never"
        case .balanced: "After 15 min"
        case .aggressive: "After 3 min"
        case .thirtyMinutes: "After 30 min"
        case .fortyFiveMinutes: "After 45 min"
        case .sixtyMinutes: "After 60 min"
        case .custom: "Custom"
        }
    }

    public static let selectableCases: [Self] = [
        .off, .balanced, .thirtyMinutes, .fortyFiveMinutes, .sixtyMinutes, .custom
    ]
}

public struct BrowserSettings: Codable, Sendable, Equatable {
    public var tabLayout: TabLayout
    public var isTabStripVisible: Bool
    public var sidebarWidth: Double
    public var hibernation: HibernationPolicy
    public var customHibernationMinutes: Int?
    /// Ads and trackers. On by default, like Brave Shields.
    public var blocksTrackers: Bool
    public var offersPasswordSave: Bool
    public var showsTOTPButton: Bool
    public var searchEngine: SearchEngine
    public var homepage: String

    public static let sidebarWidthRange: ClosedRange<Double> = 180...380

    public init(
        tabLayout: TabLayout = .sidebar,
        isTabStripVisible: Bool = true,
        sidebarWidth: Double = 248,
        hibernation: HibernationPolicy = .balanced,
        customHibernationMinutes: Int? = 15,
        blocksTrackers: Bool = true,
        offersPasswordSave: Bool = true,
        showsTOTPButton: Bool = true,
        searchEngine: SearchEngine = .duckduckgo,
        homepage: String = "https://duckduckgo.com"
    ) {
        self.tabLayout = tabLayout
        self.isTabStripVisible = isTabStripVisible
        self.sidebarWidth = sidebarWidth.clamped(to: Self.sidebarWidthRange)
        self.hibernation = hibernation
        self.customHibernationMinutes = customHibernationMinutes
        self.blocksTrackers = blocksTrackers
        self.offersPasswordSave = offersPasswordSave
        self.showsTOTPButton = showsTOTPButton
        self.searchEngine = searchEngine
        self.homepage = homepage
    }

    public var hibernationIdleThreshold: TimeInterval? {
        guard hibernation == .custom else { return hibernation.idleThreshold }
        return TimeInterval(max(customHibernationMinutes ?? 15, 1) * 60)
    }

    /// Picking an engine moves the homepage with it, so the two do not disagree.
    /// A homepage the user typed themselves is left alone.
    public mutating func selectSearchEngine(_ engine: SearchEngine) {
        let trimmed = homepage.trimmingCharacters(in: .whitespacesAndNewlines)
        let followsEngine = trimmed.isEmpty || SearchEngine.allCases.contains { $0.homepage == trimmed }
        searchEngine = engine
        if followsEngine { homepage = engine.homepage }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
