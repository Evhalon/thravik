import RedentKit
import RedentUI
import SwiftUI

/// Maps a `SheetRoute` to the screen that serves it.
///
/// Lives in the app target rather than in `RedentUI` so the window shell stays
/// unaware of which concrete stores back each screen. `app` holds what every
/// window shares; `window` is the one that presented the sheet.
struct SheetRouter: View {
    let route: SheetRoute
    let app: AppContainer
    let window: WindowContainer
    @Environment(\.openWindow) private var openWindow

    private var model: BrowserModel { window.model }

    var body: some View {
        Group {
            switch route {
            case .settings:
                SettingsSheet(
                    settings: settingsBinding,
                    updates: app.updates,
                    defaultBrowser: app.defaultBrowser,
                    onOpenPasswords: { model.sheet = .passwords },
                    onOpenAuthenticatorImport: { model.sheet = .importAuthenticator },
                    onResetWorkspace: { model.resetWorkspace() }
                )

            case .passwords, .authenticator:
                VaultWindowView(
                    sources: VaultSources(
                        credentials: app.credentials,
                        totp: app.authenticator,
                        generator: app.generator
                    ),
                    initialTab: route == .authenticator ? .authenticator : .passwords,
                    onImportAuthenticator: { model.sheet = .importAuthenticator }
                )

            case .history:
                HistoryBrowserView(history: app.history, spaceID: model.currentSpaceID) { url in
                    model.navigate(to: url)
                    model.sheet = nil
                }

            case .spaces:
                WorkspacePanel(model: model)

            case .groups:
                TabGroupsPanel(controller: model.tabs)

            case .timeline:
                if let tab = model.selectedTab {
                    TabTimelinePanel(tab: tab)
                } else {
                    SheetPlaceholder(message: "Open a tab to see where it has been.")
                }

            case .sitePrivacy:
                if let privacy = app.sitePrivacyModel(for: window) {
                    SitePrivacyPanel(model: privacy)
                } else {
                    SheetPlaceholder(message: "Open a website to see its privacy settings.")
                }

            case .bookmarks:
                BookmarksSheet(model: BookmarksModel(
                    store: app.bookmarks,
                    spaces: model.tabs.session.spaces,
                    spaceID: model.currentSpaceID
                )) { url in
                    model.navigate(to: url)
                } onOpenNewTab: { url in
                    model.open(url, inNewTab: true)
                } onOpenNewWindow: { url in
                    openWindow(value: BrowserWindowSpec(isPrivate: model.isPrivate, startURL: url))
                }

            case .importBrowser:
                BrowserImportSheet(model: BrowserImportModel(
                    importer: app.browserImporter,
                    history: app.history,
                    bookmarks: app.bookmarks,
                    credentials: app.credentials,
                    destination: ImportDestination(
                        spaces: model.tabs.session.spaces,
                        spaceID: model.currentSpaceID
                    )
                ))

            case .downloads:
                DownloadsPanel(model: app.downloads)

            case .defaultBrowser:
                DefaultBrowserSheet(model: app.defaultBrowser)

            case .importAuthenticator:
                AuthenticatorImportView(importer: app.importer, store: app.authenticator)
            }
        }
    }

    private var settingsBinding: Binding<BrowserSettings> {
        Binding(get: { model.settings }, set: { model.settings = $0 })
    }
}
