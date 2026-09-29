import Foundation

/// Picks the tab that should be selected after closing one.
public enum TabCloseSelection: Sendable {
    /// The row above `closedID` in visual order. Closing the top row selects the
    /// row that sat beneath it. Closing the last remaining tab selects nothing.
    public static func afterClosing(_ closedID: UUID, in order: [UUID]) -> UUID? {
        guard let index = order.firstIndex(of: closedID) else { return order.first }
        if index > 0 { return order[index - 1] }
        return order.dropFirst().first
    }
}
