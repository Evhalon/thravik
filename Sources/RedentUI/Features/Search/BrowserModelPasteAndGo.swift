import AppKit
import Foundation
import RedentKit

extension BrowserModel {
    public var pasteAndGoTitle: String {
        pasteAndGoAction?.menuTitle ?? "Paste and Go"
    }

    public var canPasteAndGo: Bool {
        pasteAndGoAction != nil
    }

    public func pasteAndGo() {
        guard let action = pasteAndGoAction else { return }
        open(action.url, inNewTab: false)
    }

    var pasteAndGoAction: PasteAndGoDecision.Action? {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        return PasteAndGoDecision.action(for: text, using: settings.searchRouting)
    }
}
