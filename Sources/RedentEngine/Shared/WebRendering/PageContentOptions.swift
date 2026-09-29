import RedentKit

/// The settings that shape what a web view is built with. A view built for one
/// set is never reused for another, and a change reaches live views in place.
struct PageContentOptions: Equatable, Sendable {
    var blocksTrackers: Bool
    var quietsPages: Bool

    init(blocksTrackers: Bool = true, quietsPages: Bool = true) {
        self.blocksTrackers = blocksTrackers
        self.quietsPages = quietsPages
    }

    init(_ settings: BrowserSettings) {
        self.init(blocksTrackers: settings.blocksTrackers, quietsPages: settings.quietsPages)
    }
}
