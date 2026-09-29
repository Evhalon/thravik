import Foundation
import Testing
@testable import RedentKit

@Suite("Tracking parameters")
struct TrackingParametersTests {
    private func strip(_ raw: String) -> String? {
        URL(string: raw).flatMap(TrackingParameters.stripped)?.absoluteString
    }

    @Test("Campaign and click IDs are removed, the page's own parameters kept in order")
    func removesTrackers() {
        let result = strip("https://shop.example/item?id=42&utm_source=news&color=red&fbclid=abc")
        #expect(result == "https://shop.example/item?id=42&color=red")
    }

    @Test("A query made only of trackers disappears entirely, fragment intact")
    func dropsEmptyQuery() {
        #expect(strip("https://example.com/a?utm_medium=email&gclid=1#top") == "https://example.com/a#top")
    }

    @Test("A clean URL reports nothing to do")
    func cleanURL() {
        #expect(strip("https://example.com/search?q=utm_source") == nil)
        #expect(strip("https://example.com/") == nil)
    }

    @Test("Names match exactly or by prefix, never by substring")
    func noSubstringMatch() {
        #expect(strip("https://example.com/?myfbclid=1&utm=2") == nil)
        #expect(TrackingParameters.isTracking("UTM_Campaign"))
    }

    @Test("Percent-encoding in kept values survives byte for byte")
    func keepsEncoding() {
        let result = strip("https://example.com/?q=a%2Bb%20c&utm_term=x")
        #expect(result == "https://example.com/?q=a%2Bb%20c")
    }

    @Test("Only web URLs are rewritten")
    func webOnly() {
        #expect(strip("ftp://example.com/?utm_source=x") == nil)
    }
}
