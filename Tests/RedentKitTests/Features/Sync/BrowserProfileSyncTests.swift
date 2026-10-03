import Foundation
import Testing
@testable import RedentKit

struct BrowserProfileSyncTests {
    @Test func profileRoundTripsAndOlderSessionsDecodeWithoutOne() throws {
        let profile = BrowserProfile(displayName: "Mira", purpose: "Research")
        let encoded = try JSONEncoder().encode(BrowserSession(profile: profile))
        let restored = try JSONDecoder().decode(BrowserSession.self, from: encoded)
        #expect(restored.profile == profile)

        let olderSession = try JSONEncoder().encode(BrowserSession())
        let olderObject = try #require(JSONSerialization.jsonObject(with: olderSession) as? [String: Any])
        var withoutProfile = olderObject
        withoutProfile.removeValue(forKey: "profile")
        let olderData = try JSONSerialization.data(withJSONObject: withoutProfile)
        #expect(try JSONDecoder().decode(BrowserSession.self, from: olderData).profile == nil)
    }

    @Test func catalogCarriesProfileAndMergePrefersRemoteWithLocalFallback() throws {
        let localProfile = BrowserProfile(displayName: "Personal", purpose: "Everyday")
        let remoteProfile = BrowserProfile(displayName: "Studio", purpose: "Design")
        let catalog = SyncSpaceCatalog(session: BrowserSession(profile: remoteProfile))
        #expect(catalog.profile == remoteProfile)
        let encodedCatalog = try JSONEncoder().encode(catalog)
        #expect(try JSONDecoder().decode(SyncSpaceCatalog.self, from: encodedCatalog) == catalog)

        let catalogObject = try #require(JSONSerialization.jsonObject(with: encodedCatalog) as? [String: Any])
        var olderCatalog = catalogObject
        olderCatalog.removeValue(forKey: "profile")
        let olderCatalogData = try JSONSerialization.data(withJSONObject: olderCatalog)
        #expect(try JSONDecoder().decode(SyncSpaceCatalog.self, from: olderCatalogData).profile == nil)

        let remoteSnapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [], localDeviceID: UUID())
        #expect(WorkspaceSyncMerge.apply(local: BrowserSession(profile: localProfile), snapshot: remoteSnapshot)
            .session.profile == remoteProfile)

        var profilelessCatalog = catalog
        profilelessCatalog.profile = nil
        let fallbackSnapshot = WorkspaceSyncSnapshot(catalog: profilelessCatalog, deviceTabs: [], localDeviceID: UUID())
        #expect(WorkspaceSyncMerge.apply(local: BrowserSession(profile: localProfile), snapshot: fallbackSnapshot)
            .session.profile == localProfile)
    }

    @Test func tabUndoPreservesCurrentProfile() {
        let currentProfile = BrowserProfile(displayName: "Current", purpose: "Browsing")
        let previousProfile = BrowserProfile(displayName: "Previous", purpose: "Earlier")
        let current = BrowserSession(profile: currentProfile)
        let previous = BrowserSession(profile: previousProfile)

        let restored = SessionRewind.rewind(current, to: previous, scope: .tabs)

        #expect(restored.profile == currentProfile)
    }
}
