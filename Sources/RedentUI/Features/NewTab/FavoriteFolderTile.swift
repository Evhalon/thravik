import RedentDesign
import SwiftUI

/// A favorites collection that accepts a dragged saved page.
struct FavoriteFolderTile: View {
    let folder: FavoriteFolder
    let onOpen: () -> Void
    let onPrepare: () -> Void
    let onReceiveFavorite: (UUID) -> Void

    @State private var isHovering = false
    @State private var isDropTarget = false
    @State private var receivedCount = 0

    private let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 9) {
                icon
                Text(folder.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isDropTarget ? Palette.chromeText : Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 96)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .scaleEffect(isDropTarget ? 1.12 : isHovering ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDropTarget)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            if hovering && !isHovering { onPrepare() }
            isHovering = hovering
        }
        .dropDestination(for: String.self, action: receive) { isDropTarget = $0 }
        .help("Open \(folder.name) — drag a favorite here to add it")
    }

    private var icon: some View {
        ZStack {
            shape.fill(Palette.accent.opacity(isDropTarget ? 0.34 : 0.18))
            shape.strokeBorder(Palette.accent.opacity(isDropTarget ? 0.9 : 0.24),
                               lineWidth: isDropTarget ? 1.5 : Metric.hairWidth)
            Image(systemName: isDropTarget ? "folder.fill.badge.plus" : "folder.fill")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(Palette.accent.opacity(0.9))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: receivedCount)
            countBadge
        }
        .frame(width: 62, height: 62)
        .compositingGroup()
        .shadow(color: Palette.accent.opacity(isDropTarget ? 0.55 : 0.16), radius: isDropTarget ? 18 : 7, y: 4)
    }

    private var countBadge: some View {
        Text("\(folder.favoriteCount)")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .contentTransition(.numericText())
            .animation(.snappy, value: folder.favoriteCount)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Palette.accent.opacity(0.9)))
            .offset(x: 21, y: 21)
    }

    private func receive(_ values: [String], at _: CGPoint) -> Bool {
        guard let value = values.first, let bookmarkID = UUID(uuidString: value) else { return false }
        receivedCount += 1
        onReceiveFavorite(bookmarkID)
        return true
    }
}
