import RedentDesign
import RedentKit
import SwiftUI

/// Scrolls the Space orbs while keeping the selected one in view.
struct SpaceOrbScroller: View {
    let spaces: [BrowserSpace]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    @Binding var position: SpaceScrollPosition

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) { orbs }
                .scrollIndicators(.never)
                .onScrollGeometryChange(for: SpaceScrollPosition.self) { geometry in
                    SpaceScrollPosition(
                        offset: geometry.contentOffset.x + geometry.contentInsets.leading,
                        contentWidth: geometry.contentSize.width,
                        viewportWidth: geometry.containerSize.width
                    )
                } action: { _, updatedPosition in
                    position = updatedPosition
                }
                .onChange(of: selectedID, initial: true) { _, id in scroll(to: id, using: proxy) }
                .onChange(of: spaces.map(\.id)) { _, _ in scroll(to: selectedID, using: proxy) }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 30)
        }
    }

    private var orbs: some View {
        HStack(spacing: 8) {
            ForEach(spaces) { space in
                Button { onSelect(space.id) } label: {
                    SpaceOrb(space: space, isSelected: space.id == selectedID, size: 24)
                }
                .buttonStyle(PressScaleStyle())
                .help(space.name)
                .accessibilityLabel(space.name)
                .id(space.id)
            }
        }
    }

    private func scroll(to id: UUID?, using proxy: ScrollViewProxy) {
        guard let id else { return }
        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .center) }
    }
}
