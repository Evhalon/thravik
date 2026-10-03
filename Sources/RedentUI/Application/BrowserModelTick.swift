import Foundation
import RedentKit

extension BrowserModel {
    /// One timer for the whole window, per AGENTS.md §4 — not one per code.
    public func tick(_ date: Date) {
        otp.tick(date)
        otp.dismissIfPageChanged(selectedTab?.url)
        tabs.sweepHibernation(now: date, keeping: split.visibleTabIDs(primary: tabs.selectedID))
        if let expired = tabs.sweepExpiredTabs(now: date) { expiredTabID = expired }
        refreshTidyTabs(now: date)
        meetings.tick(now: date, isEnabled: settings.showsUpcomingMeetings)
        let origin = selectedTab?.pageTrustIssue == nil ? selectedTab?.origin : nil
        autofill.observe(origin)
        persistIfNeeded(date)
    }
}
