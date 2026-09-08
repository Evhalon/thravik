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
    public let address = AddressBarModel()
    public let suggestions: AddressSuggestionsModel
    public let history: any HistoryStoring
    public let bookmarks: any BookmarkStoring

    public var settings: BrowserSettings { didSet { settingsChanged(from: oldValue) } }
    public var sheet: SheetRoute?
    public var showsCommandBar = false
    public var actionError: String?
    /// The temporary tab whose deadline passed while the user was reading it.
    public var expiredTabID: UUID?
    public let commandBar: CommandBarModel
    /// Chrome hidden entirely — "widen the screen and hide the tabs".
    public var isFocusMode: Bool = false
    /// Which tabs this window shows side by side, and which pane has the chrome.
    public var split = SplitLayout()
    /// Bumped so the new-tab search field can steal first responder from the
    /// sidebar address field after AppKit reassigns it.
    public var centerSearchFocusEpoch: UInt = 0

    @ObservationIgnored private let visits: VisitRecorder
    /// `internal` rather than `private`: the persistence policy lives in a
    /// sibling file to stay under the line limit.
    @ObservationIgnored var hasUnsavedChanges = false
    @ObservationIgnored var lastSave = Date.distantPast
    @ObservationIgnored var hasUnsavedSettings = false
    @ObservationIgnored var saveTask: Task<Void, Never>?
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
        self.suggestions = features.suggestions
        self.history = services.history
        self.bookmarks = services.bookmarks
        self.visits = VisitRecorder(history: services.history)
        self.settings = settings
        self.settingsStore = services.settings
        self.sessionStore = services.session
        self.logger = services.logger
        self.content = content
        var commands = CommandBarModel.Configuration(history: services.history, bookmarks: services.bookmarks)
        commands.searchEngine = settings.searchEngine
        self.commandBar = CommandBarModel(configuration: commands)
        tabs.signalHandler = self
        tabs.onChange = { [weak self] in
            guard let self else { return }
            // Building the id set costs an allocation per change event, and an
            // unsplit window has no pane to invalidate.
            if split.isSplit { split.validate(against: Set(tabs.tabs.map(\.id))) }
            hasUnsavedChanges = true
            refreshCommandContext()
        }
        tabs.onNavigation = { [weak self] snapshot, id in self?.visits.record(snapshot, navigationID: id) }
        commandBar.onExecute = { [weak self] action in self?.execute(action) }
        split = tabs.session.splitLayout
        split.validate(against: Set(tabs.tabs.map(\.id)))
    }

    public func navigate(to url: URL) {
        if let tab = selectedTab { tab.load(url) } else { tabs.newTab(url: url) }
    }

    public func submitAddress() {
        // An armed dropdown row wins over re-parsing the raw text.
        if let row = suggestions.highlightedRow {
            suggestions.close()
            address.finishEditing()
            navigate(to: row.url)
            return
        }
        suggestions.close()
        guard let url = address.commit(using: settings.searchEngine) else { return }
        navigate(to: url)
    }

    public func open(_ url: URL, inNewTab: Bool) {
        suggestions.close()
        address.finishEditing()
        if inNewTab { tabs.newTab(url: url) } else { navigate(to: url) }
    }

    public func queryChanged(_ text: String, from source: AddressSuggestionsModel.Source) {
        suggestions.update(query: text, from: source, searchEngine: settings.searchEngine, spaceID: currentSpaceID)
    }

    /// Arrow keys in a TextField never reach `onMoveCommand`. The command bar
    /// already uses `onKeyPress`; the address fields must do the same.
    public func moveSuggestionHighlight(by offset: Int, from source: AddressSuggestionsModel.Source) -> Bool {
        guard suggestions.isOpen(for: source) else { return false }
        suggestions.moveHighlight(by: offset)
        return true
    }

    /// One timer for the whole window, per AGENTS.md §4 — not one per code.
    public func tick(_ date: Date) {
        otp.tick(date)
        otp.dismissIfPageChanged(selectedTab?.url)
        tabs.sweepHibernation(now: date, keeping: split.visibleTabIDs(primary: tabs.selectedID))
        if let expired = tabs.sweepExpiredTabs(now: date) { expiredTabID = expired }
        autofill.setSpace(selectedTab?.snapshot.spaceID ?? currentSpaceID)
        autofill.observe(selectedTab?.origin)
        persistIfNeeded(date)
    }

    private func settingsChanged(from old: BrowserSettings) {
        // A sidebar drag writes this on every frame. Encoding and storing the
        // settings that often is what made the drag feel heavy, so the write is
        // coalesced onto the window clock like the workspace itself.
        hasUnsavedSettings = true
        tabs.apply(settings: settings)
        if old.offersPasswordSave != settings.offersPasswordSave {
            autofill.setEnabled(settings.offersPasswordSave)
        }
        if !settings.showsTOTPButton { otp.fieldDisappeared() }
    }
}
