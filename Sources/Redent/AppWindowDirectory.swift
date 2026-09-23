import AppKit
import Foundation
import RedentKit

/// One window's view of every other: what the Command Bar lists under
/// Windows, and how a tab or a web app reaches a window of its own.
///
/// Holds the container weakly — the window model owns this directory, and the
/// container owns the window model.
@MainActor
final class AppWindowDirectory: BrowserWindowDirectory {
    private weak var app: AppContainer?
    private let current: BrowserWindowSpec
    private let openWindow: @MainActor (BrowserWindowSpec) -> Void

    init(app: AppContainer, current: BrowserWindowSpec, openWindow: @escaping @MainActor (BrowserWindowSpec) -> Void) {
        self.app = app
        self.current = current
        self.openWindow = openWindow
    }

    var windows: [CommandWindowContext] {
        guard let app else { return [] }
        return app.windows.values
            .sorted { $0.spec.isPrimary && !$1.spec.isPrimary }
            .map { window in
                let model = window.model
                let title = model.selectedTab?.snapshot.displayTitle ?? "New Tab"
                return CommandWindowContext(id: window.spec.id, title: title, tabCount: model.tabs.tabs.count,
                                            flags: .init(isPrivate: window.spec.isPrivate,
                                                         isCurrent: window.spec.id == current.id,
                                                         webAppID: window.spec.webApp?.appID))
            }
    }

    func focus(_ id: UUID) {
        guard let window = container(id)?.nativeWindow else { return }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func closeCurrent() {
        container(current.id)?.nativeWindow?.performClose(nil)
    }

    func toggleFullScreen() {
        container(current.id)?.nativeWindow?.toggleFullScreen(nil)
    }

    func adopt(_ url: URL, into id: UUID?) -> Bool {
        guard let id else {
            openWindow(BrowserWindowSpec(isPrivate: current.isPrivate, startURL: url))
            return true
        }
        guard let target = container(id), target.spec.isPrivate == current.isPrivate else { return false }
        target.tabs.newTab(url: url)
        focus(id)
        return true
    }

    func open(_ app: WebApp, at url: URL?, in space: BrowserSpace?) {
        let existing = self.app?.windows.values.first { $0.spec.webApp?.appID == app.id }
        guard let existing else {
            let window = WebAppWindow(appID: app.id, space: space)
            openWindow(BrowserWindowSpec(startURL: url ?? app.url, webApp: window))
            return
        }
        if let url { existing.model.navigate(to: url) }
        focus(existing.spec.id)
    }

    private func container(_ id: UUID) -> WindowContainer? {
        app?.windows.values.first { $0.spec.id == id }
    }
}
