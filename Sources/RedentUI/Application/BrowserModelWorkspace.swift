import Foundation
import RedentKit

extension BrowserModel {
    func settingsChanged(from old: BrowserSettings) {
        // A sidebar drag writes this on every frame. Encoding and storing the
        // settings that often is what made the drag feel heavy, so the write is
        // coalesced onto the window clock like the workspace itself.
        hasUnsavedSettings = true
        tabs.apply(settings: settings)
        commandBar.searchRouting = settings.searchRouting
        if old.opensFloatingNewTab && !settings.opensFloatingNewTab { dismissFloatingNewTab() }
        if old.offersPasswordSave != settings.offersPasswordSave {
            autofill.setEnabled(settings.offersPasswordSave)
        }
        if old.remembersFormEntries != settings.remembersFormEntries {
            formHistory.setEnabled(settings.remembersFormEntries)
        }
        if !settings.showsTOTPButton {
            otp.fieldDisappeared()
            twoFactor.pageChanged()
        }
        if old.tidyTabsThreshold != settings.tidyTabsThreshold { refreshTidyTabs() }
        if old.showsUpcomingMeetings != settings.showsUpcomingMeetings {
            meetings.setEnabled(settings.showsUpcomingMeetings, now: .now)
        }
        sensitiveHistoryChanged(from: old)
    }

    public func applySyncedWorkspace(_ session: BrowserSession, remote: [RemoteSyncedTab]) {
        guard !tabs.isPrivate else { return }
        if tabs.session != session {
            tabs.importSyncedWorkspace(session)
            split = session.splitLayout
        }
        remoteTabs = remote
        guard hasUnsavedChanges else { return }
        persistSession()
    }

    public func openRemoteTab(_ tab: RemoteSyncedTab) {
        guard let url = tab.url else { return }
        _ = tabs.newTab(url: url)
    }
}
