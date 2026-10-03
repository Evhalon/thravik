import RedentKit
import SwiftUI

/// Find and the address bar, added to the menus macOS already puts them in
/// rather than invented as a menu of their own.
struct BrowserEditCommands: Commands {
    let model: BrowserModel?
    let bindings: ShortcutBindings

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Find on Page…") { model?.showFindBar() }
                .shortcut(.findOnPage, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            Button("Find Next") { model?.findNext(forward: true) }
                .shortcut(.findNext, bindings: bindings)
                .disabled(!(model?.canFindNext ?? false))
            Button("Find Previous") { model?.findNext(forward: false) }
                .shortcut(.findPrevious, bindings: bindings)
                .disabled(!(model?.canFindNext ?? false))
            Button("Close Find on Page") { model?.closeFindBar() }
                .shortcut(.closeFind, bindings: bindings)
                .disabled(!canCloseFind)
            Divider()
            Button("Fill Login") { model?.fillLogin() }
                .shortcut(.fillLogin, bindings: bindings)
                .disabled(!(model?.canFillLogin ?? false))
            Divider()
            Button("Open Location…") { model?.focusAddressBar() }
                .shortcut(.openLocation, bindings: bindings)
                .disabled(model == nil)
            Button("Copy Address") { model?.copyAddress() }
                .shortcut(.copyURL, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
            // Web apps bind ⌘⇧V to plain-text paste. The key navigates only while
            // a browser search field is focused, not while the page has the caret.
            Button(model?.pasteAndGoTitle ?? "Paste and Go") { model?.pasteAndGo() }
                .shortcut(.pasteAndGo, bindings: bindings)
                .disabled(model?.pasteAndGoField == nil)
        }
        CommandGroup(replacing: .printItem) {
            Button("Print…") { model?.printPage() }
                .shortcut(.print, bindings: bindings)
                .disabled(!(model?.hasPage ?? false))
        }
    }

    private var canCloseFind: Bool {
        guard let model, model.chrome.isFindBarVisible else { return false }
        guard !model.address.isEditing, model.formHistory.menu == nil else { return false }
        return !model.showsCommandBar && !model.showsFloatingNewTab && model.sheet == nil && !model.showsSettings
    }
}
