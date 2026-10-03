import Foundation
import RedentKit

/// Form history's half of the page signals, and the menu's own actions.
extension BrowserModel {
    func handleFormHistory(_ signal: PageSignal, from tab: any BrowserTab) {
        switch signal {
        case .formFieldActive(let focus):
            guard retainsBrowsingTraces(for: tab) else { return formHistory.close(nil) }
            Task { await formHistory.fieldActive(focus, in: tab) }
        case .formFieldInactive:
            formHistory.close(nil)
        case .formSuggestionHighlighted(let index):
            formHistory.highlight(index)
        case .formSuggestionChosen(let index):
            formHistory.choose(at: index, in: tab)
        case .formSubmitted(let values):
            let remembers = retainsBrowsingTraces(for: tab)
            Task { await formHistory.submitted(values, remembers: remembers, in: tab) }
        default:
            return
        }
    }

    public func chooseFormSuggestion(_ value: String) {
        guard let tab = formSuggestionTab, let index = formHistory.menu?.items.firstIndex(of: value) else { return }
        formHistory.choose(at: index, in: tab)
    }

    public func forgetFormSuggestion(_ value: String) {
        guard let tab = formSuggestionTab else { return }
        Task { await formHistory.forget(value, in: tab) }
    }

    public func dismissFormSuggestions() {
        formHistory.close(formSuggestionTab)
    }

    private var formSuggestionTab: (any BrowserTab)? {
        guard let id = formHistory.menu?.tabID else { return nil }
        return tabs.tabs.first { $0.id == id }
    }
}
