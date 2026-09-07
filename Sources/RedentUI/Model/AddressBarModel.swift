import Foundation
import Observation
import RedentKit

/// Address-bar state, kept deliberately separate from the browser model so the
/// "what the user is typing" concern never fights "what the tab is showing".
@MainActor @Observable
public final class AddressBarModel {
    public var text: String = ""
    public var isEditing: Bool = false

    private var lastSyncedURL: URL?

    public init() {}

    /// Pulls the address in from the active tab — unless the user is mid-edit,
    /// in which case their typing wins.
    public func sync(with tab: (any BrowserTab)?) {
        guard !isEditing else { return }
        let url = tab?.url
        guard url != lastSyncedURL else { return }
        lastSyncedURL = url
        text = url.map(Self.prettyPrint) ?? ""
    }

    public func beginEditing() {
        isEditing = true
    }

    /// - Returns: the URL to load, or `nil` if the input was empty.
    public func commit(using engine: SearchEngine) -> URL? {
        isEditing = false
        return AddressResolver.resolve(text, using: engine)
    }

    /// Ends editing without changing the text — used when a dropdown row is
    /// opened, since the address will be replaced by the page's own URL.
    public func finishEditing() {
        isEditing = false
        lastSyncedURL = nil
    }

    public func cancelEditing(restoringFrom tab: (any BrowserTab)?) {
        isEditing = false
        lastSyncedURL = nil
        sync(with: tab)
    }

    /// `https://www.example.com/path` → `example.com/path`. The scheme is noise
    /// in the common case; the lock badge carries the security signal instead.
    static func prettyPrint(_ url: URL) -> String {
        guard let scheme = url.scheme, scheme == "http" || scheme == "https" else {
            return url.absoluteString
        }
        var shown = url.absoluteString
        shown.removeFirst(scheme.count + 3)
        if shown.hasPrefix("www.") { shown.removeFirst(4) }
        if shown.hasSuffix("/") { shown.removeLast() }
        return shown
    }
}
