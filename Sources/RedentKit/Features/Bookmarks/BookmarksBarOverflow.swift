import Foundation

/// How many bar chips fit before the trailing overflow menu.
public enum BookmarksBarOverflow {
    public struct Plan: Equatable, Sendable {
        public let visibleCount: Int
        public let overflowCount: Int

        public var hasOverflow: Bool { overflowCount > 0 }
    }

    /// The `»` glyph, its padding, and the inset AppKit adds around a menu label.
    public static let overflowButtonWidth: Double = 36
    public static let spacing: Double = 6

    public static func plan(
        itemWidths: [Double],
        availableWidth: Double,
        overflowWidth: Double,
        spacing: Double
    ) -> Plan {
        let count = itemWidths.count
        guard count > 0 else { return Plan(visibleCount: 0, overflowCount: 0) }
        if totalWidth(itemWidths, spacing: spacing) <= availableWidth {
            return Plan(visibleCount: count, overflowCount: 0)
        }
        let budget = max(0, availableWidth - overflowWidth - spacing)
        let visible = countFitting(itemWidths, budget: budget, spacing: spacing)
        return Plan(visibleCount: visible, overflowCount: count - visible)
    }

    private static func totalWidth(_ widths: [Double], spacing: Double) -> Double {
        widths.reduce(0, +) + spacing * Double(max(widths.count - 1, 0))
    }

    private static func countFitting(_ widths: [Double], budget: Double, spacing: Double) -> Int {
        var used = 0.0
        var count = 0
        for width in widths {
            let next = count == 0 ? width : used + spacing + width
            guard next <= budget else { break }
            used = next
            count += 1
        }
        return count
    }
}
