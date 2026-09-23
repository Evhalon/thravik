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
    @State private var favoriteToRename: NewTabTile?

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
        .sheet(item: $favoriteToRename) { tile in
            FavoriteNameEditor(tile: tile) { await newTab.renameFavorite(tile, to: $0) }
        }
        .task(id: model.currentSpaceID) { await loadFavorites() }
        .onAppear { isSearchFocused = true }
        .task(id: model.centerSearchFocusEpoch) { await claimSearchFocus() }
    }

    private func claimSearchFocus() async {
        isSearchFocused = true
        try? await Task.sleep(for: .milliseconds(50))
        isSearchFocused = true
    }

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
                onRenameFavorite: { favoriteToRename = $0 },
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
                onRenameFavorite: { favoriteToRename = $0 },
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
        if model.submitNewTabQuery(query) { query = "" }
    }
}
