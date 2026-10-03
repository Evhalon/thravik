import RedentDesign
import RedentKit
import SwiftUI

/// Space orbs under the sidebar. Scroll or select to switch.
struct SpacePageDots: View {
    let spaces: [BrowserSpace]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    var onManage: (() -> Void)?
    var updates: UpdateModel?
    @State private var position = SpaceScrollPosition()

    var body: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: Metric.hairWidth)
                .padding(.horizontal, 8)
            HStack(spacing: 8) {
                SpaceOrbScroller(
                    spaces: spaces, selectedID: selectedID, onSelect: onSelect, position: $position
                )
                if let onManage {
                    manageButton(action: onManage)
                }
                if let updates { SpaceUpdateButton(updates: updates) }
            }
            if position.hasOverflow { pageIndicator }
        }
        .padding(.top, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spaces")
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ProgressView(value: position.progress)
                .progressViewStyle(.linear)
                .frame(width: 52)
            Text("\(position.page) of \(position.pageCount)")
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Spaces page \(position.page) of \(position.pageCount)")
    }

    private func manageButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 22, height: 22)
                .background { Circle().strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth) }
                .contentShape(.circle)
        }
        .buttonStyle(PressScaleStyle())
        .help("Manage Spaces")
    }
}
