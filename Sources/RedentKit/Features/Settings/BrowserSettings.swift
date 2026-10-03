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
    /// Command-T starts with a floating search instead of a blank tab.
    public var opensFloatingNewTab = true
    public var hidesNavigationBar = false
    /// Off so existing profiles keep a clean chrome.
    public var showsBookmarksBar = false
    public var sidebarWidth: Double
    public var hibernation: HibernationPolicy
    public var customHibernationMinutes: Int?
    /// Ads and trackers. On by default, like Brave Shields.
    public var blocksTrackers: Bool
    /// Drops click IDs and campaign tags from links before they load.
    public var stripsTrackingParameters: Bool
    /// Declines cookie banners, stops sound nobody asked for, and keeps
    /// push-notification pitches off the page.
    public var quietsPages: Bool
    public var offersPasswordSave: Bool
    public var showsTOTPButton: Bool
    public var searchEngine: SearchEngine
    public var customSearchEngines: [CustomSearchEngine] = []
    public var activeCustomSearchEngineID: UUID?
    public var homepage: String
    /// Restores the primary workspace when the app opens.
    public var reopensTabsOnLaunch: Bool
    /// Lets Apple Intelligence, on this Mac, name tab groups by topic.
    public var namesGroupsOnDevice = true
    /// Offers values sent in earlier forms under the field being typed in.
    public var remembersFormEntries = true
    /// Built-in banking and health registrable domains skip history when on.
    public var excludeBankingAndHealthFromHistory = false
    /// User-listed registrable domains that never appear in history or frecency.
    public var sensitiveSiteHistoryDomains: [String] = []
    public var floatsPlayingVideoOnTabSwitch = false
    public var tidyTabsThreshold: TidyTabsThreshold = .off
    public var showsUpcomingMeetings = false
    public var shortcutBindings = ShortcutBindings()

    public static let sidebarWidthRange: ClosedRange<Double> = 180...380

    public init(
        tabLayout: TabLayout = .sidebar,
        isTabStripVisible: Bool = true,
        sidebarWidth: Double = 248,
        hibernation: HibernationPolicy = .balanced,
        customHibernationMinutes: Int? = 15,
        blocksTrackers: Bool = true,
        stripsTrackingParameters: Bool = true,
        quietsPages: Bool = true,
        offersPasswordSave: Bool = true,
        showsTOTPButton: Bool = true,
        searchEngine: SearchEngine = .duckduckgo,
        homepage: String = "https://duckduckgo.com",
        reopensTabsOnLaunch: Bool = true
    ) {
        self.tabLayout = tabLayout
        self.isTabStripVisible = isTabStripVisible
        self.sidebarWidth = sidebarWidth.clamped(to: Self.sidebarWidthRange)
        self.hibernation = hibernation
        self.customHibernationMinutes = customHibernationMinutes
        self.blocksTrackers = blocksTrackers
        self.stripsTrackingParameters = stripsTrackingParameters
        self.quietsPages = quietsPages
        self.offersPasswordSave = offersPasswordSave
        self.showsTOTPButton = showsTOTPButton
        self.searchEngine = searchEngine
        self.homepage = homepage
        self.reopensTabsOnLaunch = reopensTabsOnLaunch
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
