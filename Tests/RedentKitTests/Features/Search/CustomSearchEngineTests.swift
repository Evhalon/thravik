import Foundation
import Testing
@testable import RedentKit

@Suite("Custom search engines")
struct CustomSearchEngineTests {
    @Test("Template must be http(s) with exactly one %s")
    func templateValidation() throws {
        #expect(throws: CustomSearchEngineError.missingQueryPlaceholder) {
            try CustomSearchTemplate.validated("https://example.com/search?q=").get()
        }
        #expect(throws: CustomSearchEngineError.missingQueryPlaceholder) {
            try CustomSearchTemplate.validated("https://example.com/%s/%s").get()
        }
        #expect(throws: CustomSearchEngineError.invalidTemplate) {
            try CustomSearchTemplate.validated("ftp://example.com/?q=%s").get()
        }
        #expect(throws: CustomSearchEngineError.invalidTemplate) {
            try CustomSearchTemplate.validated("not a url %s").get()
        }
        #expect(throws: CustomSearchEngineError.invalidTemplate) {
            try CustomSearchTemplate.validated("javascript://example.com/%0Aalert(%s)").get()
        }
        let valid = try CustomSearchTemplate.validated(
            "https://www.youtube.com/results?search_query=%s"
        ).get()
        #expect(valid == "https://www.youtube.com/results?search_query=%s")
    }

    @Test("Query substitution escapes reserved characters")
    func urlBuildingEscapes() throws {
        let url = try #require(CustomSearchTemplate.url(
            from: "https://example.com/search?q=%s",
            query: "a&b=c?d#e"
        ))
        let query = try #require(url.query())
        #expect(query.hasPrefix("q="))
        #expect(!query.dropFirst(2).contains("&"))
        #expect(!query.contains("#"))
        #expect(url.absoluteString.contains("%26"))
        let unicode = try #require(CustomSearchTemplate.url(from: "https://example.com/?q=%s", query: "100% café"))
        #expect(unicode.absoluteString == "https://example.com/?q=100%25%20caf%C3%A9")
    }

    @Test("Draft rejects empty names, bad keywords, and duplicates")
    func draftValidation() throws {
        #expect(throws: CustomSearchEngineError.emptyName) {
            try CustomSearchEngine.make(name: "  ", keyword: "yt", template: "https://y.com/?q=%s", existing: []).get()
        }
        #expect(throws: CustomSearchEngineError.invalidKeyword) {
            try CustomSearchEngine.make(name: "YouTube", keyword: "y t", template: "https://y.com/?q=%s", existing: []).get()
        }
        let first = try CustomSearchEngine.make(
            name: "YouTube", keyword: "YT", template: "https://www.youtube.com/results?search_query=%s", existing: []
        ).get()
        #expect(first.keyword == "yt")
        #expect(throws: CustomSearchEngineError.duplicateKeyword) {
            try CustomSearchEngine.make(
                name: "Other", keyword: "yt", template: "https://example.com/?q=%s", existing: [first]
            ).get()
        }
    }
}
