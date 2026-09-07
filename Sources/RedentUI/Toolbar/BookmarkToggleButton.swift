import RedentDesign
import RedentKit
import SwiftUI

/// The star in the address bar. Owns its own lookup rather than pushing
/// bookmark state into the browser model, since only this control cares.
struct BookmarkToggleButton: View {
    @Bindable var model: BrowserModel
    @State private var existing: Bookmark?

    var body: some View {
        Button(action: toggle) {
            Image(systemName: existing == nil ? "star" : "star.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(existing == nil ? Palette.chromeSecondaryText : Palette.accent)
        }
        .buttonStyle(PressScaleStyle())
        .help(existing == nil ? "Bookmark this page" : "Remove bookmark")
        .task(id: model.selectedTab?.url) { await refresh() }
    }

    private func refresh() async {
        guard let url = model.selectedTab?.url else { return existing = nil }
        existing = await model.bookmarks.bookmark(for: url)
    }

    private func toggle() {
        guard let tab = model.selectedTab, let url = tab.url else { return }
        let title = tab.title
        Task {
            if let existing {
                await model.bookmarks.delete(existing.id)
            } else {
                await model.bookmarks.save(
                    Bookmark(url: url, title: title, isFavorite: true)
                )
            }
            await refresh()
        }
    }
}
