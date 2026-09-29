import RedentDesign
import RedentKit
import SwiftUI

/// A named group in the manager. Count is caption; mutate via the menu.
struct GroupManageRow: View {
    let group: BrowserGroup
    let onRename: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            ChromeOrb(
                systemImage: "folder.fill",
                tint: SpacePalette.color(group.colorToken),
                size: 26
            )
            titles
            Spacer(minLength: 0)
            ManageRowMenu {
                Button("Rename…", action: onRename)
                Button("Close All Tabs", role: .destructive, action: onClose)
                Button("Delete Group", role: .destructive, action: onDelete)
            }
            .opacity(isHovering ? 1 : 0.35)
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.chromeFill.opacity(isHovering ? 1 : 0))
        }
        .contentShape(.rect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(group.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Text(group.tabIDs.count == 1 ? "1 tab" : "\(group.tabIDs.count) tabs")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }
}
