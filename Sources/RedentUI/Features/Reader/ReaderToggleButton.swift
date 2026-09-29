import RedentDesign
import RedentKit
import SwiftUI

/// Beside the star: lays the page's article over it, or takes it away again.
struct ReaderToggleButton: View {
    @Bindable var model: BrowserModel

    var body: some View {
        Button(action: model.toggleReader) {
            Image(systemName: "text.page")
                .symbolVariant(model.isReaderActive ? .fill : .none)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(model.isReaderActive ? Palette.accent : Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .help(model.isReaderActive ? "Hide Reader (⌃⌘R)" : "Show Reader (⌃⌘R)")
        .accessibilityLabel(model.isReaderActive ? "Hide Reader" : "Show Reader")
    }
}
