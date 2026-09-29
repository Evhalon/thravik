import RedentDesign
import RedentKit
import SwiftUI

/// One Space in the manager: orb, name, quiet count. Actions live in the menu.
struct WorkspaceSpaceRow: View {
    let space: BrowserSpace
    let tabCount: Int
    let isSelected: Bool
    let actions: Actions
    @State private var isHovering = false

    struct Actions {
        let canDelete: Bool
        let onSelect: () -> Void
        let onRename: () -> Void
        let onDelete: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            SpaceOrb(space: space, isSelected: isSelected, size: 28)
            titles
            Spacer(minLength: 0)
            if isSelected { ChromeBadge("Open", tint: tint) }
            menu
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background { rowFill }
        .contentShape(.rect)
        .onTapGesture(perform: actions.onSelect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
        .accessibilityLabel(space.name)
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(space.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Text(tabCount == 1 ? "1 tab" : "\(tabCount) tabs")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private var menu: some View {
        ManageRowMenu {
            Button("Switch to this Space", action: actions.onSelect)
            Button("Rename…", action: actions.onRename)
            Divider()
            Button("Delete Space", role: .destructive, action: actions.onDelete)
                .disabled(!actions.canDelete)
        }
        .opacity(isHovering ? 1 : 0.35)
    }

    private var tint: Color {
        SpacePalette.color(
            SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken).colorToken
        )
    }

    private var rowFill: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(isSelected ? tint.opacity(0.14) : Palette.chromeFill.opacity(isHovering ? 1 : 0))
    }
}
