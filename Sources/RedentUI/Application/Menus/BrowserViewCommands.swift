import RedentKit
import SwiftUI

/// The View menu: what the window shows, how big the page is drawn, and how the
/// panes are arranged.
struct BrowserViewCommands: Commands {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some Commands {
        CommandMenu("View") {
            Button(tabStripTitle) { model?.toggleTabStrip() }
                .shortcut(.toggleTabStrip, bindings: bindings)
                .disabled(model == nil)
            Button(bookmarksBarTitle) { model?.toggleBookmarksBar() }
                .shortcut(.showBookmarksBar, bindings: bindings)
                .disabled(model == nil)
            Button(sidebarTitle) { model?.toggleSidebar() }
                .disabled(model == nil)
            Button(focusTitle) { model?.toggleFocusMode() }
                .shortcut(.focusMode, bindings: bindings)
                .disabled(model == nil)
            Button(readerTitle) { model?.toggleReader() }
                .shortcut(.toggleReader, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            Button(videoTitle) { model?.toggleFloatingVideo() }
                .shortcut(.floatVideo, bindings: bindings)
                .disabled(!(model?.canFloatVideo ?? false))
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
            .shortcut(.zoomIn, bindings: bindings)
            .disabled(!(model?.canZoomIn ?? false))
        Button("Zoom Out") { model?.zoomOut() }
            .shortcut(.zoomOut, bindings: bindings)
            .disabled(!(model?.canZoomOut ?? false))
        Button("Actual Size (\(model?.zoomLabel ?? "100%"))") { model?.resetZoom() }
            .shortcut(.zoomReset, bindings: bindings)
            .disabled(!(model?.canResetZoom ?? false))
    }

    @ViewBuilder
    private var splitItems: some View {
        Button(splitTitle, action: toggleSplit)
            .shortcut(.splitView, bindings: bindings)
            .disabled(model == nil)
        Button("Add Pane") { model?.splitWithNextTab() }
            .shortcut(.addPane, bindings: bindings)
            .disabled(!(model.map { $0.isShowingSplit && $0.split.canAddPane } ?? false))
        Button("Close Pane") { model?.closeActivePane() }
            .disabled(!(model?.isShowingSplit ?? false))
        Button("Switch Pane") { model?.toggleActivePane() }
            .shortcut(.switchPane, bindings: bindings)
            .disabled(!(model?.isShowingSplit ?? false))
        Button("Flip Split") { model?.toggleSplitOrientation() }
            .disabled(!(model?.isShowingSplit ?? false))
    }

    private func toggleSplit() {
        guard let model else { return }
        if model.isShowingSplit { model.closeSplit() } else { model.splitWithNextTab() }
    }

    private var tabStripTitle: String { (model?.showsTabStrip ?? false) ? "Hide Tabs" : "Show Tabs" }
    private var bookmarksBarTitle: String {
        (model?.settings.showsBookmarksBar ?? false) ? "Hide Bookmarks Bar" : "Show Bookmarks Bar"
    }
    private var sidebarTitle: String { (model?.isSidebarVisible ?? false) ? "Hide Sidebar" : "Show Sidebar" }
    private var focusTitle: String { (model?.isFocusMode ?? false) ? "Exit Focus Mode" : "Focus Mode" }
    private var readerTitle: String { (model?.isReaderActive ?? false) ? "Hide Reader" : "Show Reader" }
    private var videoTitle: String { (model?.isVideoFloating ?? false) ? "Return Video to Tab" : "Float Video" }
    private var splitTitle: String { (model?.isShowingSplit ?? false) ? "Close Split" : "Split View" }

    private var layoutBinding: Binding<TabLayout> {
        Binding(
            get: { model?.settings.tabLayout ?? .sidebar },
            set: { model?.settings.tabLayout = $0 }
        )
    }
}
