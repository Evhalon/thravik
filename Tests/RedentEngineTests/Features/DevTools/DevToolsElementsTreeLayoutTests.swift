import AppKit
import Foundation
import Testing
import WebKit
@testable import RedentEngine

/// With Styles docked beside it, WebKit left the Elements tree's
/// `height: 100%` unresolved: the tree grew to its full length, never
/// scrolled, and a node picked on the page stayed out of sight.
@MainActor
@Suite struct DevToolsElementsTreeLayoutTests {
    private static var windows: [NSWindow] = []

    @Test func theTreeScrollsWithinItsPaneAndRevealsAPickedNode() async throws {
        let rows = (0..<80).map { "<section><p>row \($0)</p></section>" }.joined()
        let tab = try await FindTestPage.saying(rows + "<div><div><em id='deep'>deep</em></div></div>")
        let page = try #require(tab.webView)
        let pathToDeep = """
        (() => { const path = []; for (let n = document.getElementById('deep'); n !== document.documentElement; n = n.parentElement)
          path.unshift([...n.parentElement.children].indexOf(n)); return path; })()
        """
        let path = try #require(try await page.evaluateJavaScript(pathToDeep) as? [Int])
        let panel = try #require(DevToolsPanel(inspecting: page, panel: "elements"))
        defer { panel.close() }
        panel.frontend.configuration.userContentController.addUserScript(Self.stylesBesideTree)
        Self.show(panel.frontend)
        panel.open()
        panel.inspect(path: path)

        var layout: [String: Double] = [:]
        let deadline = ContinuousClock.now + .seconds(20)
        while layout["selectedTop"] == nil || layout["scrollTop"] == 0, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
            layout = (try? await panel.frontend.evaluateJavaScript(Self.treeLayout) as? [String: Double]) ?? [:]
        }
        let tree = try #require(layout["height"])
        #expect(tree <= layout["paneHeight"] ?? 0)
        #expect(layout["contentHeight"] ?? 0 > tree)
        let selectedTop = try #require(layout["selectedTop"])
        #expect(selectedTop >= layout["top"] ?? 0 && selectedTop < (layout["top"] ?? 0) + tree)
    }

    private static let stylesBesideTree = WKUserScript(
        source: #"localStorage.setItem("sidebar-position", JSON.stringify("right"));"#,
        injectionTime: .atDocumentStart, forMainFrameOnly: true
    )

    private static let treeLayout = """
    (() => {
      const tree = document.getElementById('elements-content');
      if (!tree) return null;
      const box = tree.getBoundingClientRect();
      const all = (root, out = []) => { for (const e of root.querySelectorAll('*')) { out.push(e); if (e.shadowRoot) all(e.shadowRoot, out); } return out; };
      const row = all(tree).find(e => e.tagName === 'LI' && e.classList.contains('selected'));
      const out = { top: box.top, height: box.height, contentHeight: tree.scrollHeight,
        scrollTop: tree.scrollTop, paneHeight: tree.parentElement.clientHeight };
      if (row && row.innerText.includes('deep')) out.selectedTop = row.getBoundingClientRect().top;
      return out;
    })()
    """

    private static func show(_ view: WKWebView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 900),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderFrontRegardless()
        windows.append(window)
    }
}
