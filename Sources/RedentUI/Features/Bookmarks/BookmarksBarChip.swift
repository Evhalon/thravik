import RedentDesign
import RedentKit
import SwiftUI

/// One page on the bar: favicon, truncated title, click to go.
struct BookmarksBarChip: View {
    let bookmark: Bookmark
    let callbacks: BookmarksBarCallbacks
    @State private var isHovering = false
    @State private var fetchedIcon: Data?

    private typealias Chip = BookmarksBarChipMetrics

    var body: some View {
        Button { callbacks.onOpen(bookmark.url) } label: {
            HStack(spacing: Chip.iconSpacing) {
                FaviconView(data: bookmark.faviconData ?? fetchedIcon, host: host, size: Chip.faviconSize)
                    .accessibilityHidden(true)
                Text(bookmark.displayTitle)
                    .font(.system(size: Chip.titleSize))
                    .foregroundStyle(Palette.chromeText)
                    .lineLimit(1)
            }
            .padding(.horizontal, Chip.horizontalPadding)
            .padding(.vertical, Chip.verticalPadding)
            .frame(maxWidth: Chip.maxWidth)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .chromeHoverEffect(isActive: isHovering, radius: Metric.smallRadius)
        .onHover { isHovering = $0 }
        .help(bookmark.displayTitle)
        .accessibilityLabel(bookmark.displayTitle)
        .accessibilityHint("Opens the bookmark. Command-click opens it in a background tab.")
        .contextMenu { BookmarksBarMenu(bookmark: bookmark, callbacks: callbacks) }
        .task(id: host) { await loadIcon() }
    }

    private var host: String? { bookmark.origin?.displayHost }

    private func loadIcon() async {
        guard bookmark.faviconData == nil, let host else { return }
        fetchedIcon = await SiteIconLoader.shared.icon(for: host)
    }
}
