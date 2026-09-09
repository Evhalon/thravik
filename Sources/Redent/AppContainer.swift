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
    /// One per process, so two windows in the same Container share its cookies.
    let contexts = BrowsingContextRegistry()
    var siteData: any SiteDataManaging { contexts }

    let settingsStore: any SettingsStoring
    let sessionStore: any SessionStoring
    let logger: any EventLogging

    /// Restored once, and handed to the primary window whenever it is built.
    private var restoredSession: Result<BrowserSession, any Error>
    private var windows: [BrowserWindowSpec: WindowContainer] = [:]
    /// Built on first use so its quit hook can reach every open window.
    @ObservationIgnored private var updatesStorage: UpdateModel?

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

    func persist() {
        windows[.primary]?.model.persistSession()
    }

    /// Releases are published as signed disk images on GitHub; the installer
    /// swaps the running bundle and reopens it once this process exits.
    var updates: UpdateModel {
        if let updatesStorage { return updatesStorage }
        let created = UpdateModel(
            currentVersion: Self.installedVersion(),
            checker: GitHubReleaseFeed(repository: "Evhalon/thravik"),
            installer: DiskImageInstaller(),
            // The restart is asked for from inside a sheet a window presents, so
            // every window's binding has to be cleared before AppKit will
            // terminate — not just the one the button was pressed in.
            quit: { [weak self] in
                AppTermination.quit(dismissing: { self?.dismissAllPresentations() })
            }
        )
        updatesStorage = created
        return created
    }

    private func dismissAllPresentations() {
        for window in windows.values { window.model.dismissPresentations() }
    }

    /// `nil` under `swift run`, which has no Info.plist and so no version to
    /// compare — a dev build is never offered an update.
    private static func installedVersion() -> AppVersion? {
        guard let raw = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        else { return nil }
        return AppVersion(raw)
    }
}
