import RedentKit
import RedentDesign
import SwiftUI

/// The favicon + title pair shared by both tab strips, so a tab looks like the
/// same object whichever layout it is rendered in.
struct TabRowLabel: View {
    let tab: any BrowserTab
    var isSelected: Bool = false
    var iconSize: CGFloat = 16

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            icon
            if tab.snapshot.isTemporary {
                Image(systemName: "clock.badge.xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Text(tab.snapshot.displayTitle)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isSelected ? Palette.chromeText : Palette.chromeSecondaryText)
        }
        .opacity(tab.isHibernated ? 0.6 : 1)
        .help(helpText)
    }

    private var icon: some View {
        ZStack {
            FaviconView(data: tab.snapshot.faviconData, host: tab.origin?.displayHost, size: iconSize)
                .saturation(tab.isHibernated ? 0.25 : 1)
            if tab.isLoading {
                CountdownRing(fraction: max(0.06, tab.progress), lineWidth: 1.6, tint: Palette.accent)
                    .frame(width: iconSize + 7, height: iconSize + 7)
            }
        }
        .frame(width: iconSize + 7, height: iconSize + 7)
    }

    private var helpText: String {
        let title = tab.snapshot.displayTitle
        if tab.snapshot.isTemporary {
            return "\(title) — temporary: no history, storage discarded on close"
        }
        return tab.isHibernated ? "\(title) — sleeping to save memory" : title
    }
}
