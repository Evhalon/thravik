import Foundation
import RedentKit

extension BrowserModel {
    func refreshTidyTabs(now: Date = .now) {
        guard settings.tidyTabsThreshold != .off else {
            updateTidyTabsPresentation(candidates: [], showSuggestion: false)
            return
        }
        let automatic = tidyTabCandidates(requiresMinimumCount: true, now: now)
        let show = tidyTabsDismissal.shouldShowSuggestion(for: Set(automatic))
        updateTidyTabsPresentation(candidates: automatic, showSuggestion: show)
    }

    public func dismissTidyTabsSuggestion() {
        tidyTabsDismissal.dismiss(candidates: Set(tidyTabsCandidateIDs))
        updateTidyTabsPresentation(candidates: tidyTabsCandidateIDs, showSuggestion: false)
    }

    public func tidyUnusedTabs(manual: Bool = false) {
        let now = Date.now
        let ids = tidyTabCandidates(requiresMinimumCount: !manual, now: now)
        guard !ids.isEmpty, let spaceID = tabs.session.selectedSpaceID else { return }
        let name = TidyTabsArchive.groupName(now: now)
        try? tabs.perform(.createGroupWithTabs(spaceID: spaceID, name: name, tabIDs: ids))
        // Restoring or undoing an archive must not bring the banner straight back.
        tidyTabsDismissal.dismiss(candidates: Set(ids))
        refreshTidyTabs(now: now)
    }

    public func restoreArchivedGroup(_ groupID: UUID) {
        try? tabs.perform(.deleteGroup(id: groupID))
    }

    public func simulateStaleTabsForTidyDemo() {
        tabs.backdateInactiveTabsForTidyDemo(
            spaceID: tabs.session.selectedSpaceID,
            lastActiveAt: .now.addingTimeInterval(-8 * 24 * 3600)
        )
        refreshTidyTabs()
    }

    private func tidyTabCandidates(requiresMinimumCount: Bool, now: Date) -> [UUID] {
        let session = tabs.session
        guard let spaceID = session.selectedSpaceID else { return [] }
        let interval = settings.tidyTabsThreshold.inactivityInterval ?? TidyTabsThreshold.manualFallbackInterval
        let spaceTabs = session.tabs.filter { $0.spaceID == spaceID }
        let playing = Set(tabs.tabs.filter(\.isPlayingAudio).map(\.id))
        let request = TidyTabsPolicy.Request(
            tabs: spaceTabs,
            selectedTabID: tabs.selectedID,
            splitTabIDs: split.visibleTabIDs(primary: tabs.selectedID),
            playingAudioTabIDs: playing,
            inactivityThreshold: interval,
            now: now,
            requiresMinimumCount: requiresMinimumCount
        )
        return TidyTabsPolicy().candidateIDs(for: request)
    }
}
