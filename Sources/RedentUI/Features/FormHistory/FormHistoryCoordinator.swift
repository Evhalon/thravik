import Foundation
import Observation
import RedentKit

/// Chrome-style suggestions under text fields, from what the user has sent in
/// similar fields before. Offers and fills only — the user sends the form.
@MainActor @Observable
public final class FormHistoryCoordinator {
    public private(set) var menu: FormSuggestionMenu?
    public private(set) var isEnabled: Bool

    private let store: any FormHistoryStoring
    @ObservationIgnored private var lookupID = UUID()

    public static let limit = 6

    public init(store: any FormHistoryStoring, isEnabled: Bool = true) {
        self.store = store
        self.isEnabled = isEnabled
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { close(nil) }
    }

    func fieldActive(_ focus: FormFieldFocus, in tab: any BrowserTab) async {
        let lookupID = UUID()
        self.lookupID = lookupID
        guard isEnabled, let key = FormFieldKey(focus.field) else { return close(tab) }
        let items = await store.suggestions(for: key, matching: focus.typed, limit: Self.limit)
        guard self.lookupID == lookupID else { return }
        guard !items.isEmpty else { return close(tab) }
        menu = FormSuggestionMenu(tabID: tab.id, key: key, anchor: focus.anchor, items: items, typed: focus.typed)
        tab.showFormSuggestions(count: items.count)
    }

    func highlight(_ index: Int) {
        guard var menu, index < menu.items.count else { return }
        menu.highlighted = max(index, -1)
        self.menu = menu
    }

    func choose(at index: Int, in tab: any BrowserTab) {
        guard let menu, menu.tabID == tab.id, menu.items.indices.contains(index) else { return }
        tab.fillFormField(menu.items[index])
        close(nil)
    }

    /// Temporary tabs and private windows leave nothing behind, like history.
    func submitted(_ values: [FormFieldValue], remembers: Bool, in tab: any BrowserTab) async {
        close(menu == nil ? nil : tab)
        guard isEnabled, remembers else { return }
        let entries = values.compactMap { FormEntry(field: $0.field, value: $0.value) }
        guard !entries.isEmpty else { return }
        await store.record(entries, at: Date())
    }

    /// Forgets one suggestion, the way Shift-Delete does in Chrome.
    func forget(_ value: String, in tab: any BrowserTab) async {
        guard var menu else { return }
        await store.remove(value, for: menu.key)
        let items = menu.items.filter { $0 != value }
        guard !items.isEmpty else { return close(tab) }
        menu = FormSuggestionMenu(tabID: menu.tabID, key: menu.key, anchor: menu.anchor, items: items, typed: menu.typed)
        self.menu = menu
        tab.showFormSuggestions(count: items.count)
    }

    public func forgetAll() async {
        close(nil)
        await store.removeAll()
    }

    /// Closes the menu. The page is told too when it still has the field.
    func close(_ tab: (any BrowserTab)?) {
        lookupID = UUID()
        guard menu != nil || tab != nil else { return }
        menu = nil
        tab?.showFormSuggestions(count: 0)
    }
}
