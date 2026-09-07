import RedentDesign
import RedentKit
import SwiftUI

/// One Container: orb, name, default badge. Use/rename/delete sit in the menu.
struct ContainerManageRow: View {
    let container: BrowserContainer
    let tabCount: Int
    let isSpaceDefault: Bool
    let actions: Actions
    @State private var isHovering = false

    struct Actions {
        let onSetDefault: () -> Void
        let onMoveTab: () -> Void
        let onRename: () -> Void
        let onDelete: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            ChromeOrb(systemImage: icon, tint: tint, isSelected: isSpaceDefault, size: 28)
            titles
            Spacer(minLength: 0)
            if isSpaceDefault { ChromeBadge("Space default", tint: tint) }
            menu
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.chromeFill.opacity(isHovering || isSpaceDefault ? 1 : 0))
        }
        .contentShape(.rect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(container.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Text(tabCount == 1 ? "1 tab" : "\(tabCount) tabs")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private var menu: some View {
        ManageRowMenu {
            Button("Set as Space Default", action: actions.onSetDefault)
            Button("Move Current Tab Here", action: actions.onMoveTab)
            Button("Rename…", action: actions.onRename)
            Divider()
            Button("Delete Container", role: .destructive, action: actions.onDelete)
                .disabled(container.kind == .default)
        }
        .opacity(isHovering ? 1 : 0.35)
    }

    private var icon: String {
        switch container.kind {
        case .default: "person.fill"
        case .named: "person.2.fill"
        case .ephemeral: "flame.fill"
        }
    }

    private var tint: Color {
        switch container.kind {
        case .default: Palette.chromeSecondaryText
        case .named: SpacePalette.color(SpaceIdentity.derived(from: container.id).colorToken)
        case .ephemeral: SpacePalette.color("coral")
        }
    }
}
