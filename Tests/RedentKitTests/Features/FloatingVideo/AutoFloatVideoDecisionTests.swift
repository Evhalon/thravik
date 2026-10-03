import Foundation
import RedentKit
import Testing

@Suite("Auto float video on tab switch")
struct AutoFloatVideoDecisionTests {
    private let leaving = UUID()
    private let arriving = UUID()
    private let other = UUID()

    @Test("Playing, sizable video floats when the setting is on")
    func floatsPlayingVideo() {
        let action = AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: playable),
            selected: tab(arriving),
            enabled: true
        ))
        #expect(action == .float(leaving))
    }

    @Test("Setting off leaves the page video alone")
    func settingOffDoesNothing() {
        let action = AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: playable),
            selected: tab(arriving),
            enabled: false
        ))
        #expect(action == .none)
    }

    @Test("Paused or tiny videos do not float")
    func requiresPlayingAndSize() {
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: video(playing: false, canFloat: true)),
            selected: tab(arriving),
            enabled: true
        )) == .none)
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: video(playing: true, canFloat: false)),
            selected: tab(arriving),
            enabled: true
        )) == .none)
    }

    @Test("Hibernated and already-floating tabs are not floated again")
    func skipsHibernatedAndFloating() {
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: playable, hibernated: true),
            selected: tab(arriving),
            enabled: true
        )) == .none)
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: video(playing: true, canFloat: true, floating: true)),
            selected: tab(arriving),
            enabled: true
        )) == .none)
    }

    @Test("A split-pane tab or a muted autoplay preview stays in the page")
    func splitPaneAndMutedStay() {
        var muted = playable
        muted.isAudible = false
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: playable, onScreen: true), selected: tab(arriving), enabled: true
        )) == .none)
        #expect(AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: muted), selected: tab(arriving), enabled: true
        )) == .none)
    }

    @Test("Another floating video blocks auto-float")
    func existingFloatWins() {
        let action = AutoFloatVideoDecision.action(request(
            previous: tab(leaving, video: playable),
            selected: tab(arriving),
            enabled: true,
            floating: other
        ))
        #expect(action == .none)
    }

    @Test("Returning to an auto-floated tab restores the page video")
    func returnsAutoFloatedTab() {
        let selected = tab(arriving, video: video(floating: true, automatic: true))
        let action = AutoFloatVideoDecision.action(request(
            previous: tab(leaving),
            selected: selected,
            enabled: true,
            floating: arriving
        ))
        #expect(action == .returnToPage(arriving))
    }

    @Test("A manually floated video stays up when its tab is selected")
    func keepsManualFloat() {
        let action = AutoFloatVideoDecision.action(request(
            previous: tab(leaving),
            selected: tab(arriving, video: video(floating: true)),
            enabled: true,
            floating: arriving
        ))
        #expect(action == .none)
    }

    private func request(
        previous: AutoFloatVideoTab?,
        selected: AutoFloatVideoTab?,
        enabled: Bool,
        floating: UUID? = nil
    ) -> AutoFloatVideoRequest {
        AutoFloatVideoRequest(
            previous: previous,
            selected: selected,
            settingEnabled: enabled,
            floatingTabID: floating
        )
    }

    private var playable: AutoFloatVideoTab.Video { video(playing: true, canFloat: true) }

    private func tab(
        _ id: UUID,
        video: AutoFloatVideoTab.Video = .init(
            isPlaying: false, canFloat: false, isFloating: false, floatedAutomatically: false
        ),
        hibernated: Bool = false,
        onScreen: Bool = false
    ) -> AutoFloatVideoTab {
        AutoFloatVideoTab(id: id, isHibernated: hibernated, isOnScreen: onScreen, video: video)
    }

    private func video(
        playing: Bool = false,
        canFloat: Bool = false,
        floating: Bool = false,
        automatic: Bool = false
    ) -> AutoFloatVideoTab.Video {
        AutoFloatVideoTab.Video(
            isPlaying: playing,
            canFloat: canFloat,
            isFloating: floating,
            floatedAutomatically: automatic
        )
    }
}
