import AppKit
import RedentKit

/// Measured chip widths for the overflow plan. The chips draw with these same
/// constants, so a measured width never undercounts what lands on screen.
@MainActor
enum BookmarksBarChipMetrics {
    static let horizontalPadding: CGFloat = 8
    static let verticalPadding: CGFloat = 3
    static let iconSpacing: CGFloat = 5
    static let faviconSize: CGFloat = 12
    static let titleSize: CGFloat = 11.5
    static let folderGlyphSize: CGFloat = 10
    static let chevronSize: CGFloat = 7
    static let maxWidth: CGFloat = 173
    /// AppKit hosts a menu label in a borderless pop-up button that adds its own inset.
    private static let menuInset: CGFloat = 8
    private static let rounding: CGFloat = 2

    static func width(of item: BookmarksBarItem) -> Double {
        let title = textWidth(item.title)
        let content = switch item {
        case .page: faviconSize + iconSpacing + title
        case .folder: folderGlyphWidth + iconSpacing + title + iconSpacing + chevronWidth + menuInset
        }
        return Double(min(ceil(content + horizontalPadding * 2 + rounding), maxWidth + menuInset))
    }

    private static func textWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: titleSize)
        return NSAttributedString(string: text, attributes: [.font: font]).size().width
    }

    private static let folderGlyphWidth = glyphWidth("folder", size: folderGlyphSize, weight: .semibold)
    private static let chevronWidth = glyphWidth("chevron.down", size: chevronSize, weight: .bold)

    private static func glyphWidth(_ name: String, size: CGFloat, weight: NSFont.Weight) -> CGFloat {
        let configuration = NSImage.SymbolConfiguration(pointSize: size, weight: weight)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        return image?.size.width ?? size * 1.5
    }
}
