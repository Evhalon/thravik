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
    public let formHistory: FormHistoryCoordinator
    public let address = AddressBarModel()
    public let suggestions: AddressSuggestionsModel
    public let history: any HistoryStoring
    public let bookmarks: any BookmarkStoring
    public let downloads: DownloadsModel
    public let updates: UpdateModel?

    public var settings: BrowserSettings { didSet { settingsChanged(from: oldValue) } }
    public var managedPolicyLocks: Set<ManagedPolicyLockKey> = []
    public var sheet: SheetRoute?
    /// Settings replace the page in this window until the user leaves them.
    public var showsSettings = false
    public var showsCommandBar = false
    public var showsFloatingNewTab = false
    /// Address bar, floating new tab, or the home search field. Nil on a web page.
    var pasteAndGoField: PasteAndGoField?
    public var actionError: String?
    /// The temporary tab whose deadline passed while the user was reading it.
    public var expiredTabID: UUID?
    public let commandBar: CommandBarModel
    public let chrome = PageChromeModel()
    let groupNames: GroupNameModel
    /// Chrome hidden entirely — "widen the screen and hide the tabs".
    public var isFocusMode: Bool = false
    /// Which tabs this window shows side by side, and which pane has the chrome.
    public var split = SplitLayout()
    /// Bumped so the new-tab search field can steal first responder from the
    /// sidebar address field after AppKit reassigns it.
    public var centerSearchFocusEpoch: UInt = 0
    public private(set) var tidyTabsCandidateIDs: [UUID] = []
    public private(set) var showTidyTabsSuggestion = false
    @ObservationIgnored var tidyTabsDismissal = TidyTabsDismissal()
    public let meetings: CalendarMeetingsModel

    /// Runs on every clock tick; unchanged values must not invalidate the sidebar.
    func updateTidyTabsPresentation(candidates: [UUID], showSuggestion: Bool) {
        if tidyTabsCandidateIDs != candidates { tidyTabsCandidateIDs = candidates }
        if showTidyTabsSuggestion != showSuggestion { showTidyTabsSuggestion = showSuggestion }
    }

    /// Opens another browser window. Set by the composition root, which is the
    /// only layer that knows what a window is; nil in previews and tests.
    @ObservationIgnored public var windowOpener: (@MainActor (_ isPrivate: Bool) -> Void)?
    /// The app's other windows. Set by the composition root; nil in tests.
    @ObservationIgnored public var windowDirectory: (any BrowserWindowDirectory)?
    /// Takes a Chrome Web Store extension to its review. Set by the composition root.
    @ObservationIgnored public var extensionInstaller: (@MainActor (ChromeWebStoreID) -> Void)?
    @ObservationIgnored public var privateWindowsAllowed: (@MainActor () -> Bool)?
    @ObservationIgnored public var accountSyncAllowed: (@MainActor () -> Bool)?
    /// Sites kept as apps, newest list from `webAppStore`.
    public internal(set) var webApps: [WebApp] = []
    let webAppStore: (any WebAppStoring)?
    let webAppInstaller: (any WebAppInstalling)?
    /// The last queued write to `webAppStore`; reads wait for it.
    @ObservationIgnored var webAppWrite: Task<Void, Never>?
    /// Set by the composition root on the primary window. Nil in tests.
    @ObservationIgnored public var publishWorkspace: ((BrowserSession) -> Void)?
    /// Set by the composition root so every window shares one exclusion list.
    @ObservationIgnored public var onSensitiveHistoryChanged: ((BrowserSettings) -> Void)?
    public internal(set) var remoteTabs: [RemoteSyncedTab] = []

    @ObservationIgnored private let visits: VisitRecorder
    @ObservationIgnored let prerenderSchedule = SearchPrerenderSchedule()
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
        self.formHistory = features.formHistory
        self.suggestions = features.suggestions
        self.history = services.history
        self.bookmarks = services.bookmarks
        self.downloads = services.downloads
        self.updates = services.updates
        self.webAppStore = services.webApps
        self.webAppInstaller = services.webAppInstaller
        self.groupNames = GroupNameModel(naming: services.groupNaming)
        self.visits = VisitRecorder(history: services.history)
        self.settings = settings
        self.meetings = CalendarMeetingsModel(
            provider: services.calendar, isEnabled: settings.showsUpcomingMeetings
        )
        self.settingsStore = services.settings
        self.sessionStore = services.session
        self.logger = services.logger
        self.content = content
        self.lastTabCount = tabs.tabs.count
        var commands = CommandBarModel.Configuration(history: services.history, bookmarks: services.bookmarks)
        commands.searchRouting = settings.searchRouting
        self.commandBar = CommandBarModel(configuration: commands)
        tabs.signalHandler = self
        tabs.onChange = { [weak self] in self?.tabsChanged() }
        tabs.onNavigation = { [weak self] snapshot, id in
            guard let self else { return }
            visits.record(snapshot, navigationID: id, policy: SensitiveSitePolicy(settings: settings))
        }
        commandBar.onExecute = { [weak self] action in self?.execute(action) }
        split = tabs.session.splitLayout
        split.validate(against: Set(tabs.tabs.map(\.id)))
        Task { [weak self] in await self?.reloadWebApps() }
    }

    public func navigate(to url: URL) {
        showsSettings = false
        if let tab = selectedTab { tab.load(url) } else { tabs.newTab(url: url) }
    }

    public func pageContextChanged() {
        findPageContextChanged()
        autofill.pageChanged()
        otp.pageChanged()
        twoFactor.pageChanged()
        dismissFormSuggestions()
        Task { [weak self] in await self?.selectedTab?.announcePageSignals() }
    }
}
