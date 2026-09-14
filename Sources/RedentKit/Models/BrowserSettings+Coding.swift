import Foundation

private enum BrowserSettingsCodingKey: String, CodingKey {
    case tabLayout, isTabStripVisible, sidebarWidth, hibernation
    case customHibernationMinutes, blocksTrackers, offersPasswordSave
    case showsTOTPButton, searchEngine, homepage, reopensTabsOnLaunch
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
            offersPasswordSave: try values.decodeIfPresent(Bool.self, forKey: .offersPasswordSave) ?? defaults.offersPasswordSave,
            showsTOTPButton: try values.decodeIfPresent(Bool.self, forKey: .showsTOTPButton) ?? defaults.showsTOTPButton,
            searchEngine: try values.decodeIfPresent(SearchEngine.self, forKey: .searchEngine) ?? defaults.searchEngine,
            homepage: try values.decodeIfPresent(String.self, forKey: .homepage) ?? defaults.homepage,
            reopensTabsOnLaunch: try values.decodeIfPresent(Bool.self, forKey: .reopensTabsOnLaunch) ?? defaults.reopensTabsOnLaunch
        )
    }
}
