import Testing
@testable import RedentEngine

@Suite("Native find in form fields", .serialized)
@MainActor
struct FindControlTests {
    @Test("Native find selects the query within a field")
    func selectsSubstringInField() async throws {
        let tab = try await FindTestPage.saying("<input id=field value='prefix needle suffix'>")
        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        let selected = try await tab.webView?.callAsyncJavaScript(
            "const f = document.getElementById('field'); return f.value.slice(f.selectionStart, f.selectionEnd);",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        #expect(selected == "needle")
        let marked = try await tab.webView?.callAsyncJavaScript(
            "return document.getElementById('field').className",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        #expect(marked == "")
    }

    @Test("Native find reaches a textarea value without selecting all its text")
    func findsTextAreaSubstring() async throws {
        let tab = try await FindTestPage.saying("<textarea id=field>prefix needle suffix</textarea>")
        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        let selected = try await tab.webView?.callAsyncJavaScript(
            "const f = document.getElementById('field'); return f.value.slice(f.selectionStart, f.selectionEnd);",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        #expect(selected == "needle")
    }

    @Test("Closing find removes a native field selection")
    func clearsFieldSelection() async throws {
        let tab = try await FindTestPage.saying("<input id=field value='prefix needle suffix'>")
        _ = await tab.findInPage("needle", forward: true)
        tab.clearFindHighlight()
        let script = "const f = document.getElementById('field'); return f.selectionEnd - f.selectionStart;"
        let deadline = ContinuousClock.now + .seconds(5)
        var length: Int?
        repeat {
            try await Task.sleep(for: .milliseconds(20))
            length = try await tab.webView?.callAsyncJavaScript(
                script, in: nil, contentWorld: PageScripts.contentWorld
            ) as? Int
        } while length != 0 && ContinuousClock.now < deadline
        #expect(length == 0)
    }
}
