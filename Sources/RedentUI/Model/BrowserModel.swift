import Foundation
import Observation
import SwiftUI
import RedentKit

/// One window: tabs, chrome, autofill. App root is the only place that wires stores.
@MainActor @Observable
public final class BrowserModel {
    public let tabs: any BrowserControlling
    public let autofill: AutofillCoordinator
    public let otp: OTPCoordinator
    public let twoFactor: TwoFactorSetupCoordinator
    public let address = AddressBarModel()
    public let suggestions: AddressSuggestionsModel
    public let history: any HistoryStoring
    public let bookmarks: any BookmarkStoring
    public let downloads: DownloadsModel

    public var settings: BrowserSettings { didSet { settingsChanged(from: oldValue) } }
    public var sheet: SheetRoute?
    public var showsCommandBar = false
    public var actionError: String?
    /// The temporary tab whose deadline passed while the user was reading it.
    public var expiredTabID: UUID?
    public let commandBar: CommandBarModel
    /// Find bar, bookmark star, and caret requests — everything the chrome
    /// shows about the page in front of the user.
    public let chrome = PageChromeModel()
    /// Chrome hidden entirely — "widen the screen and hide the tabs".
    public var isFocusMode: Bool = false
    /// Which tabs this window shows side by side, and which pane has the chrome.
    public var split = SplitLayout()
    /// Bumped so the new-tab search field can steal first responder from the
    /// sidebar address field after AppKit reassigns it.
    public var centerSearchFocusEpoch: UInt = 0

    /// Opens another browser window. Set by the composition root, which is the
    /// only layer that knows what a window is; nil in previews and tests.
    @ObservationIgnored public var windowOpener: (@MainActor (_ isPrivate: Bool) -> Void)?
    /// The app's other windows. Set by the composition root; nil in tests.
    @ObservationIgnored public var windowDirectory: (any BrowserWindowDirectory)?
    /// Sites kept as apps, newest list from `webAppStore`.
    public internal(set) var webApps: [WebApp] = []
    let webAppStore: (any WebAppStoring)?
    let webAppInstaller: (any WebAppInstalling)?
    /// The last queued write to `webAppStore`; reads wait for it.
    @ObservationIgnored var webAppWrite: Task<Void, Never>?

    @ObservationIgnored private let visits: VisitRecorder
    /// `internal` rather than `private`: the persistence policy lives in a
    /// sibling file to stay under the line limit.
    @ObservationIgnored var hasUnsavedChanges = false
    @ObservationIgnored var lastTabCount = 0
    @ObservationIgnored var lastSave = Date.distantPast
    @ObservationIgnored var hasUnsavedSettings = false
    @ObservationIgnored var saveTask: Task<Bool?, Never>?
    let settingsStore: any SettingsStoring
    let sessionStore: any SessionStoring
    private let logger: any EventLogging

    public let content: @MainActor (UUID) -> AnyView

    public init(tabs: any BrowserControlling, services: BrowserServices,
                features: BrowserFeatures, settings: BrowserSettings,
                content: @escaping @MainActor (UUID) -> AnyView) {
        self.tabs = tabs
        self.autofill = features.autofill
        self.otp = features.otp
        self.twoFactor = features.twoFactor
        self.suggestions = features.suggestions
        self.history = services.history
        self.bookmarks = services.bookmarks
        self.downloads = services.downloads
        self.webAppStore = services.webApps
        self.webAppInstaller = services.webAppInstaller
        self.visits = VisitRecorder(history: services.history)
        self.settings = settings
        self.settingsStore = services.settings
        self.sessionStore = services.session
        self.logger = services.logger
        self.content = content
        self.lastTabCount = tabs.tabs.count
        var commands = CommandBarModel.Configuration(history: services.history, bookmarks: services.bookmarks)
        commands.searchEngine = settings.searchEngine
        self.commandBar = CommandBarModel(configuration: commands)
        tabs.signalHandler = self
        tabs.onChange = { [weak self] in self?.tabsChanged() }
        tabs.onNavigation = { [weak self] snapshot, id in self?.visits.record(snapshot, navigationID: id) }
        commandBar.onExecute = { [weak self] action in self?.execute(action) }
        split = tabs.session.splitLayout
        split.validate(against: Set(tabs.tabs.map(\.id)))
        Task { [weak self] in await self?.reloadWebApps() }
    }

    public func navigate(to url: URL) {
        if let tab = selectedTab { tab.load(url) } else { tabs.newTab(url: url) }
    }

    public func pageContextChanged() {
        autofill.pageChanged()
        otp.pageChanged()
        twoFactor.pageChanged()
    }

    /// One timer for the whole window, per AGENTS.md §4 — not one per code.
    public func tick(_ date: Date) {
        otp.tick(date)
        otp.dismissIfPageChanged(selectedTab?.url)
        tabs.sweepHibernation(now: date, keeping: split.visibleTabIDs(primary: tabs.selectedID))
        if let expired = tabs.sweepExpiredTabs(now: date) { expiredTabID = expired }
        let origin = selectedTab?.pageTrustIssue == nil ? selectedTab?.origin : nil
        autofill.observe(origin)
        persistIfNeeded(date)
    }

    private func settingsChanged(from old: BrowserSettings) {
        // A sidebar drag writes this on every frame. Encoding and storing the
        // settings that often is what made the drag feel heavy, so the write is
        // coalesced onto the window clock like the workspace itself.
        hasUnsavedSettings = true
        tabs.apply(settings: settings)
        commandBar.searchEngine = settings.searchEngine
        if old.offersPasswordSave != settings.offersPasswordSave {
            autofill.setEnabled(settings.offersPasswordSave)
        }
        if !settings.showsTOTPButton {
            otp.fieldDisappeared()
            twoFactor.pageChanged()
        }
    }
}
