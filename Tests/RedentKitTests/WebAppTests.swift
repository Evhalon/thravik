import Foundation
import RedentKit
import Testing

@Suite("Web apps")
struct WebAppTests {
    @Test("An app takes the brand its page title already carries, and the site's root")
    func brandFromTitle() throws {
        let page = try #require(URL(string: "https://github.com/acme/onepanel/pull/182"))
        let app = try #require(WebApp(page: page, title: "Pull request #182 — OnePanel — GitHub",
                                      faviconData: nil, spaceID: nil))
        #expect(app.name == "GitHub")
        #expect(app.url == URL(string: "https://github.com/"))
    }

    @Test("With no brand in the title, the site names itself")
    func fallbackName() throws {
        let page = try #require(URL(string: "https://www.example.com/docs"))
        let app = try #require(WebApp(page: page, title: "Getting started", faviconData: nil, spaceID: nil))
        #expect(app.name == "Example")
    }

    @Test("Only web pages can become apps")
    func onlyWebPages() throws {
        let file = try #require(URL(string: "file:///Users/me/notes.html"))
        #expect(WebApp(page: file, title: "Notes", faviconData: nil, spaceID: nil) == nil)
    }

    @Test("The same host is the same app; a sibling subdomain is not")
    func sameSite() throws {
        let app = WebApp(name: "Gmail", url: try #require(URL(string: "https://mail.google.com/")))
        #expect(app.isSameSite(as: try #require(URL(string: "https://mail.google.com/mail/u/0"))))
        #expect(!app.isSameSite(as: try #require(URL(string: "https://docs.google.com/"))))
    }
}
