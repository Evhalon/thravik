import Foundation
import Testing
@testable import RedentKit

@Suite("Tab custom emoji")
struct TabCustomEmojiTests {
    @Test("Presentation emoji, flags, ZWJ, skin tones and keycaps pass")
    func acceptsEmojiGraphemes() {
        #expect(TabCustomEmoji.validated("🔥") == "🔥")
        #expect(TabCustomEmoji.validated("  🎉  ") == "🎉")
        #expect(TabCustomEmoji.validated("🇺🇸") == "🇺🇸")
        #expect(TabCustomEmoji.validated("🏴󠁧󠁢󠁥󠁮󠁧󠁿") == "🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        #expect(TabCustomEmoji.validated("👨‍👩‍👧‍👦") == "👨‍👩‍👧‍👦")
        #expect(TabCustomEmoji.validated("👋🏻") == "👋🏻")
        #expect(TabCustomEmoji.validated("1️⃣") == "1️⃣")
        #expect(TabCustomEmoji.validated("☺️") == "☺️")
        #expect(TabCustomEmoji.validated("©️") == "©️")
    }

    @Test("Letters, digits, blank and multiple clusters fail")
    func rejectsNonEmoji() {
        #expect(TabCustomEmoji.validated(nil) == nil)
        #expect(TabCustomEmoji.validated("") == nil)
        #expect(TabCustomEmoji.validated("   ") == nil)
        #expect(TabCustomEmoji.validated("A") == nil)
        #expect(TabCustomEmoji.validated("ab") == nil)
        #expect(TabCustomEmoji.validated("1") == nil)
        #expect(TabCustomEmoji.validated("#") == nil)
        #expect(TabCustomEmoji.validated("©") == nil)
        #expect(TabCustomEmoji.validated("🎉🔥") == nil)
        #expect(TabCustomEmoji.validated("hello") == nil)
    }

    @Test("Heart needs VS16; long kiss sequence still fits the bound")
    func heartAndLongSequences() {
        #expect(TabCustomEmoji.validated("❤️") == "❤️")
        #expect(TabCustomEmoji.validated("\u{2764}") == nil)
        #expect(TabCustomEmoji.validated("👩🏽‍❤️‍💋‍👨🏿") == "👩🏽‍❤️‍💋‍👨🏿")
        #expect(TabCustomEmoji.validated("#️⃣") == "#️⃣")
    }

    @Test("Combining marks glued onto an emoji are rejected, however many")
    func rejectsZalgoAndOversizedClusters() {
        #expect(TabCustomEmoji.validated("🔥\u{0301}") == nil)
        #expect(TabCustomEmoji.validated("🔥" + String(repeating: "\u{0336}", count: 5_000)) == nil)
        let zwjChain = Array(repeating: "🔥", count: 20).joined(separator: "\u{200D}")
        #expect(TabCustomEmoji.validated(zwjChain) == nil)
    }

    @Test("A text-presentation variant is not an icon")
    func rejectsTextPresentation() {
        let textSmile = "\u{263A}\u{FE0E}"
        #expect(TabCustomEmoji.validated(textSmile) == nil)
    }

    @Test("The reducer stores a valid emoji and ignores junk")
    func workspaceAction() throws {
        let tab = TabSnapshot(title: "Mail")
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.setCustomEmoji(id: tab.id, emoji: "  📬  "))
        #expect(state.session.tabs.first?.customEmoji == "📬")
        try state.apply(.setCustomEmoji(id: tab.id, emoji: "nope"))
        #expect(state.session.tabs.first?.customEmoji == "📬")
        try state.apply(.setCustomEmoji(id: tab.id, emoji: nil))
        #expect(state.session.tabs.first?.customEmoji == nil)
    }

    @Test("A missing tab cannot take an emoji")
    func missingTab() {
        var state = WorkspaceState()
        #expect(throws: WorkspaceActionError.self) {
            try state.apply(.setCustomEmoji(id: UUID(), emoji: "🔥"))
        }
    }
}
