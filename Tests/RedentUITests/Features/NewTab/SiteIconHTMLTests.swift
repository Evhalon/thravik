import Foundation
import Testing
@testable import RedentUI

@Suite("Homepage icon links")
struct SiteIconHTMLTests {
    @Test("Prefers the large PNG OrdiGO declares over the 48px .ico")
    func prefersDeclaredPNG() {
        let html = """
        <link rel="icon" href="/favicon.ico" sizes="48x48" />
        <link rel="icon" type="image/png" sizes="192x192" href="/favicon-192.png" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        """
        let urls = SiteIconHTML.iconURLs(in: html, host: "ordigo.app").map(\.absoluteString)
        #expect(urls.first == "https://ordigo.app/favicon-192.png")
        #expect(urls.contains("https://ordigo.app/apple-touch-icon.png"))
        #expect(urls.contains("https://ordigo.app/favicon.ico"))
    }

    @Test("Drops off-origin icon hosts")
    func sameOriginOnly() {
        let html = #"<link rel="icon" href="https://cdn.evil.test/steal.png">"#
        #expect(SiteIconHTML.iconURLs(in: html, host: "ordigo.app").isEmpty)
    }
}
