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
            Button(readerTitle) { model?.toggleReader() }
                .keyboardShortcut("r", modifiers: [.command, .control])
                .disabled(!(model?.hasPage ?? false))
            Divider()
            Picker("Tab Layout", selection: layoutBinding) {
                ForEach(TabLayout.allCases) { Text($0.label).tag($0) }
            }
            .disabled(model == nil)
            Divider()
            zoomItems
            Divider()
            splitItems
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
        Button("Add Pane") { model?.splitWithNextTab() }
            .keyboardShortcut("d", modifiers: [.command, .option])
            .disabled(!(model.map { $0.isShowingSplit && $0.split.canAddPane } ?? false))
        Button("Close Pane") { model?.closeActivePane() }
            .disabled(!(model?.isShowingSplit ?? false))
        Button("Switch Pane") { model?.toggleActivePane() }
            .keyboardShortcut("]", modifiers: [.command, .option])
            .disabled(!(model?.isShowingSplit ?? false))
        Button("Flip Split") { model?.toggleSplitOrientation() }
            .disabled(!(model?.isShowingSplit ?? false))
    }

    private func toggleSplit() {
        guard let model else { return }
        if model.isShowingSplit { model.closeSplit() } else { model.splitWithNextTab() }
    }

    private var tabStripTitle: String { (model?.showsTabStrip ?? false) ? "Hide Tabs" : "Show Tabs" }
    private var sidebarTitle: String { (model?.isSidebarVisible ?? false) ? "Hide Sidebar" : "Show Sidebar" }
    private var focusTitle: String { (model?.isFocusMode ?? false) ? "Exit Focus Mode" : "Focus Mode" }
    private var readerTitle: String { (model?.isReaderActive ?? false) ? "Hide Reader" : "Show Reader" }
    private var splitTitle: String { (model?.isShowingSplit ?? false) ? "Close Split" : "Split View" }

    private var layoutBinding: Binding<TabLayout> {
        Binding(
            get: { model?.settings.tabLayout ?? .sidebar },
            set: { model?.settings.tabLayout = $0 }
        )
    }
}
