import Foundation
import Testing
@testable import RedentKit

@Suite("Tab snapshot emoji coding")
struct TabSnapshotEmojiCodingTests {
    @Test("A snapshot saved before customEmoji still decodes")
    func legacySnapshotOmitsEmoji() throws {
        let tab = TabSnapshot(title: "Old")
        let encoded = try JSONEncoder().encode(tab)
        var values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        values.removeValue(forKey: "customEmoji")
        let data = try JSONSerialization.data(withJSONObject: values)
        let decoded = try JSONDecoder().decode(TabSnapshot.self, from: data)
        #expect(decoded.title == "Old")
        #expect(decoded.customEmoji == nil)
    }

    @Test("A chosen emoji survives encode and decode")
    func emojiRoundTrips() throws {
        var tab = TabSnapshot(title: "Mail")
        tab.customEmoji = "📬"
        let decoded = try JSONDecoder().decode(TabSnapshot.self, from: JSONEncoder().encode(tab))
        #expect(decoded.customEmoji == "📬")
    }

    @Test("Junk stored under customEmoji is dropped")
    func invalidStoredEmojiDropped() throws {
        var tab = TabSnapshot(title: "Mail")
        tab.customEmoji = "📬"
        let encoded = try JSONEncoder().encode(tab)
        var values = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        values["customEmoji"] = "not-emoji"
        let data = try JSONSerialization.data(withJSONObject: values)
        let decoded = try JSONDecoder().decode(TabSnapshot.self, from: data)
        #expect(decoded.customEmoji == nil)
    }
}
