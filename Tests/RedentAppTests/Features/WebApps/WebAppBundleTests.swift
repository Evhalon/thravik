import Foundation
import RedentKit
import Testing
@testable import Redent

@Suite("Web app bundles")
struct WebAppBundleTests {
    private let host = WebAppHost(bundleID: "app.redent.browser", name: "Thravik", launcher: nil)

    @Test("An icon file carries its magic, its length and every rendition")
    func icnsLayout() throws {
        let icns = try #require(WebAppIconRenderer.icns(favicon: nil, name: "Mail"))
        #expect(icns.prefix(4) == Data("icns".utf8))
        let length = icns[4..<8].reduce(0) { $0 << 8 | Int($1) }
        #expect(length == icns.count)
        for rendition in ICNSEncoder.renditions {
            #expect(icns.range(of: Data(rendition.type.utf8)) != nil)
        }
    }

    @Test("A favicon that cannot be read still yields an icon")
    func unreadableFavicon() {
        #expect(WebAppIconRenderer.icns(favicon: Data([1, 2, 3]), name: "Site") != nil)
    }

    @Test("The bundle names itself after the app and points back at the browser")
    func manifest() throws {
        let app = WebApp(name: "Mail: Work/Home", url: try #require(URL(string: "https://mail.example")))
        let manifest = WebAppBundleManifest(app: app, host: host)
        #expect(manifest.bundleFileName == "Mail- Work-Home.app")
        #expect(manifest.bundleIdentifier.hasPrefix("app.redent.browser.webapp."))
        #expect(manifest.infoPlist[WebAppLink.appIDKey] as? String == app.id.uuidString)
        #expect(manifest.infoPlist[WebAppLink.hostBundleIDKey] as? String == "app.redent.browser")
    }
}
