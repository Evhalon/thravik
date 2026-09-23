import RedentDesign
import RedentKit
import SwiftUI

/// One file in the downloads list: its type icon, how far along it is, and the
/// one action that makes sense for the state it is in. A finished file opens
/// on click and can be dragged straight out into Finder or another app.
struct DownloadRow: View {
    let item: DownloadItem
    let onCancel: () -> Void
    let onReveal: () -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            DownloadFileIcon(filename: item.filename)
                .opacity(item.state == .finished || item.isActive ? 1 : 0.5)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.filename)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                DownloadCaption(item: item)
                if item.isActive { DownloadProgressBar(fraction: item.fraction) }
            }
            Spacer(minLength: Metric.tightGutter)
            action
        }
        .padding(.horizontal, 8)
        .frame(height: 48)
        .background(hoverFill, in: .rect(cornerRadius: Metric.smallRadius))
        .contentShape(.rect)
        .onHover { isHovering = $0 }
        .onTapGesture(perform: onOpen)
        .onDrag(fileProvider)
        .contextMenu {
            Button("Open", action: onOpen).disabled(item.state != .finished)
            Button("Show in Finder", action: onReveal).disabled(item.destination == nil)
            Divider()
            Button("Remove from List", action: onRemove)
        }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    private var hoverFill: Color {
        isHovering && item.state == .finished ? Palette.chromeSecondaryText.opacity(0.12) : .clear
    }

    /// Hands the finished file itself to the drop target, so it copies or
    /// moves like any Finder drag.
    private func fileProvider() -> NSItemProvider {
        guard item.state == .finished, let url = item.destination,
              let provider = NSItemProvider(contentsOf: url) else { return NSItemProvider() }
        provider.suggestedName = url.lastPathComponent
        return provider
    }

    @ViewBuilder
    private var action: some View {
        if item.isActive {
            RowIconButton(symbol: "xmark.circle.fill", help: "Stop", action: onCancel)
        } else if item.state == .finished {
            RowIconButton(symbol: "magnifyingglass.circle.fill", help: "Show in Finder", action: onReveal)
                .opacity(isHovering ? 1 : 0)
        } else {
            RowIconButton(symbol: "xmark.circle.fill", help: "Remove from List", action: onRemove)
                .opacity(isHovering ? 1 : 0.6)
        }
    }
}

/// The small round glyph button at the trailing edge of a row.
private struct RowIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .help(help)
        .accessibilityLabel(help)
    }
}
