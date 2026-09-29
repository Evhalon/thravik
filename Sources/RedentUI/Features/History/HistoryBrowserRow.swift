import RedentDesign
import RedentKit
import SwiftUI

/// One visited page: its icon, title and site, and the time of the visit.
/// A click opens it; ⌘-click opens it in a new tab.
struct HistoryBrowserRow: View {
    let entry: HistoryEntry
    let isSelected: Bool
    let actions: Actions
    @State private var isHovering = false
    @State private var icon: Data?

    struct Actions {
        let onOpen: (_ inNewTab: Bool) -> Void
        let onDelete: () -> Void
        let onForgetSite: () -> Void
    }

    var body: some View {
        HStack(spacing: 10) {
            FaviconView(data: icon, host: host, size: 18)
            Text(entry.displayTitle)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
                .layoutPriority(1)
            Text(host ?? "")
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.chromeSecondaryText)
                .lineLimit(1)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(background, in: .rect(cornerRadius: Metric.smallRadius, style: .continuous))
        .contentShape(.rect)
        .onHover { isHovering = $0 }
        .onTapGesture { actions.onOpen(NSEvent.modifierFlags.contains(.command)) }
        .contextMenu { menu }
        .help(entry.url.absoluteString)
        .task(id: host) { await loadIcon() }
    }

    private var host: String? { entry.origin?.displayHost }

    private var background: Color {
        if isSelected { return Palette.accent.opacity(0.18) }
        return isHovering ? Palette.chromeSecondaryText.opacity(0.1) : .clear
    }

    /// The time stays put until the pointer arrives, then gives way to the
    /// delete button in the same spot — no column of trash cans at rest.
    @ViewBuilder
    private var trailing: some View {
        if isHovering {
            Button(action: actions.onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            .buttonStyle(PressScaleStyle())
            .help("Remove from History")
            .frame(width: 52, alignment: .trailing)
        } else {
            Text(entry.lastVisit, format: .dateTime.hour().minute())
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 52, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button("Open") { actions.onOpen(false) }
        Button("Open in New Tab") { actions.onOpen(true) }
        Button("Copy Link", action: copyLink)
        Divider()
        Button("Remove from History", action: actions.onDelete)
        if let host {
            Button("Remove All from \(host)", action: actions.onForgetSite)
        }
    }

    private func copyLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.url.absoluteString, forType: .string)
    }

    private func loadIcon() async {
        guard let host else { return }
        icon = await SiteIconLoader.shared.icon(for: host)
    }
}
