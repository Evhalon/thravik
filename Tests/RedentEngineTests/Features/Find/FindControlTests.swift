import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Find form values")
@MainActor
struct FindControlTests {
    @Test("Each occurrence in a field has its own active selection")
    func selectsTheActualOccurrenceWithoutFocusing() async throws {
        let tab = try await FindTestPage.saying("<input id=field value='needle needle'><input value='needle'>")
        let view = try #require(tab.webView)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 1))
        #expect(try await selectionStart(in: tab) == 0)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 2))
        #expect(try await selectionStart(in: tab) == 7)
        let focused = try await view.evaluateJavaScript("document.activeElement.id") as? String
        #expect(focused != "field")
    }

    @Test("Script changes to field values are included on the next command")
    func rescansLiveControlValues() async throws {
        let tab = try await FindTestPage.saying("<input value='needle'>")
        let view = try #require(tab.webView)
        #expect(await tab.findInPage("needle", forward: true).total == 1)
        _ = try await view.evaluateJavaScript("document.querySelector('input').value = 'needle needle'")
        #expect(await tab.findInPage("needle", forward: true).total == 2)
    }

    @Test("Hidden and password values are excluded")
    func excludesUnsearchableControlValues() async throws {
        let tab = try await FindTestPage.saying("""
        <input type=password value=needle><input type=hidden value=needle>
        <textarea>needle visible</textarea><select><option>needle visible</option><option>needle hidden</option></select>
        """)
        #expect(await tab.findInPage("needle", forward: true).total == 2)
    }

    @Test("Closing find restores the field's original selection")
    func restoresSelectionOnClose() async throws {
        let tab = try await FindTestPage.saying("<input id=field value='needle needle'>")
        let view = try #require(tab.webView)
        _ = try await view.evaluateJavaScript("document.getElementById('field').setSelectionRange(2, 4)")
        _ = await tab.findInPage("needle", forward: true)
        tab.clearFindHighlight()
        try await Task.sleep(for: .milliseconds(50))
        #expect(try await selectionStart(in: tab) == 2)
    }

    @Test("Closing find preserves a selection the reader changed during the session")
    func preservesSelectionChangedDuringFind() async throws {
        let tab = try await FindTestPage.saying("<input id=field value='needle needle'>")
        let view = try #require(tab.webView)
        _ = await tab.findInPage("needle", forward: true)
        _ = try await view.evaluateJavaScript("document.getElementById('field').setSelectionRange(9, 11)")
        tab.clearFindHighlight()
        try await Task.sleep(for: .milliseconds(50))
        #expect(try await selectionStart(in: tab) == 9)
    }

    private func selectionStart(in tab: WebTab) async throws -> Int {
        let view = try #require(tab.webView)
        let value = try await view.evaluateJavaScript("document.getElementById('field').selectionStart")
        return value as? Int ?? -1
    }
}
