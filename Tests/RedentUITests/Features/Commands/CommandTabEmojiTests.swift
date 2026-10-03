import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Command bar tab emoji")
struct CommandTabEmojiTests {
    @Test("A tab row carries the chosen emoji to the favicon")
    func tabRowCarriesEmoji() {
        var values = CommandTabContext.Values(url: URL(string: "https://mail.example"))
        values.customEmoji = "📬"
        let tab = CommandTabContext(id: UUID(), title: "Mail", values: values)
        let row = CommandEntityRows.tabRow(tab)
        #expect(row.customEmoji == "📬")
        #expect(row.faviconHost == "mail.example")
    }
}
