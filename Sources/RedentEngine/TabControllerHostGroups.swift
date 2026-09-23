import Foundation
import RedentKit

/// Keeps same-site tabs inside their automatic sidebar group, so opening or
/// redirecting to a site joins its group instead of relocating it.
extension TabController {
    func insertIndex(opening url: URL?, in spaceID: UUID?) -> Int {
        HostGroupPlacement.insertionIndex(
            forHost: url.flatMap(Origin.init(url:))?.displayHost,
            spaceID: spaceID,
            in: webTabs.map(\.snapshot)
        ) ?? insertIndexAfterCurrent()
    }

    /// A redirect can land a tab on a site whose group sits further down.
    func settleIntoHostGroup(_ id: UUID) {
        guard let target = HostGroupPlacement.settledIndex(of: id, in: webTabs.map(\.snapshot)),
              let index = webTabs.firstIndex(where: { $0.id == id })
        else { return }
        let tab = webTabs.remove(at: index)
        webTabs.insert(tab, at: target)
        changed()
    }
}
