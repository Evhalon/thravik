import Foundation
import Testing
@testable import RedentUI

@Suite("New-tab icon probe")
struct SiteIconProbeTests {
    @Test("Probes PNG paths before the classic .ico")
    func candidateOrder() {
        let urls = SiteIconProbe.urls(for: "GitHub.com").map(\.absoluteString)
        #expect(urls == [
            "https://github.com/apple-touch-icon.png",
            "https://github.com/favicon-192.png",
            "https://github.com/favicon.png",
            "https://github.com/favicon.ico",
            "https://www.github.com/favicon.ico"
        ])
    }

    @Test("A www host is not probed twice")
    func skipsDuplicateWWW() {
        let urls = SiteIconProbe.urls(for: "www.bbc.co.uk").map(\.absoluteString)
        #expect(!urls.contains { $0.contains("www.www.") })
        #expect(urls.contains("https://www.bbc.co.uk/favicon.ico"))
        #expect(urls.first == "https://www.bbc.co.uk/apple-touch-icon.png")
    }

    @Test("Rejects path-like hosts so a tile cannot fetch off-origin")
    func rejectsUnsafeHost() {
        #expect(SiteIconProbe.urls(for: "evil.com/steal").isEmpty)
        #expect(SiteIconProbe.urls(for: "https://evil.com").isEmpty)
    }

    @Test("Accepts real image bytes and rejects HTML stand-ins")
    func sniffsBytes() {
        #expect(SiteIconProbe.isImage(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])))
        #expect(SiteIconProbe.isImage(Data([0x00, 0x00, 0x01, 0x00, 0x01, 0x00])))
        #expect(SiteIconProbe.isImage(Data("<svg xmlns='n' width='1'/>".utf8)))
        #expect(!SiteIconProbe.isImage(Data("<!DOCTYPE html><html></html>".utf8)))
        #expect(!SiteIconProbe.isImage(Data()))
    }
}
