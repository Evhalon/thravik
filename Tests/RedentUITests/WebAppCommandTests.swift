import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Open as App")
struct WebAppCommandTests {
    @Test("Saving the site hands the page to its app window, and remembers the app")
    func saveOpensAppWindow() async throws {
        let browser = FakeBrowser()
        let tab = InertTab()
        tab.url = URL(string: "https://github.com/acme/onepanel/pull/182")
        tab.title = "Pull request #182 — OnePanel — GitHub"
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        let store = MemoryWebAppStore()
        let model = makeTestBrowserModel(tabs: browser, webApps: store)
        let directory = RecordingWindowDirectory()
        model.windowDirectory = directory

        model.execute(.saveWebApp)

        let opened = try #require(directory.openedApps.first)
        #expect(opened.app.name == "GitHub")
        #expect(opened.app.url == URL(string: "https://github.com/"))
        #expect(opened.url == tab.url)
        #expect(browser.closed == [tab.id])
        await model.reloadWebApps()
        #expect(model.webApps.map(\.name) == ["GitHub"])
    }

    @Test("A saved app with no window system opens as a tab")
    func openWithoutDirectory() async throws {
        let app = WebApp(name: "Linear", url: try #require(URL(string: "https://linear.app/")))
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser, webApps: MemoryWebAppStore([app]))
        await model.reloadWebApps()

        model.execute(.openWebApp(app.id))

        #expect(browser.openedURLs == [app.url])
    }

    @Test("The app list offers the site as an app, and reopens one already saved")
    func descriptorPrefersExisting() throws {
        var fixture = CommandFixture()
        let descriptor = try #require(DefaultCommandDescriptors.all.first { $0.id == "open-as-app" })
        #expect(descriptor.action(in: fixture.context) == .saveWebApp)
        let app = WebApp(name: "GitHub", url: try #require(URL(string: "https://github.com/")))
        fixture.context.webApps = [app]
        #expect(descriptor.action(in: fixture.context) == .openWebApp(app.id))
    }
}
