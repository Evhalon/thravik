import RedentKit
import SwiftUI

/// Menu-bar commands. Kept here rather than in the app target so the shortcuts
/// live next to the chrome they drive.
public struct BrowserCommands: Commands {
    private let model: BrowserModel

    public init(model: BrowserModel) {
        self.model = model
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab", action: model.openNewTab)
                .keyboardShortcut("t")
            Button("Close Tab") { model.tabs.selectedID.map(model.tabs.close) }
                .keyboardShortcut("w")
            Button("Reopen Closed Tab", action: model.tabs.reopenLastClosed)
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Button("New Temporary Tab", action: model.openTemporaryTab)
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        CommandMenu("Browser") {
            Button("Command Bar…", action: model.showCommands).keyboardShortcut("k")
            Button("Undo Browser Action", action: model.tabs.undo)
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(!model.tabs.canUndo)
        }
        CommandGroup(replacing: .saveItem) {
            Button(model.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar", action: model.toggleSidebar)
                .keyboardShortcut("s")
        }
        CommandMenu("View") {
            Button(model.showsTabStrip ? "Hide Tabs" : "Show Tabs", action: model.toggleTabStrip)
                .keyboardShortcut("\\", modifiers: .command)
            Button(model.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar", action: model.toggleSidebar)
            Button(model.isFocusMode ? "Exit Focus Mode" : "Focus Mode", action: model.toggleFocusMode)
                .keyboardShortcut("f", modifiers: [.command, .shift])
            Divider()
            Picker("Tab Layout", selection: layoutBinding) {
                ForEach(TabLayout.allCases) { Text($0.label).tag($0) }
            }
            Divider()
            Divider()
            Button(model.split.isSplit ? "Close Split" : "Split View", action: toggleSplit)
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button("Switch Pane", action: model.toggleActivePane)
                .keyboardShortcut("]", modifiers: [.command, .option])
                .disabled(!model.split.isSplit)
            Button("Flip Split", action: model.toggleSplitOrientation)
                .disabled(!model.split.isSplit)
            Divider()
            Button("Next Tab", action: model.tabs.selectNext)
                .keyboardShortcut(.tab, modifiers: .control)
            Button("Previous Tab", action: model.tabs.selectPrevious)
                .keyboardShortcut(.tab, modifiers: [.control, .shift])
        }
        CommandMenu("Spaces") {
            ForEach(Array(model.tabs.session.spaces.prefix(9).enumerated()), id: \.element.id) { index, space in
                Button(space.name) { model.execute(.focusSpace(space.id)) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [.control, .option])
            }
            Divider()
            Button("Manage Spaces…") { model.sheet = .spaces }
            Button("Tab Groups…") { model.sheet = .groups }
                .keyboardShortcut("g", modifiers: [.control, .option])
            Button("Containers…") { model.sheet = .containers }
                .keyboardShortcut("c", modifiers: [.control, .option])
        }
        CommandGroup(after: .appSettings) {
            Button("Tab Timeline…") { model.sheet = .timeline }
                .keyboardShortcut("y", modifiers: [.command, .shift])
            Button("Site Privacy…") { model.sheet = .sitePrivacy }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            Button("History…") { model.sheet = .history }
            Button("Bookmarks…") { model.sheet = .bookmarks }
            Button("Passwords…") { model.sheet = .passwords }
            Button("Authenticator…") { model.sheet = .authenticator }
            Button("Import from Another Browser…") { model.sheet = .importBrowser }
        }
    }

    private func toggleSplit() {
        if model.split.isSplit { model.closeSplit() } else { model.splitWithNextTab() }
    }

    private var layoutBinding: Binding<TabLayout> {
        Binding(get: { model.settings.tabLayout }, set: { model.settings.tabLayout = $0 })
    }
}
