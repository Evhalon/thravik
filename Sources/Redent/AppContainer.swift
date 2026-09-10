import Foundation
import Observation
import RedentEngine
import RedentImport
import RedentKit
import RedentOTPAuth
import RedentUI
import RedentUpdate
import RedentVault

/// The composition root. This is the ONLY type that names concrete adapters —
/// everything above it depends on the ports in RedentKit (AGENTS.md §2).
///
/// It owns what the whole app shares; a window's own tabs and chrome live in
/// the `WindowContainer` it hands out.
@MainActor @Observable
final class AppContainer {
    let credentials: any CredentialStoring
    let authenticator: any TOTPAccountStoring
    let generator: any TOTPGenerating
    let importer: any OTPAuthImporting
    let history: any HistoryStoring
    let bookmarks: any BookmarkStoring
    let browserImporter: any BrowserImporting
    let permissions: SitePermissionLedger
    /// One list for the whole app: a download outlives the window that started
    /// it, and the engine side of it outlives the tab.
    let downloads = DownloadsModel()
    let downloadCoordinator: DownloadCoordinator
    /// The once-per-release offer to take over web links.
    let defaultBrowser: DefaultBrowserModel
    /// One per process, so two windows in the same Container share its cookies.
    let contexts = BrowsingContextRegistry()
    var siteData: any SiteDataManaging { contexts }

    let settingsStore: any SettingsStoring
    let sessionStore: any SessionStoring
    let logger: any EventLogging

    /// Links from another app that arrived before a window existed to show
    /// them. Drained by the first window that appears.
    @ObservationIgnored var pendingLinks: [URL] = []

    /// Restored once, and handed to the primary window whenever it is built.
    private var restoredSession: Result<BrowserSession, any Error>
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
        self.settingsStore = UserDefaultsSettingsStore()
        let sessionStore = UserDefaultsSessionStore()
        self.sessionStore = sessionStore
        self.restoredSession = Result { try sessionStore.loadRecoverable() }

        let credentials = KeychainCredentialStore()
        self.credentials = credentials
        self.authenticator = KeychainTOTPStore()
        self.generator = SystemTOTPGenerator()
        self.importer = OTPAuthImporter()
        self.history = SQLiteHistoryStore()
        self.bookmarks = JSONBookmarkStore()
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
        Task { await permissions.load() }
    }

    /// Memoised: SwiftUI re-evaluates a scene's body freely, and rebuilding a
    /// window's tab controller there would throw away its live web views.
    func window(for spec: BrowserWindowSpec) -> WindowContainer {
        if let existing = windows[spec] { return existing }
        let created = WindowContainer(spec: spec, app: self)
        windows[spec] = created
        return created
    }

    func releaseWindow(_ spec: BrowserWindowSpec) {
        windows.removeValue(forKey: spec)?.retire()
    }

    /// What a freshly built window starts from: the saved workspace for the
    /// primary window, a blank one for every other.
    func startingSession(for spec: BrowserWindowSpec) -> BrowserSession {
        guard spec.isPrimary else { return BrowserSession() }
        return (try? restoredSession.get()) ?? BrowserSession()
    }

    /// The saved workspace could not be read. Reported once, by the window that
    /// would have shown it.
    func restoreFailureMessage(for spec: BrowserWindowSpec) -> String? {
        guard spec.isPrimary, case .failure = restoredSession else { return nil }
        return "Saved workspace could not be restored. Original data was preserved."
    }

    /// The window a link from another app lands in: the primary one, or
    /// whichever is open if that one is not.
    var primaryWindow: WindowContainer? {
        windows[.primary] ?? windows.values.first
    }

    func persist() {
        windows[.primary]?.model.persistSession()
    }
}
