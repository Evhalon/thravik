import Foundation

/// Pure tab-switch policy for auto picture-in-picture.
public enum AutoFloatVideoDecision {
    public static func action(_ request: AutoFloatVideoRequest) -> AutoFloatVideoAction {
        if let selected = request.selected, shouldReturn(selected) {
            return .returnToPage(selected.id)
        }
        guard request.settingEnabled, let previous = request.previous else { return .none }
        guard canFloatLeaving(previous, floatingTabID: request.floatingTabID) else { return .none }
        return .float(previous.id)
    }

    private static func shouldReturn(_ selected: AutoFloatVideoTab) -> Bool {
        selected.video.isFloating && selected.video.floatedAutomatically
    }

    private static func canFloatLeaving(_ previous: AutoFloatVideoTab, floatingTabID: UUID?) -> Bool {
        guard !previous.isHibernated, !previous.isOnScreen, !previous.video.isFloating else { return false }
        guard floatingTabID == nil else { return false }
        return previous.video.isPlaying && previous.video.canFloat && previous.video.isAudible
    }
}
