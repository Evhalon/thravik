import Foundation
import Testing
@testable import RedentKit

@Suite("Web app links")
struct WebAppLinkTests {
    @Test("A link names the app it was made for")
    func roundTrip() throws {
        let id = UUID()
        let url = try #require(WebAppLink.url(for: id))
        #expect(WebAppLink.appID(in: url) == id)
    }

    @Test("Ordinary web links are not web-app links")
    func webLinkIsNotAppLink() throws {
        let url = try #require(URL(string: "https://open/\(UUID().uuidString)"))
        #expect(WebAppLink.appID(in: url) == nil)
    }

    @Test("A link without a valid id asks for nothing")
    func malformed() throws {
        let url = try #require(URL(string: "redent-webapp://open/not-an-id"))
        #expect(WebAppLink.appID(in: url) == nil)
    }
}
