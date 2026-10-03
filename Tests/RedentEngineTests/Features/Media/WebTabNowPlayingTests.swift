import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Tab now playing")
@MainActor
struct WebTabNowPlayingTests {
    @Test("Media session metadata fills now playing once audio starts")
    func metadataBecomesNowPlaying() throws {
        let (_, tab) = try backgroundTab()
        tab.receiveMediaSession([
            "title": "Night Drive",
            "artist": "Nova",
            "artwork": "https://cdn.example/art.jpg"
        ])
        #expect(tab.nowPlaying == nil)

        tab.mediaFrame("main", isAudible: true)
        let playing = try #require(tab.nowPlaying)
        #expect(playing.title == "Night Drive")
        #expect(playing.artist == "Nova")
        #expect(playing.artworkURL?.host == "cdn.example")
        #expect(playing.isPlaying)
        #expect(!playing.canSkip)
        #expect(playing.tabID == tab.id)
    }

    @Test("Missing metadata falls back to the tab title")
    func fallsBackToTabTitle() throws {
        let (_, tab) = try backgroundTab()
        tab.mediaFrame("main", isAudible: true)
        #expect(tab.nowPlaying?.title == "Music")
        #expect(tab.nowPlaying?.artist == nil)
    }

    @Test("A new page drops the previous track")
    func resetClearsNowPlaying() throws {
        let (_, tab) = try backgroundTab()
        tab.receiveMediaSession(["title": "Old"])
        tab.mediaFrame("main", isAudible: true)
        #expect(tab.nowPlaying != nil)
        tab.resetMediaFrames()
        #expect(tab.nowPlaying == nil)
    }

    @Test("Pausing a background tab keeps a resumable card")
    func pausedBackgroundStays() throws {
        let (_, tab) = try backgroundTab()
        tab.mediaFrame("main", isAudible: true)
        tab.mediaFrame("main", isAudible: false)
        let paused = try #require(tab.nowPlaying)
        #expect(!paused.isPlaying)
    }

    @Test("A muted video playing in the background is not now playing")
    func mutedVideoIgnored() throws {
        let (_, tab) = try backgroundTab()
        tab.receiveVideoState(["available": true, "playing": true, "aspect": 1.7])
        #expect(tab.nowPlaying == nil)
    }

    @Test("Selecting the paused tab, ending, or dismissing drops the card")
    func pausedCardClears() throws {
        let (browser, tab) = try backgroundTab()
        tab.mediaFrame("main", isAudible: true)
        tab.mediaFrame("main", isAudible: false)
        browser.select(tab.id)
        #expect(tab.nowPlaying == nil)

        tab.mediaFrame("main", isAudible: true)
        tab.mediaFrame("main", isAudible: false)
        tab.receiveMediaSession(["ended": true])
        #expect(tab.nowPlaying == nil)

        tab.mediaFrame("main", isAudible: true)
        tab.dismissNowPlaying()
        tab.mediaFrame("main", isAudible: false)
        #expect(tab.nowPlaying == nil)
    }

    @Test("Leaving a tab that is still playing keeps its card")
    func leavingPlayingTabKeepsCard() throws {
        let (browser, tab) = try backgroundTab()
        let front = try #require(browser.selectedID)
        browser.select(tab.id)
        tab.mediaFrame("main", isAudible: true)
        browser.select(front)
        #expect(tab.nowPlaying?.isPlaying == true)
    }

    private func backgroundTab() throws -> (TabController, WebTab) {
        let first = TabSnapshot(url: URL(string: "https://front.example"), title: "Front")
        let second = TabSnapshot(url: URL(string: "https://music.example"), title: "Music")
        let browser = TabController(
            session: BrowserSession(tabs: [first, second], selectedTabID: first.id),
            settings: BrowserSettings(),
            logger: NowPlayingLogger()
        )
        return (browser, try #require(browser.webTabs.first { $0.id == second.id }))
    }
}

private struct NowPlayingLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
