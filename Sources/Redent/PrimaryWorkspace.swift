import Foundation
import RedentKit

/// What the primary window starts from each time SwiftUI builds it.
///
/// The disk is read once, at launch. SwiftUI can tear the primary window down
/// and build it again while the app keeps running — closing and reopening it,
/// or a disappear the user never saw — and a rebuild from the launch snapshot
/// brought back every tab closed since, then saved them over the real session.
struct PrimaryWorkspace {
    private var restored: Result<BrowserSession, any Error>

    init(restored: Result<BrowserSession, any Error>) {
        self.restored = restored
    }

    var session: BrowserSession { (try? restored.get()) ?? BrowserSession() }

    var restoreFailed: Bool {
        guard case .failure = restored else { return false }
        return true
    }

    /// The window being released is the newest truth, whatever launch loaded.
    mutating func windowReleased(with session: BrowserSession) {
        restored = .success(session)
    }
}
