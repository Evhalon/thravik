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
        switch pasteAndGoField {
        case .floatingNewTab:
            dismissFloatingNewTab()
            tabs.newTab(url: action.url)
        case .newTabPage:
            suggestions.close(from: .newTab)
            navigate(to: action.url)
        case .address, nil:
            open(action.url, inNewTab: false)
        }
    }

    func beginPasteAndGoEditing(_ field: PasteAndGoField) {
        pasteAndGoField = field
        Task { @MainActor in
            await Task.yield()
            guard pasteAndGoField == field else { return }
            FieldEditor.attachPasteAndGo(
                title: { [weak self] in self?.pasteAndGoTitle ?? "Paste and Go" },
                isEnabled: { [weak self] in self?.canPasteAndGo ?? false },
                perform: { [weak self] in self?.pasteAndGo() }
            )
        }
    }

    func endPasteAndGoEditing(_ field: PasteAndGoField) {
        guard pasteAndGoField == field else { return }
        pasteAndGoField = nil
        FieldEditor.detachPasteAndGo()
    }

    var pasteAndGoAction: PasteAndGoDecision.Action? {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        return PasteAndGoDecision.action(for: text, using: settings.searchRouting)
    }
}
