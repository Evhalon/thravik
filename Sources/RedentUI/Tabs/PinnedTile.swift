import RedentDesign
import RedentKit
import SwiftUI

/// One pinned tab as a launcher tile: its icon alone, on glass. The title
/// lives in the tooltip; a tile is recognised by its icon.
struct PinnedTile: View {
    let tab: any BrowserTab
    let isSelected: Bool
    let actions: PinnedTileActions

    @State private var isHovering = false
    @State private var isRenaming = false
    @State private var draftName = ""

    private static let corner: CGFloat = 11

    var body: some View {
        icon
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { background }
            .overlay(alignment: .topTrailing) { audioBadge }
            .contentShape(.rect(cornerRadius: Self.corner))
            .onTapGesture(perform: actions.row.onSelect)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
            }
            .help(tab.snapshot.displayTitle)
            .contextMenu { PinnedTileMenu(tab: tab, actions: actions, onRename: beginRename) }
            .alert("Rename Tab", isPresented: $isRenaming) {
                TextField(tab.snapshot.title, text: $draftName)
                Button("Rename") { actions.onRename(draftName) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Leave the name empty to use the page's own title.")
            }
    }

    private var icon: some View {
        ZStack {
            // Pins are launchers: a sleeping pin keeps its full colour, so the
            // grid stays recognisable by icon alone.
            FaviconView(data: tab.snapshot.faviconData, host: tab.origin?.displayHost, size: 20)
            if tab.isLoading {
                CountdownRing(fraction: max(0.06, tab.progress), lineWidth: 1.6, tint: Palette.accent)
                    .frame(width: 25, height: 25)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
        ZStack {
            shape.fill(.white.opacity(isSelected ? 0.16 : isHovering ? 0.1 : 0.06))
            shape.strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(isSelected ? 0.34 : 0.12), .white.opacity(0.03)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: Metric.hairWidth
            )
        }
        .shadow(color: .black.opacity(isSelected ? 0.22 : 0), radius: 7, y: 2)
    }

    @ViewBuilder
    private var audioBadge: some View {
        if tab.isPlayingAudio || tab.isMuted {
            TabAudioButton(tab: tab)
                .scaleEffect(0.8)
                .padding(2)
        }
    }

    private func beginRename() {
        draftName = tab.snapshot.customTitle ?? ""
        isRenaming = true
    }
}
