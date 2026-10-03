import Foundation
import Testing
@testable import RedentKit

struct WorkspaceSyncMergeTests {
    @Test func addsSharedSpaceAndPinWithoutOpeningAnotherMacsTabs() throws {
        let localDevice = UUID(uuid: (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
        let otherDevice = UUID(uuid: (2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
        let clientID = UUID(uuid: (3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3))
        let pinID = UUID(uuid: (4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4))
        var client = BrowserSpace(id: clientID, name: "Client")
        client.icon = "star.fill"
        client.colorToken = "amber"
        let localURL = try #require(URL(string: "https://local.example/a"))
        let pinURL = try #require(URL(string: "https://pin.example/b"))
        let remoteURL = try #require(URL(string: "https://other.example/c?token=secret"))
        var localTab = TabSnapshot(url: localURL, title: "Local")
        localTab.spaceID = BrowserSpace.workID
        let local = BrowserSession(tabs: [localTab], selectedTabID: localTab.id)
        let pin = TabSnapshot(id: pinID, url: pinURL, title: "Pin", isPinned: true, spaceID: clientID)
        let catalog = SyncSpaceCatalog(session: BrowserSession(
            tabs: [pin], selectedTabID: pin.id, spaces: [client], selectedSpaceID: clientID))
        let other = SyncDeviceTabs(session: BrowserSession(tabs: [TabSnapshot(url: remoteURL, title: "Other")]),
                                   deviceID: otherDevice)
        let snapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [other], localDeviceID: localDevice)
        let application = WorkspaceSyncMerge.apply(local: local, snapshot: snapshot)

        #expect(application.session.tabs.contains { $0.id == localTab.id })
        #expect(application.session.selectedTabID == localTab.id)
        #expect(application.session.spaces.contains { $0.id == clientID && $0.name == "Client" && $0.icon == "star.fill" })
        #expect(application.session.tabs.contains { $0.id == pinID && $0.isPinned })
        #expect(application.session.tabs.allSatisfy { $0.title != "Other" })
        #expect(application.remoteTabs.map(\.title) == ["Other"])
        #expect(application.remoteTabs.first?.url?.query == nil)
    }

    @Test func retiredSpaceMovesItsTabsInsteadOfDroppingThem() throws {
        let retiredID = UUID(uuid: (5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5))
        let url = try #require(URL(string: "https://kept.example/page"))
        var retired = BrowserSpace(id: retiredID, name: "Old")
        var tab = TabSnapshot(url: url, title: "Kept")
        tab.spaceID = retiredID
        let local = BrowserSession(tabs: [tab], spaces: BrowserSpace.starterSpaces + [retired], selectedSpaceID: retiredID)
        var catalog = SyncSpaceCatalog(session: BrowserSession())
        catalog.retiredSpaceIDs = [retiredID]
        let snapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [], localDeviceID: UUID())
        let application = WorkspaceSyncMerge.apply(local: local, snapshot: snapshot)

        #expect(application.session.spaces.contains { $0.id == retiredID } == false)
        #expect(application.session.tabs.contains { $0.id == tab.id && $0.spaceID == BrowserSpace.workID })
    }

    @Test func firstAccountCatalogPreservesLocalPinnedTabsAndSelection() throws {
        let url = try #require(URL(string: "https://example.com/pinned"))
        let pin = TabSnapshot(url: url, title: "My pin", isPinned: true, spaceID: BrowserSpace.workID)
        let local = BrowserSession(tabs: [pin], selectedTabID: pin.id, selectedSpaceID: BrowserSpace.workID)
        let catalog = SyncSpaceCatalog(session: BrowserSession())
        let snapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [], localDeviceID: UUID())

        let applied = WorkspaceSyncMerge.apply(local: local, snapshot: snapshot).session

        #expect(applied.tabs.contains { $0.id == pin.id && $0.isPinned && $0.url == url })
        #expect(applied.selectedSpaceID == local.selectedSpaceID)
        #expect(applied.selectedTabID == pin.id)
        #expect(SidebarOutline(tabs: applied.tabs, groups: applied.groups,
                               spaceID: BrowserSpace.workID).pinnedIDs == [pin.id])
    }

    @Test func deviceTabsOmitPinsAndTemporaryTabs() throws {
        let url = try #require(URL(string: "https://example.com/path?q=1"))
        let normal = TabSnapshot(url: url, title: "Open")
        let pin = TabSnapshot(url: url, title: "Pinned", isPinned: true)
        let temporary = TabSnapshot(url: url, expiresAt: .distantFuture)
        let device = UUID(uuid: (6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6))
        let tabs = SyncDeviceTabs(session: BrowserSession(tabs: [normal, pin, temporary]), deviceID: device)
        #expect(tabs.tabs.map(\.title) == ["Open"])
        #expect(tabs.tabs.first?.url?.query == nil)
    }
}
