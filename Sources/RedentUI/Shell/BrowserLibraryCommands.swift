import SwiftUI

/// Everything the browser has saved: bookmarks, downloads, logins, and the
/// screens that manage them.
struct BrowserLibraryCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandMenu("Library") {
            Button(bookmarkTitle, action: toggleBookmark)
                .keyboardShortcut("d")
                .disabled(!(model?.hasPage ?? false))
            Button("Bookmarks…") { model?.sheet = .bookmarks }
                .keyboardShortcut("b", modifiers: [.command, .option])
                .disabled(model == nil)
            Divider()
            Button("Downloads…") { model?.sheet = .downloads }
                .keyboardShortcut("j", modifiers: [.command, .shift])
                .disabled(model == nil)
            Divider()
            Button("Passwords…") { model?.sheet = .passwords }
            Button("Authenticator…") { model?.sheet = .authenticator }
            Button("Tab Timeline…") { model?.sheet = .timeline }
                .keyboardShortcut("y", modifiers: [.command, .shift])
            Button("Site Privacy…") { model?.sheet = .sitePrivacy }
                .keyboardShortcut("i", modifiers: [.command, .shift])
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
