import Foundation

/// The spacing, radius and size scale for Redent's chrome.
///
/// Radii are deliberately larger than macOS defaults: the chrome reads as a set
/// of floating slabs, and small radii make a slab look like a mistake.
public enum Metric {
    public static let tabRowHeight: CGFloat = 34
    public static let toolbarHeight: CGFloat = 44
    public static let controlHeight: CGFloat = 30

    /// Large surfaces: the floating bar, sheets, the OTP capsule's bounding box.
    public static let cornerRadius: CGFloat = 18
    /// Tab pills, the address field, menus.
    public static let mediumRadius: CGFloat = 11
    /// Icon buttons, favicon tiles.
    public static let smallRadius: CGFloat = 7
    /// The web content card. Slightly tighter than the chrome around it.
    public static let pageRadius: CGFloat = 12

    public static let gutter: CGFloat = 12
    public static let tightGutter: CGFloat = 6
    /// The inset between the chrome and the page card, on every side.
    public static let pageInset: CGFloat = 3
    /// Height of the full-width glass titlebar the window buttons sit on.
    public static let titlebarInset: CGFloat = 30

    /// A true hairline at any scale factor.
    public static let hairWidth: CGFloat = 0.75
}
