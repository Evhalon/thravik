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
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { model?.showSettings() }
                .shortcut(.settings, bindings: bindings)
                .disabled(model == nil)
        }
        CommandGroup(replacing: .newItem) { fileItems }
        CommandMenu("Browser") {
            Button("Command Center…") { model?.toggleCommands() }
                .shortcut(.commandBar, bindings: bindings)
                .disabled(model == nil)
            Button("Reload Page") { model?.selectedTab?.reload() }
                .shortcut(.reload, bindings: bindings)
                .disabled(model?.selectedTab == nil)
            Button("Undo Browser Action") { model?.tabs.undo() }
                .shortcut(.undoBrowserAction, bindings: bindings)
                .disabled(!(model?.tabs.canUndo ?? false))
            Divider()
            BrowserDevToolsItems(model: model, bindings: bindings)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Toggle Tab Layout") { model?.toggleTabLayout() }
                .shortcut(.toggleTabLayout, bindings: bindings)
                .disabled(model == nil)
            Button(sidebarTitle) { model?.toggleSidebar() }
                .shortcut(.toggleSidebar, bindings: bindings)
                .disabled(model == nil)
        }
        BrowserEditCommands(model: model, bindings: bindings)
        BrowserViewCommands(model: model, bindings: bindings)
        BrowserTabCommands(model: model, bindings: bindings)
        BrowserPageCommands(model: model, bindings: bindings)
        BrowserLibraryCommands(model: model, bindings: bindings)
        BrowserSpaceCommands(model: model, bindings: bindings)
    }

    @ViewBuilder
    private var fileItems: some View {
        Button("New Window") { model?.newWindow() }
            .shortcut(.newWindow, bindings: bindings)
            .disabled(model == nil)
        Button("New Private Window") { model?.newPrivateWindow() }
            .shortcut(.newPrivateWindow, bindings: bindings)
            .disabled(model == nil || !(model?.canOpenPrivateWindow ?? true))
        Divider()
        Button("New Tab") { model?.openNewTab() }
            .shortcut(.newTab, bindings: bindings)
            .disabled(model == nil)
        Button("New Private Tab") { model?.openTemporaryTab() }
            .shortcut(.newPrivateTab, bindings: bindings)
            .disabled(model == nil)
        Button("Close Tab") { model.flatMap { $0.tabs.selectedID.map($0.tabs.close) } }
            .shortcut(.closeTab, bindings: bindings)
            .disabled(model == nil)
        Button("Reopen Closed Tab") { model?.tabs.reopenLastClosed() }
            .shortcut(.reopenClosedTab, bindings: bindings)
            .disabled(!(model?.tabs.canReopen ?? false))
    }

    private var sidebarTitle: String {
        (model?.isSidebarVisible ?? false) ? "Hide Sidebar" : "Show Sidebar"
    }

    private var bindings: ShortcutBindings {
        model?.settings.shortcutBindings ?? ShortcutBindings()
    }
}
