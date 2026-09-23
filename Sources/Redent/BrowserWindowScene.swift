import RedentUI
import SwiftUI

/// Binds one window's scene to the container that serves it.
///
/// Separated from `RootScene` so the container lookup can happen outside a
/// `ViewBuilder`, and so the only place that knows how to open another window —
/// this view's environment action — is also the only place that hands the
/// window model a way to ask for one.
struct BrowserWindowScene: View {
    let app: AppContainer
    let spec: BrowserWindowSpec
    let delegate: AppDelegate

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let window = app.window(for: spec)
        return BrowserWindowView(model: window.model) { route in
            SheetRouter(route: route, app: app, window: window)
        }
        .onAppear { window.model.windowOpener = open(isPrivate:) }
        .task {
            let openedExternalLinks = app.drainPendingLinks()
            await delegate.windowBecameReady(openedExternalLinks: openedExternalLinks)
            await app.offerDefaultBrowserIfNeeded(in: window)
        }
        .onDisappear { app.releaseWindow(spec) }
        .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        .onOpenURL { url in
            app.openExternal([url])
            delegate.presentApplication()
        }
    }

    private func open(isPrivate: Bool) {
        openWindow(value: BrowserWindowSpec(isPrivate: isPrivate))
    }
}
