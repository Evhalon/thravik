import RedentKit

extension BrowserModel {
    public var canFloatVideo: Bool { selectedTab?.canFloatVideo ?? false }
    public var isVideoFloating: Bool { selectedTab?.isVideoFloating ?? false }
    public var showsFloatVideoControl: Bool { canFloatVideo || isVideoFloating }

    public func toggleFloatingVideo() {
        guard let tab = selectedTab else { return }
        Task {
            if await !tab.toggleFloatingVideo() {
                actionError = "This video could not be floated. Try the site's picture-in-picture control."
            }
        }
    }
}
