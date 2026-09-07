import RedentDesign
import RedentKit
import SwiftUI

/// Current Space as a quiet identity chip. Menu switches; orbs below do the rest.
struct SpaceSwitcher: View {
    let model: BrowserModel
    @State private var isHovering = false

    var body: some View {
        Menu {
            ForEach(model.tabs.session.spaces) { space in
                Button {
                    model.execute(.focusSpace(space.id))
                } label: {
                    Label(space.name, systemImage: icon(for: space))
                }
            }
            Divider()
            Button("Manage Spaces…") { model.sheet = .spaces }
            Button("Tab Groups…") { model.sheet = .groups }
            Button("Containers…") { model.sheet = .containers }
            Button("Command Bar…", action: model.showCommands)
        } label: {
            label
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .help("Switch Space")
        .onHover { isHovering = $0 }
    }

    private var label: some View {
        HStack(spacing: 8) {
            if let space = current {
                SpaceOrb(space: space, isSelected: true, size: 22)
            }
            Text(current?.name ?? "Spaces")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .padding(.horizontal, 4)
        .frame(height: Metric.tabRowHeight)
        .contentShape(.rect)
        .chromeHoverEffect(isActive: isHovering, radius: Metric.mediumRadius)
    }

    private var current: BrowserSpace? {
        model.tabs.session.spaces.first { $0.id == model.tabs.session.selectedSpaceID }
    }

    private func icon(for space: BrowserSpace) -> String {
        SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken).icon
    }
}
