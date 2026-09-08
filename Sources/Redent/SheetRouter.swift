import RedentKit
import RedentUI
import SwiftUI

/// Maps a `SheetRoute` to the screen that serves it.
///
/// Lives in the app target rather than in `RedentUI` so the window shell stays
/// unaware of which concrete stores back each screen.
struct SheetRouter: View {
    let route: SheetRoute
    let container: AppContainer

    var body: some View {
        Group {
            switch route {
            case .settings:
                SettingsSheet(
                    settings: settingsBinding,
                    updates: container.updates,
                    onOpenPasswords: { container.model.sheet = .passwords },
                    onOpenAuthenticatorImport: { container.model.sheet = .importAuthenticator },
                    onResetWorkspace: { container.model.resetWorkspace() }
                )

            case .passwords, .authenticator:
                VaultWindowView(
                    sources: VaultSources(
                        credentials: container.credentials,
                        totp: container.authenticator,
                        generator: container.generator
                    ),
                    initialTab: route == .authenticator ? .authenticator : .passwords,
                    onImportAuthenticator: { container.model.sheet = .importAuthenticator }
                )

            case .history:
                HistoryBrowserView(history: container.history, spaceID: container.model.tabs.session.selectedSpaceID) { url in
                    container.model.navigate(to: url)
                    container.model.sheet = nil
                }

            case .spaces:
                WorkspacePanel(model: container.model)

            case .groups:
                TabGroupsPanel(controller: container.model.tabs)

            case .timeline:
                if let tab = container.model.selectedTab {
                    TabTimelinePanel(tab: tab)
                } else {
                    SheetPlaceholder(message: "Open a tab to see where it has been.")
                }

            case .sitePrivacy:
                if let model = container.sitePrivacyModel() {
                    SitePrivacyPanel(model: model)
                } else {
                    SheetPlaceholder(message: "Open a website to see its privacy settings.")
                }

            case .bookmarks:
                BookmarksSheet(model: BookmarksModel(
                    store: container.bookmarks,
                    spaces: container.model.tabs.session.spaces,
                    spaceID: container.model.currentSpaceID
                )) { url in
                    container.model.navigate(to: url)
                }

            case .importBrowser:
                BrowserImportSheet(model: BrowserImportModel(
                    importer: container.browserImporter,
                    history: container.history,
                    bookmarks: container.bookmarks,
                    credentials: container.credentials,
                    destination: ImportDestination(
                        spaces: container.model.tabs.session.spaces,
                        spaceID: container.model.currentSpaceID
                    )
                ))

            case .importAuthenticator:
                AuthenticatorImportView(
                    importer: container.importer,
                    store: container.authenticator
                )
            }
        }
    }

    private var settingsBinding: Binding<BrowserSettings> {
        Binding(
            get: { container.model.settings },
            set: { container.model.settings = $0 }
        )
    }
}
