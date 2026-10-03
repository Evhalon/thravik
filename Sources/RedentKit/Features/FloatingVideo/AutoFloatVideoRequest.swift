import Foundation

/// Inputs for whether a tab switch should float or restore a video.
public struct AutoFloatVideoRequest: Sendable, Equatable {
    public var previous: AutoFloatVideoTab?
    public var selected: AutoFloatVideoTab?
    public var settingEnabled: Bool
    public var floatingTabID: UUID?

    public init(
        previous: AutoFloatVideoTab?,
        selected: AutoFloatVideoTab?,
        settingEnabled: Bool,
        floatingTabID: UUID?
    ) {
        self.previous = previous
        self.selected = selected
        self.settingEnabled = settingEnabled
        self.floatingTabID = floatingTabID
    }
}
