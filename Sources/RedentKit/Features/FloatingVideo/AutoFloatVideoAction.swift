import Foundation

public enum AutoFloatVideoAction: Sendable, Equatable {
    case none
    case float(UUID)
    case returnToPage(UUID)
}
