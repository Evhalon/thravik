import Foundation
import RedentKit

/// A web app's window: which app, and the Space whose Container — cookies,
/// storage, logins — it browses in.
struct WebAppWindow: Hashable, Codable {
    let appID: UUID
    let space: BrowserSpace?

    /// A workspace holding only the app's Space, so the window browses in
    /// that Space's session and nowhere else.
    var session: BrowserSession {
        guard let space else { return BrowserSession() }
        return BrowserSession(tabs: [], spaces: [space], selectedSpaceID: space.id)
    }
}
