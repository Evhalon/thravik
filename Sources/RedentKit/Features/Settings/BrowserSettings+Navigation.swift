import Foundation

extension BrowserSettings {
    public mutating func setNavigationBarHidden(_ hidden: Bool) {
        hidesNavigationBar = hidden
        guard hidden else { return }
        tabLayout = .sidebar
        isTabStripVisible = true
    }

    public var hibernationIdleThreshold: TimeInterval? {
        guard hibernation == .custom else { return hibernation.idleThreshold }
        return TimeInterval(max(customHibernationMinutes ?? 15, 1) * 60)
    }
}
