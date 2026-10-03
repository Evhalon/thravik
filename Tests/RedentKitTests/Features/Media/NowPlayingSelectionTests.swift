import Foundation
import RedentKit
import Testing

@Suite("Now playing tab selection")
struct NowPlayingSelectionTests {
    private let selected = UUID()
    private let older = UUID()
    private let newer = UUID()

    @Test("Ignores the selected tab even when it is playing")
    func excludesSelected() {
        let pick = NowPlayingSelection.pick(
            from: [item(selected, playing: true, at: 20), item(older, playing: true, at: 10)],
            selectedTabID: selected
        )
        #expect(pick?.tabID == older)
    }

    @Test("Among background players, the most recently started wins")
    func mostRecentPlaying() {
        let pick = NowPlayingSelection.pick(
            from: [item(older, playing: true, at: 5), item(newer, playing: true, at: 15)],
            selectedTabID: selected
        )
        #expect(pick?.tabID == newer)
    }

    @Test("A paused background tab keeps the card so it can be resumed")
    func pausedStaysResumable() {
        let pick = NowPlayingSelection.pick(
            from: [item(older, playing: false, at: 50)],
            selectedTabID: selected
        )
        #expect(pick?.tabID == older)
        #expect(pick?.isPlaying == false)
    }

    @Test("A playing background tab beats a more recently paused one")
    func playingBeatsPaused() {
        let pick = NowPlayingSelection.pick(
            from: [item(older, playing: true, at: 5), item(newer, playing: false, at: 50)],
            selectedTabID: selected
        )
        #expect(pick?.tabID == older)
    }

    @Test("The newest paused tab wins when nothing plays")
    func newestPaused() {
        let pick = NowPlayingSelection.pick(
            from: [item(older, playing: false, at: 5), item(newer, playing: false, at: 50)],
            selectedTabID: selected
        )
        #expect(pick?.tabID == newer)
    }

    @Test("A paused selected tab never shows the card")
    func pausedSelectedExcluded() {
        let pick = NowPlayingSelection.pick(
            from: [item(selected, playing: false, at: 50)],
            selectedTabID: selected
        )
        #expect(pick == nil)
    }

    @Test("No card when every player is the selected tab")
    func emptyWhenOnlySelectedPlays() {
        let pick = NowPlayingSelection.pick(
            from: [item(selected, playing: true, at: 1)],
            selectedTabID: selected
        )
        #expect(pick == nil)
    }

    private func item(_ id: UUID, playing: Bool, at seconds: TimeInterval) -> NowPlaying {
        NowPlaying(
            tabID: id,
            title: "Track",
            isPlaying: playing,
            updatedAt: Date(timeIntervalSince1970: seconds)
        )
    }
}
