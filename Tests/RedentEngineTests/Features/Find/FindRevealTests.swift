import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Revealing a match scrolls only what the reader could scroll themselves.
@Suite("Find reveal")
@MainActor
struct FindRevealTests {
    /// Regression: typing a short query matched text in an off-canvas menu,
    /// and `scrollIntoView` slid the page's `overflow: hidden` shell over to
    /// it, leaving a blank white page behind.
    @Test("A match in a clipped menu never scrolls the page's hidden shell")
    func clippedMatchLeavesTheShellInPlace() async throws {
        let tab = try await FindTestPage.saying("""
        <div id="shell"><main>Welcome</main><nav id="menu">Settings to run later</nav></div>
        """, head: """
        <style>
        html,body{margin:0;height:100%;overflow:hidden}
        #shell{height:100%;overflow:hidden;position:relative}
        main{height:100%}
        #menu{position:absolute;top:2000px;left:1500px;width:300px}
        </style>
        """)

        _ = await tab.findInPage("to run", forward: true)

        let offset = try await tab.webView?.callAsyncJavaScript(
            "var s = document.getElementById('shell'); return s.scrollTop + s.scrollLeft",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(offset == 0)
    }

    @Test("A match below the fold of a scrolling panel is scrolled into view")
    func scrollablePanelStillReveals() async throws {
        let tab = try await FindTestPage.saying("""
        <div id="panel"><div style="height:3000px"></div><p>needle</p></div>
        """, head: "<style>#panel{height:300px;overflow:auto}</style>")

        _ = await tab.findInPage("needle", forward: true)

        let top = try await tab.webView?.callAsyncJavaScript(
            "return document.getElementById('panel').scrollTop",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect((top ?? 0) > 2000)
    }

    @Test("A match further down an ordinary page scrolls the page to it")
    func ordinaryPageStillScrolls() async throws {
        let tab = try await FindTestPage.saying("<div style=\"height:4000px\"></div><p>needle</p>")

        _ = await tab.findInPage("needle", forward: true)

        let scrolled = try await tab.webView?.callAsyncJavaScript(
            "return window.scrollY", in: nil, contentWorld: PageScripts.contentWorld
        ) as? Double
        #expect((scrolled ?? 0) > 3000)
    }

    @Test("A match clipped by a small panel is revealed even inside the page viewport")
    func revealsNestedClippingInsideViewport() async throws {
        let tab = try await FindTestPage.saying("""
        <div id="panel"><div style="height:180px"></div><p>needle</p></div>
        """, head: "<style>#panel{height:100px;overflow:auto}</style>")
        _ = await tab.findInPage("needle", forward: true)
        let top = try await tab.webView?.callAsyncJavaScript(
            "return document.getElementById('panel').scrollTop",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect((top ?? 0) > 0)
    }

    @Test("A horizontal scrolling panel reveals a match past its right edge")
    func revealsHorizontalPanel() async throws {
        let tab = try await FindTestPage.saying("""
        <div id="panel"><div style="width:1600px"><span style="margin-left:1400px">needle</span></div></div>
        """, head: "<style>#panel{width:200px;overflow:auto;white-space:nowrap}</style>")
        _ = await tab.findInPage("needle", forward: true)
        let left = try await tab.webView?.callAsyncJavaScript(
            "return document.getElementById('panel').scrollLeft",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect((left ?? 0) > 1000)
    }


    @Test("A scrolling text container can reveal its own text nodes")
    func revealsDirectTextInsideScrollingParent() async throws {
        let lines = String(repeating: "line\n", count: 100)
        let tab = try await FindTestPage.saying(
            "<div id=panel>\(lines)needle</div>",
            head: "<style>#panel{height:100px;overflow:auto;white-space:pre}</style>"
        )
        _ = await tab.findInPage("needle", forward: true)
        let top = try await tab.webView?.callAsyncJavaScript(
            "return document.getElementById('panel').scrollTop",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect((top ?? 0) > 1000)
    }

}
