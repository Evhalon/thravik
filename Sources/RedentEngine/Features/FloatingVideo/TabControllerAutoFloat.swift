import Foundation
import RedentKit

extension TabController {
    func applyAutoFloatVideo(from previousID: UUID?, to selectedID: UUID) {
        let onScreen = onScreenTabIDs?() ?? [selectedID]
        let previous = previousID.flatMap { autoFloatState($0, onScreen: onScreen) }
        let selected = autoFloatState(selectedID, onScreen: onScreen)
        let floatingTabID = webTabs.first { $0.isVideoFloating }?.id
        let action = AutoFloatVideoDecision.action(
            AutoFloatVideoRequest(
                previous: previous,
                selected: selected,
                settingEnabled: settings.floatsPlayingVideoOnTabSwitch,
                floatingTabID: floatingTabID
            )
        )
        perform(action)
    }

    private func perform(_ action: AutoFloatVideoAction) {
        switch action {
        case .none:
            return
        case .float(let id):
            guard let tab = webTabs.first(where: { $0.id == id }) else { return }
            Task { [weak self] in
                // The user may have come back while the panel was opening.
                guard await tab.floatVideoAutomatically(), self?.selectedID == id else { return }
                tab.returnVideoToTab()
            }
        case .returnToPage(let id):
            webTabs.first { $0.id == id }?.returnVideoToTab()
        }
    }

    private func autoFloatState(_ id: UUID, onScreen: Set<UUID>) -> AutoFloatVideoTab? {
        guard let tab = webTabs.first(where: { $0.id == id }) else { return nil }
        return AutoFloatVideoTab(
            id: tab.id,
            isHibernated: tab.isHibernated,
            isOnScreen: onScreen.contains(id),
            video: .init(
                isPlaying: tab.isVideoPlaying,
                canFloat: tab.canFloatVideo,
                // Counts a tab the user muted in Redent, unlike the element's own flag.
                isAudible: tab.isPlayingAudio,
                isFloating: tab.isVideoFloating,
                floatedAutomatically: tab.didAutoFloatVideo
            )
        )
    }
}
