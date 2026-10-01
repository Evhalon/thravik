import RedentEngine
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
        let settings = SettingsServices(
            updates: app.updates, defaultBrowser: app.defaultBrowser,
            passkeys: app.passkeys, extensions: app.extensions.model
        )
        return BrowserWindowView(model: window.model, settingsServices: settings) { route in
            SheetRouter(route: route, app: app, window: window)
        }
        .environment(\.extensionToolbar, extensionToolbar(for: window))
        .onAppear {
            window.model.windowOpener = open(isPrivate:)
            window.model.windowDirectory = AppWindowDirectory(app: app, current: spec) { openWindow(value: $0) }
            let extensions = app.extensions.model
            window.model.extensionInstaller = { [weak model = window.model] storeID in
                extensions.requestInstall(storeID)
                model?.showSettings()
            }
        }
        .task {
            await app.offerDefaultBrowserIfNeeded(in: window)
        }
        .onDisappear { app.releaseWindow(spec) }
        .background {
            WindowReadyProbe { nativeWindow in
                window.nativeWindow = nativeWindow
                app.extensions.host.windowBecameReady(window.tabs, nativeWindow: nativeWindow)
                let openedExternalLinks = app.drainPendingLinks()
                delegate.windowBecameReady(nativeWindow, openedExternalLinks: openedExternalLinks)
            }
            .frame(width: 0, height: 0)
        }
        .background {
            if let frame = spec.frame {
                TornOffWindowPlacer(frame: frame.rect).frame(width: 0, height: 0)
            }
        }
    }

    /// Private windows never run extensions, so they get no buttons for them.
    private func extensionToolbar(for window: WindowContainer) -> AnyView? {
        guard !spec.isPrivate else { return nil }
        let extensions = app.extensions.model
        return AnyView(ExtensionToolbar(host: app.extensions.host, tabs: window.tabs) {
            extensions.wantsReveal = true
            window.model.showSettings()
        })
    }

    private func open(isPrivate: Bool) {
        openWindow(value: BrowserWindowSpec(isPrivate: isPrivate))
    }
}
