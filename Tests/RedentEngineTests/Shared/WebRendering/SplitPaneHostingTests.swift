import AppKit
import RedentKit
import SwiftUI
import Testing
import WebKit
@testable import RedentEngine

/// Split View moves a tab's page between SwiftUI hosts. Every page on screen
/// has to end up in its own pane, not parked out of sight — a parked page is
/// a black pane.
@Suite("Split pane hosting")
@MainActor
struct SplitPaneHostingTests {
    @Test("Opening a split keeps the page already on screen in its pane")
    func openingSplitKeepsShownPage() async throws {
        let scene = try SplitScene()
        await scene.settle()
        scene.layout.isSplit = true
        await scene.settle()
        #expect(scene.isOnScreen(scene.first))
        #expect(scene.isOnScreen(scene.second))
    }

    @Test("Leaving a split for its second tab shows that tab")
    func leavingSplitShowsSelection() async throws {
        let scene = try SplitScene()
        scene.layout.isSplit = true
        await scene.settle()
        scene.layout.selected = 1
        scene.layout.isSplit = false
        await scene.settle()
        #expect(scene.isOnScreen(scene.second))
        #expect(!scene.isOnScreen(scene.first))
    }

    @Test("A container already on screen does not take a page from another")
    func onScreenContainerDoesNotSteal() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = NSView(frame: window.contentLayoutRect)
        let outgoing = WebViewContainer(frame: window.contentLayoutRect)
        window.contentView?.addSubview(outgoing)
        let webView = WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), options: PageContentOptions(blocksTrackers: false), contentBlocker: nil
        ))
        outgoing.attach(webView)

        let incoming = WebViewContainer(frame: window.contentLayoutRect)
        incoming.attach(webView)
        outgoing.attach(webView)
        window.contentView?.addSubview(incoming)
        outgoing.removeFromSuperview()

        #expect(webView.superview?.superview === incoming)
        #expect(webView.superview?.isHidden == false)
    }
}

@Observable
@MainActor
private final class PaneLayout {
    var isSplit = false
    var selected = 0
}

/// The shape of the window's page area: one pane, or every tab side by side.
private struct PaneHost: View {
    let layout: PaneLayout
    let controller: TabController
    let tabIDs: [UUID]

    var body: some View {
        if layout.isSplit {
            HStack(spacing: 0) {
                ForEach(tabIDs, id: \.self) { id in
                    BrowserPageView(controller: controller, tabID: id).id(id)
                }
            }
        } else {
            let id = tabIDs[layout.selected]
            BrowserPageView(controller: controller, tabID: id).id(id)
        }
    }
}

@MainActor
private struct SplitScene {
    let layout = PaneLayout()
    let first: WebTab
    let second: WebTab
    private let window: NSWindow

    init() throws {
        let controller = TabController(session: BrowserSession(), settings: BrowserSettings(), logger: QuietLogger())
        let blank = try #require(URL(string: "about:blank"))
        first = try #require(controller.newTab(url: blank) as? WebTab)
        second = try #require(controller.newTab(url: blank) as? WebTab)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = NSHostingView(rootView: PaneHost(
            layout: layout, controller: controller, tabIDs: [first.id, second.id]
        ))
    }

    /// SwiftUI applies an observed change on a later pass, not synchronously.
    func settle() async {
        for _ in 0..<5 {
            window.contentView?.layoutSubtreeIfNeeded()
            try? await Task.sleep(for: .milliseconds(30))
        }
    }

    func isOnScreen(_ tab: WebTab) -> Bool {
        guard let host = tab.webView?.superview else { return false }
        return host.superview is WebViewContainer && !host.isHidden && host.window === window
    }
}

private struct QuietLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
