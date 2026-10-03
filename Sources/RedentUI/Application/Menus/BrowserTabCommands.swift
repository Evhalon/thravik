import RedentKit
import SwiftUI

/// The Tab menu: moving between the tabs of the current Space, and the few
/// things done to the one in front.
struct BrowserTabCommands: Commands {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some Commands {
        CommandMenu("Tab") {
            stepItems
            Divider()
            numberedTabs
            Divider()
            Button(pinTitle) { model.flatMap { $0.tabs.selectedID.map($0.tabs.togglePin) } }
                .shortcut(.pinTab, bindings: bindings)
                .disabled(model?.tabs.selectedID == nil)
            Button("Duplicate Tab") { model?.duplicateSelectedTab() }
                .shortcut(.duplicateTab, bindings: bindings)
                .disabled(model?.selectedTab?.url == nil)
            Button("Close Other Tabs") {
                model.flatMap { $0.tabs.selectedID.map($0.tabs.closeOthers(than:)) }
            }
            .shortcut(.closeOtherTabs, bindings: bindings)
            .disabled(model?.tabs.selectedID == nil)
            Button("Tidy Unused Tabs…") { model?.execute(.tidyUnusedTabs) }
                .disabled(model == nil)
            // ⌃M, as in Firefox: ⌘M belongs to Minimize in every Mac app.
            Button(muteTitle) { model?.toggleMute() }
                .shortcut(.muteTab, bindings: bindings)
                .disabled(model?.selectedTab == nil)
        }
    }

    /// Both idioms, because both are muscle memory: ⌘J and ⌃⇧Tab, and
    /// ⇧⌘[ / ⇧⌘] from Safari and Chrome. ⌃Tab stays what it is everywhere
    /// else — the tab you were just on, not the next one along.
    @ViewBuilder
    private var stepItems: some View {
        Button("Next Tab") { model?.tabs.selectNext() }
            .shortcut(.nextTab, bindings: bindings)
            .disabled(model == nil)
        Button("Previous Tab") { model?.tabs.selectPrevious() }
            .shortcut(.previousTab, bindings: bindings)
            .disabled(model == nil)
        Button("Last Active Tab") { model?.tabs.selectPreviouslyActiveTab() }
            .shortcut(.lastActiveTab, bindings: bindings)
            .disabled(model == nil)
        Button("Select Tab to the Right") { model?.tabs.selectNext() }
            .shortcut(.selectTabRight, bindings: bindings)
            .disabled(model == nil)
        Button("Select Tab to the Left") { model?.tabs.selectPrevious() }
            .shortcut(.selectTabLeft, bindings: bindings)
            .disabled(model == nil)
    }

    /// ⌘1…⌘8 pick a seat; ⌘9 is the last tab, wherever it is — the convention
    /// every other browser follows.
    @ViewBuilder
    private var numberedTabs: some View {
        ForEach(1...9, id: \.self) { number in
            Button(number == 9 ? "Last Tab" : "Tab \(number)") { model?.selectTab(at: number) }
                .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
                .disabled(model == nil)
        }
    }

    private var muteTitle: String {
        model?.isSelectedTabMuted == true ? "Unmute Tab" : "Mute Tab"
    }

    private var pinTitle: String {
        let pinned = model?.selectedTab?.isPinned ?? false
        return pinned ? "Unpin Tab" : "Pin Tab"
    }
}
