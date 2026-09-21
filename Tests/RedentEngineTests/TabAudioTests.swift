import Foundation
import Testing
import RedentKit
@testable import RedentEngine

@Suite("Tab audio")
@MainActor
struct TabAudioTests {
    @Test("A background tab playing sound is not put to sleep")
    func playingTabStaysAwake() throws {
        let (browser, background) = try backgroundTab()
        background.mediaFrame("main", isAudible: true)

        browser.sweepHibernation(now: .now, keeping: [])
        #expect(!background.isHibernated)
    }

    @Test("Once the sound stops, the idle tab sleeps as usual")
    func silentTabSleeps() throws {
        let (browser, background) = try backgroundTab()
        background.mediaFrame("main", isAudible: true)
        background.mediaFrame("main", isAudible: false)

        browser.sweepHibernation(now: .now, keeping: [])
        #expect(background.isHibernated)
        #expect(!background.isPlayingAudio)
    }

    @Test("The tab plays while any one of its frames does")
    func framesAggregate() throws {
        let (_, tab) = try backgroundTab()
        tab.mediaFrame("main", isAudible: true)
        tab.mediaFrame("embed", isAudible: true)
        tab.mediaFrame("main", isAudible: false)
        #expect(tab.isPlayingAudio)

        tab.resetMediaFrames()
        #expect(!tab.isPlayingAudio)
    }

    @Test("Mute belongs to the tab and outlives a new page")
    func muteSurvivesNavigation() throws {
        let (_, tab) = try backgroundTab()
        tab.setMuted(true)
        tab.resetMediaFrames()
        #expect(tab.isMuted)
    }

    private func backgroundTab() throws -> (TabController, WebTab) {
        let first = TabSnapshot(url: URL(string: "https://front.example"), title: "Front")
        let second = TabSnapshot(url: URL(string: "https://music.example"), title: "Music")
        var settings = BrowserSettings()
        settings.hibernation = .aggressive
        let browser = TabController(
            session: BrowserSession(tabs: [first, second], selectedTabID: first.id),
            settings: settings, logger: SilentLogger()
        )
        let background = try #require(browser.webTabs.first { $0.id == second.id })
        background.wake(loading: URL(string: "https://music.example"))
        background.snapshot.lastActiveAt = Date(timeIntervalSinceNow: -10_000)
        return (browser, background)
    }
}

private struct SilentLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
