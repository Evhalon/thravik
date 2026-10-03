import Foundation
import RedentKit

extension BrowserModel {
    public func joinMeeting(_ url: URL) {
        execute(.newTab(url))
    }

    public func prepareMeeting(_ event: CalendarEvent) {
        let urls = event.prepareURLs
        guard !urls.isEmpty, let spaceID = tabs.session.selectedSpaceID else { return }
        let tabIDs = urls.map { tabs.newTab(url: $0).id }
        let name = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        try? tabs.perform(.createGroupWithTabs(
            spaceID: spaceID,
            name: name.isEmpty ? "Meeting" : name,
            tabIDs: tabIDs
        ))
    }
}
