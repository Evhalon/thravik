import Foundation
import RedentKit
import SwiftUI
@testable import RedentUI

/// A window model wired entirely to in-memory doubles, so window-level state can
/// be exercised without a Keychain, a database, or a WebKit process.
@MainActor
func makeTestBrowserModel(tabs: any BrowserControlling = FakeBrowser()) -> BrowserModel {
    let history = SilentHistory()
    let bookmarks = InertBookmarkStore()
    let services = BrowserServices(
        history: history,
        bookmarks: bookmarks,
        settings: InertSettingsStore(),
        session: InertSessionStore(),
        logger: SilentLogger()
    )
    let features = BrowserFeatures(
        autofill: AutofillCoordinator(store: FakeCredentialStore(), logger: SilentLogger()),
        otp: OTPCoordinator(store: FakeTOTPStore(), generator: FakeGenerator(), logger: SilentLogger()),
        suggestions: AddressSuggestionsModel(
            engine: SuggestionEngine(history: history, bookmarks: bookmarks)
        )
    )
    return BrowserModel(
        tabs: tabs,
        services: services,
        features: features,
        settings: BrowserSettings()
    ) { _ in AnyView(EmptyView()) }
}

struct InertBookmarkStore: BookmarkStoring {
    func all(in spaceID: UUID?) async -> [Bookmark] { [] }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}

struct InertSettingsStore: SettingsStoring {
    func load() -> BrowserSettings { BrowserSettings() }
    func save(_ settings: BrowserSettings) {}
}

struct InertSessionStore: SessionStoring {
    func load() -> BrowserSession { BrowserSession() }
    func save(_ session: BrowserSession) {}
}
