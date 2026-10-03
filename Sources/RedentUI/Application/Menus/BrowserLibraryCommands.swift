import RedentKit
import SwiftUI

/// Everything the browser has saved: bookmarks, downloads, logins, and the
/// screens that manage them.
struct BrowserLibraryCommands: Commands {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some Commands {
        CommandMenu("Library") {
            Button(bookmarkTitle, action: toggleBookmark)
                .shortcut(.bookmarkPage, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            Button("Bookmarks…") { model?.sheet = .bookmarks }
                .shortcut(.showBookmarks, bindings: bindings)
                .disabled(model == nil)
            Divider()
            Button("Downloads…") { model?.sheet = .downloads }
                .shortcut(.showDownloads, bindings: bindings)
                .disabled(model == nil)
            Divider()
            Button("Passwords…") { model?.sheet = .passwords }
            Button("Authenticator…") { model?.sheet = .authenticator }
            Button("Tab Timeline…") { model?.sheet = .timeline }
                .shortcut(.showTimeline, bindings: bindings)
            Button("Site Privacy…") { model?.sheet = .sitePrivacy }
                .shortcut(.showSitePrivacy, bindings: bindings)
            Divider()
            Button("Import from Another Browser…") { model?.sheet = .importBrowser }
        }
    }

    private func toggleBookmark() {
        guard let model else { return }
        Task { await model.toggleBookmark() }
    }

    private var bookmarkTitle: String {
        (model?.chrome.isBookmarked ?? false) ? "Remove Bookmark" : "Add Bookmark…"
    }
}
