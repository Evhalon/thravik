import RedentDesign
import SwiftUI

struct BrowserWorkspace<Backdrop: View>: View {
    @Bindable var model: BrowserModel
    let backdrop: Backdrop
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reveal = ChromeRevealModel()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            if model.isSidebarVisible {
                SidebarResizeHandle(width: $model.settings.sidebarWidth)
                    .transition(.opacity)
                    .zIndex(1)
            }
            PageColumn(model: model, usesTopStrip: usesTopStrip, backdrop: backdrop)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .zIndex(0)
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.05), value: model.isSidebarVisible)
        .animation(nil, value: model.settings.sidebarWidth)
        .overlay {
            if model.usesEdgeReveal {
                EdgeChromeOverlay(model: model, reveal: reveal, backdrop: backdrop)
            }
        }
        .background {
            WindowConfigurator(showsWindowButtons: !model.usesEdgeReveal || reveal.surface != nil)
                .frame(width: 0, height: 0)
        }
        .onChange(of: model.usesEdgeReveal) { _, _ in reveal.reset() }
    }

    private var sidebar: some View {
        Group {
            if model.isSidebarVisible {
                SidebarTabStrip(model: model)
                    .frame(width: model.settings.sidebarWidth)
                    .transition(reduceMotion ? .identity : .move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: model.isSidebarVisible ? model.settings.sidebarWidth : 0, alignment: .leading)
        // Only the rail is clipped; masking the live web view breaks video.
        .clipped()
        .allowsHitTesting(model.isSidebarVisible)
        .accessibilityHidden(!model.isSidebarVisible)
        .zIndex(2)
    }

    private var usesTopStrip: Bool { model.showsTabStrip && model.settings.tabLayout == .top }
}
