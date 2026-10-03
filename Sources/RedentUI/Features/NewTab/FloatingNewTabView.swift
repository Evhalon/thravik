import RedentDesign
import RedentKit
import SwiftUI

/// Search before creating a tab, while the current page stays visible below.
struct FloatingNewTabView: View {
    static let fieldHeight: CGFloat = 62
    static let expandedHeight = fieldHeight + FloatingNewTabResults.maximumHeight + Metric.hairWidth

    @Bindable var model: BrowserModel
    let dismissRequest: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""
    @State private var bookmarks: [Bookmark] = []
    @State private var recent: [HistoryEntry] = []
    @State private var selectedIndex = 0
    @State private var appeared = false
    @State private var isClosing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            FloatingNewTabField(model: model, query: $query, isFocused: $isFocused,
                                input: FloatingNewTabFieldInput(submit: submitSelected,
                                    dismiss: dismissAnimated, move: moveSelection))
            if appeared && !isClosing {
                Rectangle().fill(Palette.hairline).frame(height: Metric.hairWidth)
                FloatingNewTabResults(items: items, showsSections: query.isEmpty,
                                      selectedIndex: selectedIndex, onSelect: submit)
                    .transition(.opacity)
            }
        }
        .frame(width: 620)
        .background { FloatingPanelSurface(space: model.currentSpace) }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 32, y: 16)
        .modifier(FloatingPanelMotion(revealed: appeared, isClosing: isClosing,
                                            reduceMotion: reduceMotion))
        .padding(.horizontal, 20)
        .task(appear)
        .task(id: model.currentSpaceID, loadHome)
        .onChange(of: isFocused, initial: true) { _, focused in
            if focused { model.beginPasteAndGoEditing(.floatingNewTab) }
            else { model.endPasteAndGoEditing(.floatingNewTab) }
        }
        .onDisappear { model.endPasteAndGoEditing(.floatingNewTab) }
        .onChange(of: query) { _, _ in selectedIndex = 0 }
        .onChange(of: model.suggestions.rows.map(\.id)) { _, _ in selectedIndex = 0 }
        .onChange(of: dismissRequest) { _, _ in dismissAnimated() }
        .onExitCommand(perform: dismissAnimated)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("New tab search")
        .accessibilityAddTraits(.isModal)
    }

    private var items: [FloatingNewTabItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return FloatingNewTabHome.items(tabs: model.tabs.tabs.map(\.snapshot),
                selectedID: model.tabs.selectedID, bookmarks: bookmarks, recent: recent)
        }
        if model.suggestions.isOpen(for: .newTab),
           model.suggestions.query == text || model.suggestions.completion?.text == text {
            return model.suggestions.rows.map(FloatingNewTabItem.suggestion)
        }
        return FloatingNewTabItem.preview(text, routing: model.settings.searchRouting).map { [$0] } ?? []
    }

    private func moveSelection(_ offset: Int) -> KeyPress.Result {
        guard !items.isEmpty else { return .ignored }
        selectedIndex = (selectedIndex + offset + items.count) % items.count
        model.loadAhead(items[selectedIndex])
        return .handled
    }

    private func submitSelected() {
        submit(items.indices.contains(selectedIndex) ? items[selectedIndex] : nil)
    }

    private func submit(_ item: FloatingNewTabItem?) {
        animateClose { perform(item) }
    }

    private func dismissAnimated() {
        animateClose { model.cancelFloatingNewTab() }
    }

    private func animateClose(_ action: @escaping @MainActor () -> Void) {
        guard !isClosing else { return }
        guard !reduceMotion else { action(); return }
        withAnimation(.easeIn(duration: 0.16)) { isClosing = true }
        Task {
            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled, model.showsFloatingNewTab else { return }
            action()
        }
    }

    private func perform(_ item: FloatingNewTabItem?) {
        if let item { model.activateFloatingNewTab(item) }
        else { model.submitFloatingNewTabQuery(query) }
    }

    private func appear() async {
        if reduceMotion { appeared = true }
        else { withAnimation(.easeOut(duration: 0.20)) { appeared = true } }
        await Task.yield()
        isFocused = true
    }

    private func loadHome() async {
        guard let spaceID = model.currentSpaceID else { return }
        async let saved = model.bookmarks.all(in: spaceID)
        async let visited = model.history.query(HistoryQuery(
            scope: HistoryScope(spaceID: spaceID), limit: 8, sort: .recent))
        let (loadedBookmarks, loadedRecent) = await (saved, visited)
        guard !Task.isCancelled, model.currentSpaceID == spaceID else { return }
        bookmarks = loadedBookmarks
        recent = loadedRecent
    }
}
