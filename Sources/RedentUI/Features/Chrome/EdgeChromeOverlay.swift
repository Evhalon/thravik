import RedentDesign
import SwiftUI

struct EdgeChromeOverlay<Backdrop: View>: View {
    @Bindable var model: BrowserModel
    let reveal: ChromeRevealModel
    let backdrop: Backdrop
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if reveal.surface == .sidebar { sidebar(height: geometry.size.height) }
                if reveal.surface == .navigation { navigation }
                edge(.leftEdge).frame(width: 6, height: geometry.size.height)
                edge(.topEdge).frame(width: geometry.size.width, height: 6)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.26, bounce: 0), value: reveal.surface)
        .modifier(ChromeRevealInteractions(model: model, reveal: reveal))
        .onDisappear { reveal.reset() }
    }

    private func sidebar(height: CGFloat) -> some View {
        SidebarTabStrip(model: model)
            .frame(width: model.settings.sidebarWidth, height: height)
            .background { surfaceBackground }
            .clipped()
            .shadow(color: .black.opacity(0.3), radius: 16, x: 6)
            .contentShape(.rect)
            .onHover { reveal.hover(.sidebar, isInside: $0) }
            .onDisappear { reveal.hover(.sidebar, isInside: false) }
            .transition(reduceMotion ? .identity : .move(edge: .leading).combined(with: .opacity))
    }

    private var navigation: some View {
        VStack(spacing: 0) {
            ChromeBar(model: model)
            if model.showsBookmarksBar { BookmarksBar(model: model) }
        }
        .background { surfaceBackground }
        .clipped()
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        .contentShape(.rect)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { reveal.navigationHeight = $0 }
        .onHover { reveal.hover(.navigation, isInside: $0) }
        .onDisappear { reveal.hover(.navigation, isInside: false) }
        .transition(reduceMotion ? .identity : .move(edge: .top).combined(with: .opacity))
    }

    private func edge(_ region: ChromeRevealModel.Region) -> some View {
        Color.clear
            .contentShape(.rect)
            .onContinuousHover { phase in
                switch phase {
                case .active: reveal.hover(region, isInside: true)
                case .ended: reveal.hover(region, isInside: false)
                }
            }
            .accessibilityHidden(true)
    }

    private var surfaceBackground: some View {
        GeometryReader { proxy in
            if let window = proxy.bounds(of: WindowBackdrop.space) {
                backdrop
                    .frame(width: window.width, height: window.height)
                    .offset(x: window.minX, y: window.minY)
            }
        }
        .allowsHitTesting(false)
    }
}
