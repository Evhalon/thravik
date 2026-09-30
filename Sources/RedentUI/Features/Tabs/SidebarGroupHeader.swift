import RedentDesign
import RedentKit
import SwiftUI

/// A cluster's label: favicon, name, chevron. It stands for no page, so it
/// is never selected — clicking it folds or unfolds the tabs beneath.
struct SidebarGroupHeader: View {
    /// Nil while Apple Intelligence is still naming the group.
    let title: String?
    /// What the group is called before any topic: its site.
    let siteName: String
    let iconTab: (any BrowserTab)?
    let isCollapsed: Bool
    let actions: Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Actions {
        let onToggle: () -> Void
        let onClose: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            label
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
                .rotationEffect(.degrees(isCollapsed ? -90 : 0))
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .frame(height: Metric.tabRowHeight)
        .contentShape(.rect)
        .onTapGesture(perform: actions.onToggle)
        .help(isCollapsed ? "Show tabs" : "Hide tabs")
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title ?? siteName)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Close Group", actions.onClose)
        .contextMenu {
            Button("Close Group", role: .destructive, action: actions.onClose)
        }
        .animation(.easeOut(duration: 0.16), value: isCollapsed)
    }

    private var label: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            FaviconView(
                data: iconTab?.snapshot.faviconData,
                host: iconTab?.origin?.displayHost ?? siteName,
                size: 16
            )
            name
        }
    }

    /// Each new name is a new view, so it arrives through the reveal rather
    /// than morphing out of the old one.
    private var name: some View {
        ZStack(alignment: .leading) {
            if let title {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .id(title)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.textReveal))
            }
        }
        .animation(.easeOut(duration: 0.2), value: title)
    }
}
