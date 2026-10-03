import AppKit

/// Inserts Paste and Go after the system Paste item of the field editor's own
/// menu, so spelling, services, writing tools and the rest stay in place.
@MainActor
final class AddressFieldMenu: NSObject, NSMenuItemValidation {
    var titleProvider: () -> String = { "Paste and Go" }
    var isEnabledProvider: () -> Bool = { false }
    var onPasteAndGo: () -> Void = {}
    /// The window's field editor is shared by every text field in it, so the
    /// stock menu must come back before another field starts editing.
    private weak var editor: NSTextView?
    private var originalMenu: NSMenu?
    private var installedMenu: NSMenu?

    func install(on editor: NSTextView?) {
        uninstall()
        guard let editor, let stock = editor.menu, let menu = stock.copy() as? NSMenu else { return }
        let paste = menu.items.firstIndex { $0.action == #selector(NSText.paste(_:)) }
        menu.insertItem(pasteAndGoItem(), at: paste.map { $0 + 1 } ?? menu.items.count)
        self.editor = editor
        originalMenu = stock
        installedMenu = menu
        editor.menu = menu
    }

    func uninstall() {
        if let editor, editor.menu === installedMenu { editor.menu = originalMenu }
        editor = nil
        originalMenu = nil
        installedMenu = nil
        titleProvider = { "Paste and Go" }
        isEnabledProvider = { false }
        onPasteAndGo = {}
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        item.title = titleProvider()
        return isEnabledProvider()
    }

    private func pasteAndGoItem() -> NSMenuItem {
        let item = NSMenuItem(title: titleProvider(), action: #selector(runPasteAndGo), keyEquivalent: "v")
        item.keyEquivalentModifierMask = [.command, .shift]
        item.target = self
        return item
    }

    @objc private func runPasteAndGo() { onPasteAndGo() }
}
