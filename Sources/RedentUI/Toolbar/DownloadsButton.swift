import RedentDesign
import SwiftUI

/// The downloads control in the toolbar. It is not there at all until
/// something has been fetched — chrome that does nothing is chrome in the way.
struct DownloadsButton: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if !model.downloads.isEmpty {
            Button { model.sheet = .downloads } label: {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tint)
                    .overlay(alignment: .topTrailing) { badge }
            }
            .buttonStyle(PressScaleStyle())
            .help(helpText)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if model.downloads.hasUnseenCompletion {
            Circle()
                .fill(Palette.accent)
                .frame(width: 5, height: 5)
                .offset(x: 3, y: -2)
        }
    }

    private var isActive: Bool { !model.downloads.activeItems.isEmpty }

    private var symbol: String {
        isActive ? "arrow.down.circle.fill" : "arrow.down.circle"
    }

    private var tint: Color {
        isActive || model.downloads.hasUnseenCompletion
            ? Palette.accent
            : Palette.chromeSecondaryText
    }

    private var helpText: String {
        let active = model.downloads.activeItems.count
        return active > 0 ? "\(active) downloading" : "Downloads"
    }
}
