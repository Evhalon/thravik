import AppKit
import RedentKit

@MainActor
final class FloatingVideoPresentation {
    var makeControls: (@MainActor (any FloatingVideoControlling) -> NSView)?
    weak var activeTab: WebTab?
}

extension TabController {
    public func configureFloatingVideo(
        controls: @escaping @MainActor (any FloatingVideoControlling) -> NSView
    ) {
        videoPresentation.makeControls = controls
    }
}
