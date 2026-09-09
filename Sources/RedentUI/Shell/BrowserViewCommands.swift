import RedentKit
import SwiftUI

/// The View menu: what the window shows, how big the page is drawn, and how the
/// panes are arranged.
struct BrowserViewCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandMenu("View") {
            Button(tabStripTitle) { model?.toggleTabStrip() }
                .keyboardShortcut("\\", modifiers: .command)
                .disabled(model == nil)
            Button(sidebarTitle) { model?.toggleSidebar() }
                .disabled(model == nil)
            Button(focusTitle) { model?.toggleFocusMode() }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(model == nil)
            Divider()
            Picker("Tab Layout", selection: layoutBinding) {
                ForEach(TabLayout.allCases) { Text($0.label).tag($0) }
            }
            .disabled(model == nil)
            Divider()
            zoomItems
            Divider()
            splitItems
            Divider()
            Button("Next Tab") { model?.tabs.selectNext() }
                .keyboardShortcut("j")
                .disabled(model == nil)
            Button("Previous Tab") { model?.tabs.selectPrevious() }
                .keyboardShortcut(.tab, modifiers: [.control, .shift])
                .disabled(model == nil)
        }
    }

    @ViewBuilder
    private var zoomItems: some View {
        Button("Zoom In") { model?.zoomIn() }
            .keyboardShortcut("+", modifiers: .command)
            .disabled(!(model?.canZoomIn ?? false))
        Button("Zoom Out") { model?.zoomOut() }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(!(model?.canZoomOut ?? false))
        Button("Actual Size (\(model?.zoomLabel ?? "100%"))") { model?.resetZoom() }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(!(model?.canResetZoom ?? false))
    }

    @ViewBuilder
    private var splitItems: some View {
        Button(splitTitle, action: toggleSplit)
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(model == nil)
        Button("Switch Pane") { model?.toggleActivePane() }
            .keyboardShortcut("]", modifiers: [.command, .option])
            .disabled(!(model?.split.isSplit ?? false))
        Button("Flip Split") { model?.toggleSplitOrientation() }
            .disabled(!(model?.split.isSplit ?? false))
    }

    private func toggleSplit() {
        guard let model else { return }
        if model.split.isSplit { model.closeSplit() } else { model.splitWithNextTab() }
    }

    private var tabStripTitle: String { (model?.showsTabStrip ?? false) ? "Hide Tabs" : "Show Tabs" }
    private var sidebarTitle: String { (model?.isSidebarVisible ?? false) ? "Hide Sidebar" : "Show Sidebar" }
    private var focusTitle: String { (model?.isFocusMode ?? false) ? "Exit Focus Mode" : "Focus Mode" }
    private var splitTitle: String { (model?.split.isSplit ?? false) ? "Close Split" : "Split View" }

    private var layoutBinding: Binding<TabLayout> {
        Binding(
            get: { model?.settings.tabLayout ?? .sidebar },
            set: { model?.settings.tabLayout = $0 }
        )
    }
}
