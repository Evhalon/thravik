import Foundation
import Testing
@testable import RedentKit

@Suite("Sync tab emoji")
struct SyncTabSnapshotEmojiTests {
    @Test("A chosen emoji travels with the portable tab DTO")
    func portableTabKeepsEmoji() throws {
        var tab = TabSnapshot(url: URL(string: "https://example.com/mail"), title: "Mail")
        tab.customEmoji = "📬"
        let sync = try #require(SyncTabSnapshot(tab: tab))
        #expect(sync.customEmoji == "📬")
        let decoded = try JSONDecoder().decode(SyncTabSnapshot.self, from: JSONEncoder().encode(sync))
        #expect(decoded.customEmoji == "📬")
    }

    @Test("Older peers that omit customEmoji still decode")
    func legacyPayloadOmitsEmoji() throws {
        var tab = TabSnapshot(url: URL(string: "https://example.com/mail"), title: "Mail")
        tab.customEmoji = "📬"
        let sync = try #require(SyncTabSnapshot(tab: tab))
        let encoded = try JSONEncoder().encode(sync)
        var values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        values.removeValue(forKey: "customEmoji")
        let data = try JSONSerialization.data(withJSONObject: values)
        let decoded = try JSONDecoder().decode(SyncTabSnapshot.self, from: data)
        #expect(decoded.customEmoji == nil)
        #expect(decoded.title == "Mail")
    }

    @Test("A newly shared pin keeps its emoji")
    func mergedPinKeepsEmoji() throws {
        let pinID = UUID()
        let spaceID = BrowserSpace.workID
        var pin = TabSnapshot(id: pinID, url: URL(string: "https://pin.example"), title: "Pin",
                              isPinned: true, spaceID: spaceID)
        pin.customEmoji = "📌"
        let catalog = SyncSpaceCatalog(session: BrowserSession(
            tabs: [pin], selectedTabID: pinID, selectedSpaceID: spaceID))
        let snapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [], localDeviceID: UUID())
        let applied = WorkspaceSyncMerge.apply(local: BrowserSession(), snapshot: snapshot)
        #expect(applied.session.tabs.contains { $0.id == pinID && $0.customEmoji == "📌" })
    }

    @Test("No emoji leaves the encoded payload without the key, so digests stay stable")
    func nilEmojiOmitsKey() throws {
        let tab = TabSnapshot(url: URL(string: "https://example.com"), title: "Plain")
        let encoded = try JSONEncoder().encode(try #require(SyncTabSnapshot(tab: tab)))
        let values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(values["customEmoji"] == nil)
    }

    @Test("A pre-emoji schema decodes a new payload by ignoring the key")
    func oldSchemaIgnoresEmoji() throws {
        var tab = TabSnapshot(url: URL(string: "https://example.com"), title: "Mail")
        tab.customEmoji = "📬"
        let encoded = try JSONEncoder().encode(try #require(SyncTabSnapshot(tab: tab)))
        let legacy = try JSONDecoder().decode(LegacySyncTab.self, from: encoded)
        #expect(legacy.title == "Mail")
    }

    @Test("A remote catalog never overwrites a local pin's emoji")
    func localPinEmojiWins() throws {
        var local = TabSnapshot(url: URL(string: "https://pin.example"), title: "Pin", isPinned: true,
                                spaceID: BrowserSpace.workID)
        local.customEmoji = "🏠"
        var remote = local
        remote.customEmoji = "🚀"
        let catalog = SyncSpaceCatalog(session: BrowserSession(tabs: [remote], selectedTabID: remote.id))
        let snapshot = WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: [], localDeviceID: UUID())
        let applied = WorkspaceSyncMerge.apply(
            local: BrowserSession(tabs: [local], selectedTabID: local.id), snapshot: snapshot)
        #expect(applied.session.tabs.first { $0.id == local.id }?.customEmoji == "🏠")
    }

    @Test("A hostile remote emoji is dropped when a pin is created")
    func invalidRemoteEmojiDropped() throws {
        let pin = TabSnapshot(url: URL(string: "https://pin.example"), title: "Pin", isPinned: true,
                              spaceID: BrowserSpace.workID)
        let catalog = SyncSpaceCatalog(session: BrowserSession(tabs: [pin], selectedTabID: pin.id))
        var data = try JSONEncoder().encode(catalog)
        let hostile = "🔥" + String(repeating: "\u{0336}", count: 500)
        let text = try #require(String(data: data, encoding: .utf8))
        data = Data(text.replacingOccurrences(of: "\"title\":\"Pin\"",
                                              with: "\"title\":\"Pin\",\"customEmoji\":\"\(hostile)\"").utf8)
        let decoded = try JSONDecoder().decode(SyncSpaceCatalog.self, from: data)
        #expect(decoded.pins.first?.customEmoji == hostile)
        let snapshot = WorkspaceSyncSnapshot(catalog: decoded, deviceTabs: [], localDeviceID: UUID())
        let applied = WorkspaceSyncMerge.apply(local: BrowserSession(), snapshot: snapshot)
        #expect(applied.session.tabs.contains { $0.id == pin.id && $0.customEmoji == nil })
    }
}

private struct LegacySyncTab: Decodable {
    let id: UUID
    let url: URL?
    let title: String
    let isPinned: Bool
    let customTitle: String?
    let zoom: Double
}
