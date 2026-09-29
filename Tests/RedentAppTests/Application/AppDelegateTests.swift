import AppKit
import Foundation
import Testing
@testable import Redent

@Suite("External links from native apps")
struct AppDelegateTests {
    @MainActor
    @Test("Receiving a Teams-style web link presents the browser window")
    func externalLinkPresentsBrowserWindow() throws {
        let delegate = AppDelegate()
        var presentedWindow: NSWindow?
        delegate.presentWindow = { presentedWindow = $0 }
        delegate.requestWindow = {}
        let link = try #require(URL(string: "https://teams.microsoft.com/l/message/example"))

        delegate.application(NSApplication.shared, open: [link])

        #expect(presentedWindow == nil)
    }

    @MainActor
    @Test("A cold-launch link presents the exact window after attachment")
    func coldLaunchPresentsReadyWindow() throws {
        let delegate = AppDelegate()
        var presentedWindow: NSWindow?
        delegate.presentWindow = { presentedWindow = $0 }
        delegate.requestWindow = {}
        let link = try #require(URL(string: "https://teams.microsoft.com/l/message/example"))
        let window = NSWindow(contentRect: .zero, styleMask: .titled, backing: .buffered, defer: true)

        delegate.application(NSApplication.shared, open: [link])
        #expect(presentedWindow == nil)

        delegate.windowBecameReady(window, openedExternalLinks: false)

        #expect(presentedWindow === window)
    }

    // Regression: a link that launched the app left it running with no window.
    @MainActor
    @Test("A cold-launch link asks SwiftUI for a window")
    func coldLaunchRequestsWindow() throws {
        let delegate = AppDelegate()
        var requests = 0
        delegate.presentWindow = { _ in }
        delegate.requestWindow = { requests += 1 }
        let link = try #require(URL(string: "https://example.com"))

        delegate.application(NSApplication.shared, open: [link])

        #expect(requests == 1)
    }
}
