import AppKit
import Foundation
import Observation
import SwiftUI
import RedentEngine
import RedentKit
import RedentImport
import RedentOTPAuth
import RedentUI
import RedentUpdate
import RedentVault

/// The composition root. This is the ONLY type that names concrete adapters —
/// everything above it depends on the ports in RedentKit (AGENTS.md §2).
@MainActor @Observable
final class AppContainer {
    let model: BrowserModel
    let credentials: any CredentialStoring
    let authenticator: any TOTPAccountStoring
    let generator: any TOTPGenerating
    let importer: any OTPAuthImporting
    let history: any HistoryStoring
    let bookmarks: any BookmarkStoring
    let browserImporter: any BrowserImporting
    let permissions: SitePermissionLedger
    let siteData: any SiteDataManaging
    let updates: UpdateModel

    private let sessionStore: any SessionStoring

    init() {
        let logger = OSLogEventLogger(category: "browser")
        let settingsStore = UserDefaultsSettingsStore()
        let sessionStore = UserDefaultsSessionStore()
        let settings = settingsStore.load()

        let credentials = KeychainCredentialStore()
        let authenticator = KeychainTOTPStore()
        let generator = SystemTOTPGenerator()
        let history = SQLiteHistoryStore()
        let bookmarks = JSONBookmarkStore()

        let restored = Result { try sessionStore.loadRecoverable() }
        let tabs = TabController(
            session: (try? restored.get()) ?? BrowserSession(),
            settings: settings,
            logger: logger
        )

        self.credentials = credentials
        self.authenticator = authenticator
        self.generator = generator
        self.importer = OTPAuthImporter()
        self.history = history
        self.bookmarks = bookmarks
        self.browserImporter = ChromiumImporter()
        self.sessionStore = sessionStore
        self.updates = Self.makeUpdateModel()
        let permissions = SitePermissionLedger(store: JSONSitePolicyStore())
        self.permissions = permissions
        self.siteData = tabs.siteData

        let services = BrowserServices(history: history, bookmarks: bookmarks,
                                       settings: settingsStore, session: sessionStore, logger: logger)
        let features = BrowserFeatures(
            autofill: AutofillCoordinator(store: credentials, logger: logger, isEnabled: settings.offersPasswordSave),
            otp: OTPCoordinator(store: authenticator, generator: generator, logger: logger),
            suggestions: AddressSuggestionsModel(engine: SuggestionEngine(history: history, bookmarks: bookmarks))
        )
        self.model = BrowserModel(tabs: tabs, services: services, features: features, settings: settings) { id in
            AnyView(BrowserPageView(controller: tabs, tabID: id))
        }

        tabs.permissionDecider = { [weak permissions] key, permission in
            permissions?.decision(key, permission) ?? .ask
        }
        Task { await permissions.load() }

        if case .failure = restored {
            model.actionError = "Saved workspace could not be restored. Original data was preserved."
        }
        if tabs.tabs.isEmpty {
            tabs.newTab(url: nil)
        }
        tabs.warmUp()
    }

    func persist() {
        model.persistSession()
    }

    /// Releases are published as signed disk images on GitHub; the installer
    /// swaps the running bundle and reopens it once this process exits.
    private static func makeUpdateModel() -> UpdateModel {
        UpdateModel(
            currentVersion: installedVersion(),
            checker: GitHubReleaseFeed(repository: "Evhalon/thravik"),
            installer: DiskImageInstaller(),
            quit: { AppTermination.quit() }
        )
    }

    /// `nil` under `swift run`, which has no Info.plist and so no version to
    /// compare — a dev build is never offered an update.
    private static func installedVersion() -> AppVersion? {
        guard let raw = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        else { return nil }
        return AppVersion(raw)
    }
}
