import AppKit
import RedentKit

/// Keeps the web app's Dock icon alive for as long as its window is open, and
/// sends every activation — launch, Dock click, ⌘Tab — on to the browser.
@MainActor
final class LauncherDelegate: NSObject, NSApplicationDelegate {
    private let appID: UUID?
    private let hostBundleID: String?

    override init() {
        let info = Bundle.main.infoDictionary ?? [:]
        appID = (info[WebAppLink.appIDKey] as? String).flatMap(UUID.init(uuidString:))
        hostBundleID = info[WebAppLink.hostBundleIDKey] as? String
        super.init()
    }

    static func makeMenu() -> NSMenu {
        let appMenu = NSMenu()
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        appMenu.addItem(withTitle: "Quit \(name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let item = NSMenuItem()
        item.submenu = appMenu
        let menu = NSMenu()
        menu.addItem(item)
        return menu
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let appID else { return NSApp.terminate(nil) }
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(windowClosed(_:)),
            name: Notification.Name(WebAppLink.windowClosedNotification), object: appID.uuidString
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(applicationTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification, object: nil
        )
        openInBrowser()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        openInBrowser()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openInBrowser()
        return false
    }

    /// Quitting the app from the Dock closes its window, as it would for any
    /// other app.
    func applicationWillTerminate(_ notification: Notification) {
        guard let appID else { return }
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(WebAppLink.launcherQuitNotification),
            object: appID.uuidString, userInfo: nil, deliverImmediately: true
        )
    }

    private func openInBrowser() {
        guard let appID, let link = WebAppLink.url(for: appID), let hostBundleID,
              let host = NSWorkspace.shared.urlForApplication(withBundleIdentifier: hostBundleID)
        else { return NSApp.terminate(nil) }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([link], withApplicationAt: host, configuration: configuration)
    }

    @objc private func windowClosed(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    @objc private func applicationTerminated(_ notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard let hostBundleID, app?.bundleIdentifier == hostBundleID else { return }
        NSApp.terminate(nil)
    }
}
