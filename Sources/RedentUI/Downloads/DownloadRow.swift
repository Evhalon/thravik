import RedentDesign
import RedentKit
import SwiftUI

/// One file in the downloads list: what it is, how far along, and the one
/// action that makes sense for the state it is in.
struct DownloadRow: View {
    let item: DownloadItem
    let onCancel: () -> Void
    let onReveal: () -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.filename)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                caption
                if item.isActive { progressBar }
            }

            Spacer(minLength: Metric.tightGutter)
            action
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .onTapGesture(count: 2, perform: onOpen)
        .contextMenu {
            Button("Show in Finder", action: onReveal).disabled(item.destination == nil)
            Button("Remove from List", action: onRemove)
        }
    }

    private var caption: some View {
        Text(captionText)
            .font(.system(size: 10.5))
            .foregroundStyle(item.state.isFailure ? Palette.danger : Palette.chromeSecondaryText)
            .lineLimit(1)
    }

    private var captionText: String {
        switch item.state {
        case .running: [item.host, item.sizeCaption].compactMap { $0 }.joined(separator: " — ")
        case .finished: [item.host, DownloadItem.format(item.bytesReceived)]
            .compactMap { $0 }.joined(separator: " — ")
        case .cancelled: "Cancelled"
        case .failed(let reason): reason
        }
    }

    private var progressBar: some View {
        ProgressView(value: item.fraction ?? 0, total: 1)
            .progressViewStyle(.linear)
            .opacity(item.fraction == nil ? 0.45 : 1)
            .frame(height: 3)
    }

    @ViewBuilder
    private var action: some View {
        if item.isActive {
            Button("Stop", action: onCancel).controlSize(.small)
        } else if item.state == .finished {
            Button("Show", action: onReveal).controlSize(.small)
        } else {
            Button("Remove", action: onRemove).controlSize(.small)
        }
    }

    private var symbol: String {
        switch item.state {
        case .running: "arrow.down.circle"
        case .finished: "doc.fill"
        case .cancelled: "xmark.circle"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch item.state {
        case .running: Palette.accent
        case .finished: Palette.chromeText
        case .cancelled: Palette.chromeSecondaryText
        case .failed: Palette.danger
        }
    }
}

private extension DownloadItem.State {
    var isFailure: Bool { if case .failed = self { true } else { false } }
}
