import Foundation
import Testing
@testable import RedentKit

@Suite("Shortcut settings decoding")
struct ShortcutSettingsDecodingTests {
    @Test("Older JSON without bindings keeps today's menu shortcuts")
    func legacyJSONUsesDefaults() throws {
        let legacy = Data(#"{"tabLayout":"top","sidebarWidth":310,"blocksTrackers":false}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(settings.shortcutBindings.overrides.isEmpty)
        #expect(settings.shortcutBindings.chord(for: .newTab) == .command("t"))
        #expect(settings.shortcutBindings.chord(for: .closeTab) == .command("w"))
        #expect(settings.shortcutBindings.chord(for: .reopenClosedTab) == KeyChord(
            key: "t", modifiers: [.command, .shift]
        ))
        #expect(settings.tabLayout == .top)
    }

    @Test("A damaged key map falls back to defaults and keeps other settings")
    func damagedBindingsKeepSettings() throws {
        let json = Data(#"{"tabLayout":"top","shortcutBindings":{"newTab":{"key":7}}}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: json)
        #expect(settings.tabLayout == .top)
        #expect(settings.shortcutBindings.overrides.isEmpty)
    }

    @Test("A cleared shortcut survives a save")
    func clearedShortcutPersists() throws {
        var settings = BrowserSettings()
        #expect(settings.shortcutBindings.setChord(nil, for: .newTab) == .applied)
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.shortcutBindings.chord(for: .newTab) == nil)
        #expect(restored.shortcutBindings.chord(for: .closeTab) == .command("w"))
    }
}
