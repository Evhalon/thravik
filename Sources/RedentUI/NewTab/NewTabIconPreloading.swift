import Foundation

extension NewTabModel {
    func preloadFavoriteIcons() async {
        let requestedSpaceID = spaceID
        let icons = await SiteIconLoader.shared.icons(for: favoriteHostsMissingIcons)
        guard !Task.isCancelled, spaceID == requestedSpaceID else { return }
        updateFavoriteIcons(icons)
    }

    var favoriteHostsMissingIcons: [String] {
        Set(favorites.compactMap { bookmark in
            guard bookmark.faviconData == nil else { return nil }
            return bookmark.origin?.displayHost
        }).sorted()
    }
}
