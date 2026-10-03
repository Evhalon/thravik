import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Recently closed intents")
struct RecentlyClosedIntentTests {
    private let docs = RecentlyClosedEntry(
        id: UUID(), title: "Swift Docs", host: "swift.org", faviconData: nil, closedAt: .now, kind: .tab
    )
    private let batch = RecentlyClosedEntry(
        id: UUID(), title: "Research", host: nil, faviconData: nil, closedAt: .now, kind: .group(tabCount: 3)
    )

    private var fixture: CommandFixture {
        var fixture = CommandFixture()
        fixture.context.recentlyClosed = [docs, batch]
        return fixture
    }

    @Test("“closed” lists every entry, newest first")
    func listsAll() {
        #expect(fixture.intents("closed") == [.reopenClosed(docs.id), .reopenClosed(batch.id)])
        #expect(fixture.intents("recently closed tabs") == [.reopenClosed(docs.id), .reopenClosed(batch.id)])
    }

    @Test("Words after the key narrow by title or host")
    func narrows() {
        #expect(fixture.intents("closed research") == [.reopenClosed(batch.id)])
        #expect(fixture.intents("recently closed swift.org") == [.reopenClosed(docs.id)])
    }

    @Test("A search that merely contains “closed” is not hijacked")
    func ignoresIncidentalWord() {
        #expect(!fixture.intents("enclosed spaces").contains(.reopenClosed(docs.id)))
        #expect(!fixture.intents("why is the store closed").contains(.reopenClosed(docs.id)))
    }

    @Test("Menu rows read as one native title")
    func menuTitles() {
        #expect(RecentlyClosedMenuItems.title(docs) == "Swift Docs — swift.org")
        #expect(RecentlyClosedMenuItems.title(batch) == "Research — 3 tabs")
    }

    @Test("Nothing is offered when the stack is empty")
    func emptyStack() {
        #expect(CommandFixture().intents("closed").isEmpty)
    }
}
