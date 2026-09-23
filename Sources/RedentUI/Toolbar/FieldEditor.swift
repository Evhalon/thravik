import AppKit
import RedentKit

/// Reaches the focused text field's editor for the two things SwiftUI's
/// `TextField` cannot do: select an inline completion, and select all on focus.
@MainActor
enum FieldEditor {
    /// Appends the completion after the caret and selects it, so the next
    /// keystroke replaces it and backspace removes it — the standard browser
    /// behavior. Skipped if the user has typed on since the query ran.
    static func show(_ completion: InlineCompletion) {
        guard let editor = focusedEditor, editor.string == completion.typed else { return }
        let caret = (completion.typed as NSString).length
        guard editor.selectedRange() == NSRange(location: caret, length: 0) else { return }
        editor.insertText(completion.suffix, replacementRange: NSRange(location: caret, length: 0))
        editor.setSelectedRange(NSRange(location: caret, length: (completion.suffix as NSString).length))
    }

    /// Clicking into the address should make the next keystroke replace it.
    static func selectAll() {
        focusedEditor?.selectAll(nil)
    }

    private static var focusedEditor: NSTextView? {
        NSApp.keyWindow?.firstResponder as? NSTextView
    }
}
