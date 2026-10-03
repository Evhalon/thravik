import AppKit
import RedentEngine
import RedentUI
import SwiftUI

struct BrowserWindowScene: View {
    let app: AppContainer
    let spec: BrowserWindowSpec
    let delegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let window = app.window(for: spec)
        return BrowserWindowView(model: window.model, settingsServices: settings,
                                 isWorkspaceDisabled: spec.isPrimary && !app.onboarding.model.isComplete) { route in
            SheetRouter(route: route, app: app, window: window)
        }
        .modifier(FirstRunPresenter(app: app, window: window, isPrimary: spec.isPrimary))
        .environment(\.extensionToolbar, extensionToolbar(for: window))
        .onAppear { configure(window) }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            app.passwords.model.scheduleSynchronization()
            app.workspace.schedule()
        }
        .onDisappear { app.releaseWindow(spec) }
        .background {
            WindowReadyProbe { nativeWindow in ready(window, nativeWindow: nativeWindow) }
                .frame(width: 0, height: 0)
        }
        .background {
            if let frame = spec.frame {
                TornOffWindowPlacer(frame: frame.rect).frame(width: 0, height: 0)
            }
        }
    }

    private var settings: SettingsServices {
        var settings = SettingsServices(
            updates: app.updates, defaultBrowser: app.defaultBrowser,
            passkeys: app.passkeys, extensions: app.extensions.model
        )
        settings.account = app.account.model
        settings.passwordStorage = app.passwords.model
        settings.devices = app.passwords.devices
        settings.workspace = app.workspace.model
        settings.restartOnboarding = { [weak onboarding = app.onboarding] in
            onboarding?.model.startDemo()
            if !spec.isPrimary { openWindow(value: BrowserWindowSpec.primary) }
        }
        settings.restartRealOnboarding = { [weak onboarding = app.onboarding] in
            onboarding?.restartReal()
            if !spec.isPrimary { openWindow(value: BrowserWindowSpec.primary) }
        }
        return settings
    }

    private func configure(_ window: WindowContainer) {
        window.model.windowOpener = open(isPrivate:)
        window.model.windowDirectory = AppWindowDirectory(app: app, current: spec) { openWindow(value: $0) }
        let extensions = app.extensions.model
        window.model.extensionInstaller = { [weak model = window.model] storeID in
            extensions.requestInstall(storeID)
            model?.showSettings()
        }
        guard spec.isPrimary else { return }
        window.model.publishWorkspace = { [workspace = app.workspace] session in workspace.note(session) }
        app.workspace.model.openTab = { [weak model = window.model] tab in model?.openRemoteTab(tab) }
        app.workspace.note(window.model.durableSession())
    }

    private func ready(_ window: WindowContainer, nativeWindow: NSWindow) {
        window.nativeWindow = nativeWindow
        app.extensions.host.windowBecameReady(window.tabs, nativeWindow: nativeWindow)
        let openedExternalLinks = app.drainPendingLinks()
        delegate.windowBecameReady(nativeWindow, openedExternalLinks: openedExternalLinks)
    }

    private func extensionToolbar(for window: WindowContainer) -> AnyView? {
        guard !spec.isPrivate else { return nil }
        let extensions = app.extensions.model
        return AnyView(ExtensionToolbar(host: app.extensions.host, tabs: window.tabs) {
            extensions.wantsReveal = true
            window.model.showSettings()
        })
    }

    private func open(isPrivate: Bool) {
        if isPrivate, !app.managedPolicy.privateWindowsAllowed { return }
        openWindow(value: BrowserWindowSpec(isPrivate: isPrivate))
    }
}
