import Foundation

/// ⌘-click on a user-activated link opens a new tab. Redirects, form posts,
/// and other navigations stay in the current tab even if ⌘ is down.
public enum LinkActivation {
    public static func opensNewTab(isUserLink: Bool, commandHeld: Bool) -> Bool {
        isUserLink && commandHeld
    }
}
