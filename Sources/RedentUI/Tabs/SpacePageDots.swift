import RedentDesign
import RedentKit
import SwiftUI

/// Arc-style Space orbs under the sidebar. Click or swipe to switch.
struct SpacePageDots: View {
    let spaces: [BrowserSpace]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    var onManage: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: Metric.hairWidth)
                .padding(.horizontal, 8)
            HStack(spacing: 8) {
                ForEach(spaces) { space in
                    Button {
                        onSelect(space.id)
                    } label: {
                        SpaceOrb(space: space, isSelected: space.id == selectedID, size: 24)
                    }
                    .buttonStyle(PressScaleStyle())
                    .help(space.name)
                    .accessibilityLabel(space.name)
                }
                if let onManage {
                    Button(action: onManage) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Palette.chromeSecondaryText)
                            .frame(width: 22, height: 22)
                            .background {
                                Circle().strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
                            }
                    }
                    .buttonStyle(PressScaleStyle())
                    .help("Manage Spaces")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
        .contentShape(.rect)
        .gesture(swipe)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spaces")
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            let step = value.translation.width < 0 ? 1 : -1
            if let next = SpacePaging.neighbor(of: selectedID, in: spaces.map(\.id), step: step) {
                onSelect(next)
            }
        }
    }
}
