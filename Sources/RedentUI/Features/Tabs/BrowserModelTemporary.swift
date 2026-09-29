import Foundation
import RedentKit

/// The temporary-tab role from the chrome's side: opening one, and answering
/// the prompt when the one you are reading reaches its deadline.
extension BrowserModel {
    /// No deadline by default: temporary is a role the user chooses, not a
    /// countdown imposed on them.
    public func openTemporaryTab() {
        tabs.newTemporaryTab(url: nil, expiresAt: nil)
        requestCenterSearchFocus()
    }

    public func keepExpiredTab() {
        guard let id = expiredTabID else { return }
        tabs.keepTab(id)
        expiredTabID = nil
    }

    public func closeExpiredTab() {
        guard let id = expiredTabID else { return }
        tabs.close(id)
        expiredTabID = nil
    }
}
