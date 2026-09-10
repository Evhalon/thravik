import RedentKit
import SwiftUI

/// Menu-bar commands. Kept here rather than in the app target so the shortcuts
/// live next to the chrome they drive.
///
/// Every item acts on the focused window, and does nothing when no browser
/// window has focus — the items stay in the menu bar either way, so the user
/// never watches the File menu shrink because a sheet took the focus.
public struct BrowserCommands: Commands {
    @FocusedValue(\.browserModel) private var model

    public init() {}

    public var body: some Commands {
        CommandGroup(replacing: .newItem) { fileItems }
        CommandMenu("Browser") {
            Button("Command Bar…") { model?.showCommands() }
                .keyboardShortcut("k")
                .disabled(model == nil)
            Button("Reload Page") { model?.selectedTab?.reload() }
                .keyboardShortcut("r")
                .disabled(model?.selectedTab == nil)
            Button("Undo Browser Action") { model?.tabs.undo() }
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(!(model?.tabs.canUndo ?? false))
        }
        CommandGroup(replacing: .saveItem) {
            Button(sidebarTitle) { model?.toggleSidebar() }
                .keyboardShortcut("s")
                .disabled(model == nil)
        }
        BrowserEditCommands(model: model)
        BrowserViewCommands(model: model)
        BrowserTabCommands(model: model)
        BrowserPageCommands(model: model)
        BrowserLibraryCommands(model: model)
        BrowserSpaceCommands(model: model)
    }

    @ViewBuilder
    private var fileItems: some View {
        Button("New Window") { model?.newWindow() }
            .keyboardShortcut("n")
            .disabled(model == nil)
        Button("New Private Window") { model?.newPrivateWindow() }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(model == nil)
        Divider()
        Button("New Tab") { model?.openNewTab() }
            .keyboardShortcut("t")
            .disabled(model == nil)
        Button("New Private Tab") { model?.openTemporaryTab() }
            .keyboardShortcut("n", modifiers: [.command, .control])
            .disabled(model == nil)
        Button("Close Tab") { model.flatMap { $0.tabs.selectedID.map($0.tabs.close) } }
            .keyboardShortcut("w")
            .disabled(model == nil)
        Button("Reopen Closed Tab") { model?.tabs.reopenLastClosed() }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(!(model?.tabs.canReopen ?? false))
    }

    private var sidebarTitle: String {
        (model?.isSidebarVisible ?? false) ? "Hide Sidebar" : "Show Sidebar"
    }
}
