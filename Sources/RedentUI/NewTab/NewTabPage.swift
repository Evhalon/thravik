import RedentDesign
import SwiftUI

/// What a new tab shows: a greeting, a search field, and the places the user
/// actually goes. No blank canvas, and nothing to dismiss.
struct NewTabPage: View {
    @Bindable var model: BrowserModel
    @State private var newTab: NewTabModel
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var showsFolderEditor = false
    @State private var openedFolder: FavoriteFolder?

    init(model: BrowserModel) {
        self.model = model
        _newTab = State(initialValue: NewTabModel(history: model.history, bookmarks: model.bookmarks))
    }

    var body: some View {
        ZStack {
            NewTabBackdrop(space: model.currentSpace)
            GeometryReader { proxy in
                VStack(spacing: 16) {
                    header
                        .padding(.bottom, 10)
                    NewTabSearchField(model: model, text: $query, isFocused: $isSearchFocused, onSubmit: submit)
                    NewTabScrollArea { content }
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 20)
                .padding(.top, topInset(in: proxy.size.height))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .defaultFocus($isSearchFocused, true)
            folderOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showsFolderEditor) {
            FavoriteFolderEditor { await newTab.createFavoriteFolder(named: $0) }
        }
        .task(id: model.currentSpaceID) { await loadFavorites() }
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

    /// Sits the greeting a little above centre, where it rests in a tall
    /// window; the grid then runs to the bottom edge and scrolls there.
    private func topInset(in height: CGFloat) -> CGFloat {
        max(40, (height - 620) / 2 + 40)
    }

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
            NewTabEmptyState(
                onImport: { model.sheet = .importBrowser },
                onCreateFolder: { showsFolderEditor = true }
            )
        } else {
            NewTabGrid(
                favorites: newTab.rootFavoriteTiles,
                folders: newTab.favoriteFolders,
                frequent: newTab.frequentTiles,
                tilesForFolder: newTab.favoriteTiles(in:),
                onOpen: { tile, inNewTab in model.open(tile.url, inNewTab: inNewTab) },
                onOpenFolder: { openedFolder = $0 },
                onCreateFolder: { showsFolderEditor = true },
                onMoveFavorite: { id, folder in
                    Task { await newTab.moveFavorite(id, into: folder) }
                },
                onRemoveFavorite: { tile in
                    Task { await newTab.removeFavorite(tile) }
                }
            )
        }
    }

    @ViewBuilder
    private var folderOverlay: some View {
        if let folder = openedFolder {
            FavoriteFolderOverlay(
                folder: folder,
                tiles: newTab.favoriteTiles(in: folder),
                onOpen: openFolderTile,
                onRemoveFromFolder: removeFromFolder,
                onDeleteFolder: deleteFolder,
                onDismiss: { openedFolder = nil }
            )
        }
    }

    private func openFolderTile(_ tile: NewTabTile, inNewTab: Bool) {
        model.open(tile.url, inNewTab: inNewTab)
        openedFolder = nil
    }

    private func removeFromFolder(_ id: UUID) {
        Task { await newTab.removeFavoriteFromFolder(id) }
    }

    private func deleteFolder(_ folder: FavoriteFolder) {
        Task { await newTab.deleteFavoriteFolder(folder) }
    }

    private func loadFavorites() async {
        await newTab.load(in: model.currentSpaceID)
        await newTab.preloadFavoriteIcons()
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
