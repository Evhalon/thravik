import Testing
@testable import RedentEngine

@Suite("Find query changes", .serialized)
@MainActor
struct FindRepaintTests {
    @Test("Typing a longer query replaces the selected short substring")
    func refinedQuerySelectsOnlyCurrentText() async throws {
        let tab = try await FindTestPage.saying("<p>Gemini usage over the time range</p>")
        _ = await tab.findInPage("ge", forward: true)
        #expect(await tab.selectedPageText() == "Ge")
        _ = await tab.findInPage("gemini", forward: true)
        #expect(await tab.selectedPageText() == "Gemini")
        _ = await tab.findInPage("usage", forward: true)
        #expect(await tab.selectedPageText() == "usage")
    }

    @Test("Deleting the query clears native text selection")
    func emptyQueryClearsSelection() async throws {
        let tab = try await FindTestPage.saying("<p>needle</p>")
        _ = await tab.findInPage("needle", forward: true)
        #expect(await tab.findInPage("", forward: true) == .empty)
        let clearedBy = ContinuousClock.now + .seconds(5)
        while await tab.selectedPageText() != nil, ContinuousClock.now < clearedBy {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(await tab.selectedPageText() == nil)
        _ = await tab.findInPage("needle", forward: true)
        #expect(await tab.selectedPageText() == "needle")
        tab.clearFindHighlight()
        let deadline = ContinuousClock.now + .seconds(5)
        while await tab.selectedPageText() != nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(await tab.selectedPageText() == nil)
    }
}
