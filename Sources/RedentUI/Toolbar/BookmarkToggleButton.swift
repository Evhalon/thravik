import RedentDesign
import RedentKit
import SwiftUI

/// The star in the address bar. The lookup and the toggle live on the window
/// model, so this control and ⌘D can never disagree about what is saved.
struct BookmarkToggleButton: View {
    @Bindable var model: BrowserModel

    var body: some View {
        Button { Task { await model.toggleBookmark() } } label: {
            Image(systemName: model.chrome.isBookmarked ? "star.fill" : "star")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(model.chrome.isBookmarked ? Palette.accent : Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .help(model.chrome.isBookmarked ? "Remove bookmark (⌘D)" : "Bookmark this page (⌘D)")
    }
}
