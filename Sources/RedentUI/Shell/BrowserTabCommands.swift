import RedentKit
import SwiftUI

/// The Tab menu: moving between the tabs of the current Space, and the two
/// things done to the one in front.
struct BrowserTabCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandMenu("Tab") {
            stepItems
            Divider()
            numberedTabs
            Divider()
            Button(pinTitle) { model.flatMap { $0.tabs.selectedID.map($0.tabs.togglePin) } }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(model?.tabs.selectedID == nil)
            Button("Close Other Tabs") {
                model.flatMap { $0.tabs.selectedID.map($0.tabs.closeOthers(than:)) }
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
            .disabled(model?.tabs.selectedID == nil)
        }
    }

    /// Both idioms, because both are muscle memory: ⌘J and ⌃⇧Tab, and
    /// ⇧⌘[ / ⇧⌘] from Safari and Chrome. ⌃Tab stays what it is everywhere
    /// else — the tab you were just on, not the next one along.
    @ViewBuilder
    private var stepItems: some View {
        Button("Next Tab") { model?.tabs.selectNext() }
            .keyboardShortcut("j")
            .disabled(model == nil)
        Button("Previous Tab") { model?.tabs.selectPrevious() }
            .keyboardShortcut(.tab, modifiers: [.control, .shift])
            .disabled(model == nil)
        Button("Last Active Tab") { model?.tabs.selectPreviouslyActiveTab() }
            .keyboardShortcut(.tab, modifiers: .control)
            .disabled(model == nil)
        Button("Select Tab to the Right") { model?.tabs.selectNext() }
            .keyboardShortcut("]", modifiers: [.command, .shift])
            .disabled(model == nil)
        Button("Select Tab to the Left") { model?.tabs.selectPrevious() }
            .keyboardShortcut("[", modifiers: [.command, .shift])
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

    private var pinTitle: String {
        let pinned = model?.selectedTab?.isPinned ?? false
        return pinned ? "Unpin Tab" : "Pin Tab"
    }
}
