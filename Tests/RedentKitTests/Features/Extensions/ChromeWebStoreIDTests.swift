import Foundation
import RedentKit
import Testing

struct ChromeWebStoreIDTests {
    private let uBlock = "ddkjiahejlhfcafbddmgiahcphecmpfh"

    @Test("A bare id is accepted, whatever its case and padding")
    func bareID() {
        #expect(ChromeWebStoreID("  DDKJIAHEJLHFCAFBDDMGIAHCPHECMPFH\n")?.rawValue == uBlock)
    }

    @Test("The id is read from a new-store detail link")
    func newStoreLink() {
        let link = "https://chromewebstore.google.com/detail/ublock-origin-lite/\(uBlock)?hl=en"
        #expect(ChromeWebStoreID(link)?.rawValue == uBlock)
    }

    @Test("The id is read from an old-store link")
    func oldStoreLink() {
        let link = "https://chrome.google.com/webstore/detail/ublock/\(uBlock)"
        #expect(ChromeWebStoreID(link)?.rawValue == uBlock)
    }

    @Test("Letters outside a–p, wrong lengths and other sites are rejected")
    func rejectsLookalikes() {
        #expect(ChromeWebStoreID("zzkjiahejlhfcafbddmgiahcphecmpfh") == nil)
        #expect(ChromeWebStoreID("ddkjiahejlhfcafbddmgiahcphecmpf") == nil)
        #expect(ChromeWebStoreID("https://example.com/detail/\(uBlock)") == nil)
    }

    @Test("The download link asks Google's update service for that id")
    func downloadURL() throws {
        let id = try #require(ChromeWebStoreID(uBlock))
        let url = try #require(id.downloadURL)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.host() == "clients2.google.com")
        #expect(items.contains(URLQueryItem(name: "x", value: "id=\(uBlock)&uc")))
        #expect(items.contains(URLQueryItem(name: "response", value: "redirect")))
    }

    @Test("Store pages are recognised, other pages are not")
    func storePage() throws {
        let store = try #require(URL(string: "https://chromewebstore.google.com/detail/x/\(uBlock)"))
        let search = try #require(URL(string: "https://chromewebstore.google.com/search/ublock"))
        #expect(ChromeWebStoreID.isStorePage(store))
        #expect(!ChromeWebStoreID.isStorePage(search))
    }
}
