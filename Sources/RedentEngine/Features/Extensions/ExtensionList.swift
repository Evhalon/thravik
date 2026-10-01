import AppKit
import SwiftUI

/// The popover under the puzzle piece: every extension, with its icon and
/// badge, and the way to Settings.
struct ExtensionList: View {
    let items: [ExtensionToolbarItem]
    let onPick: (ExtensionToolbarItem) -> Void
    let onOptions: (ExtensionToolbarItem) -> Void
    let onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Extensions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            ForEach(items) { item in
                ExtensionListRow(item: item, onPick: { onPick(item) }, onOptions: { onOptions(item) })
            }
            Divider().padding(.vertical, 4)
            Button(action: onManage) {
                Label("Manage Extensions", systemImage: "gearshape")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 280)
    }
}

private struct ExtensionListRow: View {
    let item: ExtensionToolbarItem
    let onPick: () -> Void
    let onOptions: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onPick) {
                HStack(spacing: 10) {
                    icon
                    Text(item.name).font(.system(size: 13)).lineLimit(1)
                    Spacer(minLength: 4)
                    if !item.badge.isEmpty { badge }
                    if !item.isRunning { Text("Off").font(.system(size: 11)).foregroundStyle(.secondary) }
                    if !item.unsupportedFeatures.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                            .help("Needs Chrome-only features: \(item.unsupportedFeatures.joined(separator: ", "))")
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!item.hasAction)
            if item.hasOptions {
                Button(action: onOptions) { Image(systemName: "ellipsis") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Options")
            }
        }
        .opacity(item.isRunning ? 1 : 0.5)
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.primary.opacity(0.08) : .clear))
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var icon: some View {
        if let image = item.icon {
            Image(nsImage: image).resizable().interpolation(.high).frame(width: 18, height: 18)
        } else {
            Image(systemName: "puzzlepiece.extension.fill").frame(width: 18, height: 18)
        }
    }

    private var badge: some View {
        Text(item.badge)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .frame(minHeight: 15)
            .background(Capsule().fill(Color.accentColor))
    }
}
