import Foundation
import Observation
import RedentEngine
import RedentImport
import RedentKit
import RedentOTPAuth
import RedentUI
import RedentUpdate
import RedentVault

@MainActor @Observable
final class AppContainer {
    let account = AppAccount()
    let onboarding = AppOnboarding()
    let passwords: AppPasswordStorage
    let credentials: any CredentialStoring
    let authenticator: any TOTPAccountStoring
    let generator: any TOTPGenerating
    let importer: any OTPAuthImporting
    let history: any HistoryStoring
    let bookmarks: any BookmarkStoring
    let webApps: any WebAppStoring = JSONWebAppStore()
    let formHistory: any FormHistoryStoring = JSONFormHistoryStore()
    let webAppInstaller: any WebAppInstalling
    let browserImporter: any BrowserImporting
    let permissions: SitePermissionLedger
    /// One list for the whole app: a download outlives the window that started
    /// it, and the engine side of it outlives the tab.
    let downloads = DownloadsModel()
    let downloadCoordinator: DownloadCoordinator
    /// The once-per-release offer to take over web links.
    let defaultBrowser: DefaultBrowserModel
    let passkeys = PasskeyAccessModel(authorizer: SystemPasskeyAuthorization())
    let extensions = AppExtensions()
    /// One per process, so two windows in the same Container share its cookies.
    let contexts = BrowsingContextRegistry(sessionCookies: KeychainSessionCookieStore(
        service: KeychainNamespace.service("app.redent.session-cookies")
    ))
    var siteData: any SiteDataManaging { contexts }

    let managedPolicy: AppManagedPolicy
    let settingsStore: any SettingsStoring
    let sessionStore: any SessionStoring
    let logger: any EventLogging
    let workspace = AppWorkspaceSync()
    let calendar: any CalendarEventsProviding = EventKitCalendarStore()

    /// Links from another app that arrived before a window existed to show
    /// them. Drained by the first window that appears.
    @ObservationIgnored var pendingLinks: [URL] = []
    @ObservationIgnored var didReceiveExternalLink = false
    /// The same click can reach the app twice, through SwiftUI and AppKit.
    @ObservationIgnored var linkDebouncer = ExternalLinkDebouncer()

    @ObservationIgnored private var primaryWorkspace: PrimaryWorkspace
    /// Readable beyond this file, and only here: the update wiring in a
    /// sibling file has to reach every window to clear its sheet before the
    /// process can quit.
    private(set) var windows: [BrowserWindowSpec: WindowContainer] = [:]
    /// Built on first use so its quit hook can reach every open window.
    /// `internal` rather than `private`: the update wiring lives in a sibling
    /// file to stay under the line limit.
    @ObservationIgnored var updatesStorage: UpdateModel?

    init() {
        let logger = OSLogEventLogger(category: "browser")
        self.logger = logger
        self.managedPolicy = AppManagedPolicy()
        self.settingsStore = PolicyAwareSettingsStore(inner: UserDefaultsSettingsStore(), policy: managedPolicy.applied)
        let sessionStore = UserDefaultsSessionStore()
        self.sessionStore = sessionStore
        if settingsStore.load().reopensTabsOnLaunch {
            self.primaryWorkspace = PrimaryWorkspace(restored: Result { try sessionStore.loadRecoverable() })
        } else {
            let profile = (try? sessionStore.loadRecoverable())?.profile
            self.primaryWorkspace = PrimaryWorkspace(restored: .success(BrowserSession(profile: profile)))
        }

        self.webAppInstaller = WebAppBundleInstaller(host: .current(), logger: logger)
        let credentials = KeychainCredentialStore(
            service: KeychainNamespace.service("app.redent.browser.credentials")
        )
        let passwords = AppPasswordStorage(local: credentials, account: account)
        self.passwords = passwords
        self.credentials = passwords.router
        self.authenticator = KeychainTOTPStore(service: KeychainNamespace.service("app.redent.browser.totp"))
        self.generator = SystemTOTPGenerator()
        self.importer = OTPAuthImporter()
        self.history = SQLiteHistoryStore()
        self.bookmarks = BroadcastingBookmarkStore(JSONBookmarkStore())
        self.browserImporter = ChromiumImporter()

        let permissions = SitePermissionLedger(store: JSONSitePolicyStore())
        self.permissions = permissions
        let coordinator = DownloadCoordinator(logger: logger)
        self.downloadCoordinator = coordinator
        self.defaultBrowser = DefaultBrowserModel(
            manager: SystemDefaultBrowser(),
            store: DefaultBrowserPromptStore(),
            installedVersion: Self.installedVersionString()
        )
        coordinator.observer = downloads
        downloads.commands = coordinator
        passwords.model.onProviderChanged = { [weak self] in
            self?.windows.values.forEach { $0.model.autofill.pendingSave = nil; $0.model.pageContextChanged(); $0.model.sheet = nil }
        }
        Task { await permissions.load() }
        Task { [extensions] in await extensions.host.start() }
        KeychainMigration.run(credentials: credentials, authenticator: authenticator)
        observeWebAppLaunchers()
        startUpdatePolling()
        passwords.connect(workspace)
        workspace.apply = { [weak self] snapshot in self?.applyWorkspace(snapshot) }
        wireManagedPolicy()
    }

    /// Memoised: SwiftUI re-evaluates a scene's body freely, and rebuilding a
    /// window's tab controller there would throw away its live web views.
    func window(for spec: BrowserWindowSpec) -> WindowContainer {
        if let existing = windows[spec] { return existing }
        let created = WindowContainer(spec: spec, app: self)
        windows[spec] = created
        shareSensitiveHistory(of: created)
        applyManagedPolicy(to: created)
        return created
    }

    func releaseWindow(_ spec: BrowserWindowSpec) {
        let released = windows.removeValue(forKey: spec)
        released?.retire()
        if spec.isPrimary, let released {
            primaryWorkspace.windowReleased(with: released.model.durableSession())
        }
        if let appID = spec.webApp?.appID { webAppWindowClosed(appID) }
    }

    /// What a freshly built window starts from: the saved workspace for the
    /// primary window, a blank one for every other.
    func startingSession(for spec: BrowserWindowSpec) -> BrowserSession {
        guard spec.isPrimary else { return spec.webApp?.session ?? BrowserSession() }
        return primaryWorkspace.session
    }

    /// The saved workspace could not be read. Reported once, by the window that
    /// would have shown it.
    func restoreFailureMessage(for spec: BrowserWindowSpec) -> String? {
        guard spec.isPrimary, primaryWorkspace.restoreFailed else { return nil }
        return "Saved workspace could not be restored. Original data was preserved."
    }
}
