import SwiftUI

/// Find and the address bar, added to the menus macOS already puts them in
/// rather than invented as a menu of their own.
struct BrowserEditCommands: Commands {
    let model: BrowserModel?

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Find on Page…") { model?.showFindBar() }
                .keyboardShortcut("f")
                .disabled(!(model?.hasPage ?? false))
            Button("Find Next") { model?.findNext(forward: true) }
                .keyboardShortcut("g")
                .disabled(!(model?.chrome.isFindBarVisible ?? false))
            Button("Find Previous") { model?.findNext(forward: false) }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(!(model?.chrome.isFindBarVisible ?? false))
            Divider()
            Button("Open Location…") { model?.focusAddressBar() }
                .keyboardShortcut("l")
                .disabled(model == nil)
            Button("Copy Address") { model?.copyAddress() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(!(model?.hasPage ?? false))
        }
        CommandGroup(replacing: .printItem) {
            Button("Print…") { model?.printPage() }
                .keyboardShortcut("p")
                .disabled(!(model?.hasPage ?? false))
        }
    }
}
