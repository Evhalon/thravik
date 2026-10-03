import Foundation

private enum BrowserSettingsCodingKey: String, CodingKey {
    case tabLayout, isTabStripVisible, opensFloatingNewTab, hidesNavigationBar, showsBookmarksBar, sidebarWidth, hibernation
    case customHibernationMinutes, blocksTrackers, stripsTrackingParameters, quietsPages
    case offersPasswordSave, showsTOTPButton, searchEngine, homepage, reopensTabsOnLaunch
    case namesGroupsOnDevice, remembersFormEntries
    case excludeBankingAndHealthFromHistory, sensitiveSiteHistoryDomains
    case customSearchEngines, activeCustomSearchEngineID
    case floatsPlayingVideoOnTabSwitch
    case tidyTabsThreshold
    case showsUpcomingMeetings
    case shortcutBindings
}

/// Decoding is explicit so adding a preference never resets saved settings.
extension BrowserSettings {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: BrowserSettingsCodingKey.self)
        let defaults = Self()
        self.init(
            tabLayout: try values.decodeIfPresent(TabLayout.self, forKey: .tabLayout) ?? defaults.tabLayout,
            isTabStripVisible: try values.decodeIfPresent(Bool.self, forKey: .isTabStripVisible) ?? defaults.isTabStripVisible,
            sidebarWidth: try values.decodeIfPresent(Double.self, forKey: .sidebarWidth) ?? defaults.sidebarWidth,
            hibernation: try values.decodeIfPresent(HibernationPolicy.self, forKey: .hibernation) ?? defaults.hibernation,
            customHibernationMinutes: try values.decodeIfPresent(Int.self, forKey: .customHibernationMinutes) ?? defaults.customHibernationMinutes,
            blocksTrackers: try values.decodeIfPresent(Bool.self, forKey: .blocksTrackers) ?? defaults.blocksTrackers,
            stripsTrackingParameters: try values.decodeIfPresent(Bool.self, forKey: .stripsTrackingParameters) ?? defaults.stripsTrackingParameters,
            quietsPages: try values.decodeIfPresent(Bool.self, forKey: .quietsPages) ?? defaults.quietsPages,
            offersPasswordSave: try values.decodeIfPresent(Bool.self, forKey: .offersPasswordSave) ?? defaults.offersPasswordSave,
            showsTOTPButton: try values.decodeIfPresent(Bool.self, forKey: .showsTOTPButton) ?? defaults.showsTOTPButton,
            searchEngine: try values.decodeIfPresent(SearchEngine.self, forKey: .searchEngine) ?? defaults.searchEngine,
            homepage: try values.decodeIfPresent(String.self, forKey: .homepage) ?? defaults.homepage,
            reopensTabsOnLaunch: try values.decodeIfPresent(Bool.self, forKey: .reopensTabsOnLaunch) ?? defaults.reopensTabsOnLaunch
        )
        hidesNavigationBar = try values.decodeIfPresent(Bool.self, forKey: .hidesNavigationBar) ?? false
        showsBookmarksBar = try values.decodeIfPresent(Bool.self, forKey: .showsBookmarksBar) ?? false
        opensFloatingNewTab = try values.decodeIfPresent(Bool.self, forKey: .opensFloatingNewTab) ?? true
        namesGroupsOnDevice = try values.decodeIfPresent(Bool.self, forKey: .namesGroupsOnDevice) ?? true
        remembersFormEntries = try values.decodeIfPresent(Bool.self, forKey: .remembersFormEntries) ?? true
        excludeBankingAndHealthFromHistory = try values.decodeIfPresent(
            Bool.self, forKey: .excludeBankingAndHealthFromHistory
        ) ?? false
        sensitiveSiteHistoryDomains = try values.decodeIfPresent(
            [String].self, forKey: .sensitiveSiteHistoryDomains
        ) ?? []
        customSearchEngines = try values.decodeIfPresent(
            [CustomSearchEngine].self, forKey: .customSearchEngines
        ) ?? []
        activeCustomSearchEngineID = try values.decodeIfPresent(
            UUID.self, forKey: .activeCustomSearchEngineID
        )
        floatsPlayingVideoOnTabSwitch = try values.decodeIfPresent(
            Bool.self, forKey: .floatsPlayingVideoOnTabSwitch
        ) ?? false
        tidyTabsThreshold = try values.decodeIfPresent(
            TidyTabsThreshold.self, forKey: .tidyTabsThreshold
        ) ?? .off
        showsUpcomingMeetings = try values.decodeIfPresent(
            Bool.self, forKey: .showsUpcomingMeetings
        ) ?? false
        // A damaged key map must not reset every other setting with it.
        shortcutBindings = (try? values.decodeIfPresent(
            ShortcutBindings.self, forKey: .shortcutBindings
        )) ?? ShortcutBindings()
    }
}
