import Foundation

extension BrowserSettings {
    public mutating func setNavigationBarHidden(_ hidden: Bool) {
        hidesNavigationBar = hidden
        guard hidden else { return }
        tabLayout = .sidebar
        isTabStripVisible = true
    }
}
