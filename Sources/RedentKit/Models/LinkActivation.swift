import Foundation

/// Where a clicked link lands. ⌘-click opens a tab and leaves the reader on the
/// page they were reading; ⌘⇧-click opens the tab and goes there. Redirects,
/// form posts, and other navigations stay in the current tab even if ⌘ is down.
public enum LinkActivation {
    public enum Target: Equatable, Sendable {
        case currentTab
        case backgroundTab
        case foregroundTab
    }

    public static func target(isUserLink: Bool, commandHeld: Bool, shiftHeld: Bool) -> Target {
        guard isUserLink, commandHeld else { return .currentTab }
        return shiftHeld ? .foregroundTab : .backgroundTab
    }
}
