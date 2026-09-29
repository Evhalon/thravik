import AppKit
import Foundation
import RedentKit

/// The browser's half of each web app's own macOS app: opening the window its
/// launcher asks for, and keeping the two alive and dead together.
extension AppContainer {
    func observeWebAppLaunchers() {
        _ = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(WebAppLink.launcherQuitNotification), object: nil, queue: .main
        ) { [weak self] notification in
            guard let id = (notification.object as? String).flatMap(UUID.init(uuidString:)) else { return }
            MainActor.assumeIsolated { self?.closeWebAppWindow(id) }
        }
    }

    /// Tells the app's launcher its window is gone, so its Dock icon goes too.
    func webAppWindowClosed(_ appID: UUID) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(WebAppLink.windowClosedNotification),
            object: appID.uuidString, userInfo: nil, deliverImmediately: true
        )
    }

    /// Opens the web apps `urls` ask for and hands back every other link.
    func openWebAppLinks(_ urls: [URL], from window: WindowContainer) -> [URL] {
        urls.filter { url in
            guard let appID = WebAppLink.appID(in: url) else { return true }
            Task { await window.model.openWebAppLink(appID) }
            return false
        }
    }

    private func closeWebAppWindow(_ appID: UUID) {
        windows.values.first { $0.spec.webApp?.appID == appID }?.nativeWindow?.performClose(nil)
    }
}
