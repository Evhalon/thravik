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

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 9) {
                icon
                Text(folder.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 96)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .scaleEffect(isDropTarget ? 1.08 : isHovering ? 1.04 : 1)
        .animation(.spring(duration: 0.25), value: isDropTarget)
        .animation(.spring(duration: 0.25), value: isHovering)
        .onHover { hovering in
            if hovering && !isHovering { onPrepare() }
            isHovering = hovering
        }
        .dropDestination(for: String.self, action: receive) { isDropTarget = $0 }
        .help("Open \(folder.name) — drag a favorite here to add it")
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Palette.accent.opacity(isDropTarget ? 0.32 : 0.18))
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Palette.accent.opacity(isDropTarget ? 0.62 : 0.24), lineWidth: Metric.hairWidth)
            Image(systemName: isDropTarget ? "tray.and.arrow.down.fill" : "folder.fill")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(Palette.accent.opacity(0.9))
            Text("\(folder.favoriteCount)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(Palette.accent.opacity(0.9)))
                .offset(x: 21, y: 21)
        }
        .frame(width: 62, height: 62)
        .shadow(color: Palette.accent.opacity(isDropTarget ? 0.42 : 0.16), radius: isDropTarget ? 16 : 7, y: 4)
    }

    private func receive(_ values: [String], at _: CGPoint) -> Bool {
        guard let value = values.first, let bookmarkID = UUID(uuidString: value) else { return false }
        onReceiveFavorite(bookmarkID)
        return true
    }
}
