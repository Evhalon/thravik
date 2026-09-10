import RedentDesign
import SwiftUI

/// What a new tab shows: a greeting, a search field, and the places the user
/// actually goes. No blank canvas, and nothing to dismiss.
struct NewTabPage: View {
    @Bindable var model: BrowserModel
    @State private var newTab: NewTabModel
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""

    init(model: BrowserModel) {
        self.model = model
        _newTab = State(initialValue: NewTabModel(history: model.history, bookmarks: model.bookmarks))
    }

    var body: some View {
        ZStack {
            NewTabBackdrop()
            VStack(spacing: 26) {
                header
                NewTabSearchField(model: model, text: $query, isFocused: $isSearchFocused, onSubmit: submit)
                ScrollView {
                    content
                        .zIndex(0)
                }
                .scrollIndicators(.never)
            }
            .frame(maxWidth: 680)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            // Sits a little above centre — dead centre reads as unfinished,
            // and the eye expects the search field slightly high. A ceiling,
            // never a floor: a short window gets the height it actually has,
            // and the grid scrolls inside it rather than spilling past it.
            .frame(maxWidth: .infinity, maxHeight: restingHeight)
            .defaultFocus($isSearchFocused, true)
        }
        .task(id: model.currentSpaceID) { await newTab.load(in: model.currentSpaceID) }
        .onAppear { isSearchFocused = true }
        .task(id: model.centerSearchFocusEpoch) { await claimSearchFocus() }
    }

    /// AppKit often hands first responder to the sidebar address field when a
    /// web view leaves the tree. Claim twice: now, and after that reassignment.
    private func claimSearchFocus() async {
        isSearchFocused = true
        try? await Task.sleep(for: .milliseconds(50))
        isSearchFocused = true
    }

    /// How tall the stack grows before it stops. Past this the window keeps
    /// the extra room, which is what sits the greeting high in a large window;
    /// below it the stack simply takes what it is given.
    private let restingHeight: CGFloat = 620

    private var header: some View {
        VStack(spacing: 6) {
            Text(Greeting.current())
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .tracking(-0.3)
                .foregroundStyle(Palette.chromeText)
            Text("Where would you like to go?")
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    @ViewBuilder
    private var content: some View {
        if newTab.isBare {
            NewTabEmptyState { model.sheet = .importBrowser }
        } else {
            NewTabGrid(
                tiles: newTab.tiles,
                onOpen: { tile, inNewTab in model.open(tile.url, inNewTab: inNewTab) },
                onRemoveFavorite: { tile in Task { await newTab.removeFavorite(tile) } }
            )
        }
    }

    private func submit() {
        // An armed suggestion wins over re-resolving the raw text, exactly as
        // in the address bar — the two must not disagree about what return does.
        if let row = model.suggestions.highlightedRow {
            model.suggestions.close()
            model.navigate(to: row.url)
            query = ""
            return
        }
        model.suggestions.close()
        guard let url = AddressResolverBridge.resolve(query, engine: model.settings.searchEngine)
        else { return }
        model.navigate(to: url)
        query = ""
    }
}
