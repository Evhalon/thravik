import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Find reaches every piece of text the reader can see, however the page built
/// it: search result cards lean on web components, `display: contents`, and
/// aria-hidden copies of visible headings.
@Suite("Find reach")
@MainActor
struct FindReachTests {
    @Test("Rendered text counts even when aria-hidden, transparent, or display: contents")
    func findsRenderedTextTheAccessibilityTreeSkips() async throws {
        let tab = try await FindTestPage.saying("""
        <p>Xiao light</p>
        <div aria-hidden="true">Xiao aria</div>
        <div style="display:contents">Xiao contents</div>
        <div style="opacity:0">Xiao transparent</div>
        <div style="display:none">Xiao gone</div>
        """)

        #expect(await tab.findInPage("xiao", forward: true) == FindMatches(total: 4, current: 1))
    }

    @Test("Text inside open shadow roots and their slots is found")
    func findsTextInsideWebComponents() async throws {
        let tab = try await FindTestPage.saying("""
        <x-card><span slot="title">Xiao slotted</span></x-card>
        <script>
        customElements.define('x-card', class extends HTMLElement {
          constructor() {
            super();
            this.attachShadow({ mode: 'open' }).innerHTML =
              '<h3><slot name="title"></slot></h3><p>Xiao shadow</p><input value="Xiao field">';
          }
        });
        </script>
        """)

        #expect(await tab.findInPage("xiao", forward: true) == FindMatches(total: 3, current: 1))
    }
}
