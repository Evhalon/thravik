import AppKit
import Foundation
import Testing
import WebKit
@testable import RedentEngine

/// The page's "Inspect Element": Chrome's DevTools open on Elements with the
/// right-clicked node selected, and Safari's Web Inspector stays shut.
@MainActor
@Suite struct DevToolsInspectElementTests {
    private static var windows: [NSWindow] = []

    @Test func theNodeUnderThePointerIsSelectedInElements() async throws {
        let rows = (0..<40).map { "<section><p>row \($0)</p></section>" }.joined()
        let tab = try await FindTestPage.saying(rows + "<div><div><em id='deep'>deep</em></div></div>")
        let page = try #require(tab.webView)
        let center = "(() => { const e = document.getElementById('deep'); e.scrollIntoView({ block: 'center' });"
            + " const r = e.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; })()"
        let point = try #require(try await page.evaluateJavaScript(center) as? [Double])

        tab.inspectElement(at: CGPoint(x: point[0], y: point[1]))
        let panel = try #require(tab.devToolsPanel)
        defer { tab.closeDevTools() }
        Self.show(panel.frontend)

        let selected = """
        (() => {
          const all = (root, out = []) => { for (const e of root.querySelectorAll('*')) { out.push(e); if (e.shadowRoot) all(e.shadowRoot, out); } return out; };
          const row = all(document).find(e => e.tagName === 'LI' && e.classList.contains('selected') && e.closest('.elements-tree-outline'));
          return row ? row.innerText : '';
        })()
        """
        var text = ""
        let deadline = ContinuousClock.now + .seconds(20)
        while !text.contains("deep"), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
            text = (try? await panel.frontend.evaluateJavaScript(selected) as? String) ?? ""
        }
        #expect(text.contains("deep"))
        let inspector = page.value(forKey: "_inspector") as? NSObject
        #expect((inspector?.value(forKey: "isVisible") as? NSNumber)?.boolValue != true)
    }

    @Test func webKitsOwnItemIsReplacedSoItCannotAlsoOpenSafarisInspector() throws {
        let view = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        var inspected: CGPoint?
        view.onInspectElement = { inspected = $0 }
        let menu = NSMenu()
        let original = NSMenuItem(title: "Inspect Element", action: nil, keyEquivalent: "")
        original.identifier = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierInspectElement")
        menu.addItem(original)
        let event = try #require(NSEvent.mouseEvent(
            with: .rightMouseDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))

        view.willOpenMenu(menu, with: event)
        let item = try #require(menu.items.first)
        #expect(item !== original)
        #expect(item.title == "Inspect Element")
        #expect(item.target === view)
        if let action = item.action { NSApp.sendAction(action, to: item.target, from: item) }
        #expect(inspected != nil)
    }

    @Test func safarisInspectorIsPutAwayWhenWebKitDocksIt() async throws {
        let tab = try await FindTestPage.saying("<p>page</p>")
        let page = try #require(tab.webView)
        let host = WebViewHost(webView: page)
        host.frame = NSRect(x: 0, y: 0, width: 1000, height: 600)
        let window = NSWindow(
            contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFrontRegardless()
        Self.windows.append(window)
        let inspector = try #require(page.value(forKey: "_inspector") as? NSObject)
        defer { inspector.perform(NSSelectorFromString("close")) }

        inspector.perform(NSSelectorFromString("show"))
        inspector.perform(NSSelectorFromString("attach"))
        let deadline = ContinuousClock.now + .seconds(10)
        var isVisible = true
        repeat {
            try await Task.sleep(for: .milliseconds(200))
            isVisible = (inspector.value(forKey: "isVisible") as? NSNumber)?.boolValue ?? false
        } while (isVisible || host.subviews.count > 1) && ContinuousClock.now < deadline
        host.layoutSubtreeIfNeeded()
        #expect(!isVisible)
        #expect(host.subviews == [page])
        #expect(page.frame == host.bounds)
    }

    private static func show(_ view: WKWebView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderFrontRegardless()
        windows.append(window)
    }
}
