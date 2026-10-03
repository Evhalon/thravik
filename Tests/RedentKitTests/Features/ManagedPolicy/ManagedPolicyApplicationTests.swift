import Foundation
import Testing
@testable import RedentKit

@Suite("Managed policy application")
struct ManagedPolicyApplicationTests {
    @Test("Empty policy leaves settings unchanged")
    func identityWithoutPolicy() {
        let user = BrowserSettings(searchEngine: .bing, homepage: "https://example.com")
        let snapshot = ManagedPolicyApplication.apply(user: user, policy: ManagedPolicy())
        #expect(snapshot.settings == user)
        #expect(snapshot.locked.isEmpty)
    }

    @Test("Forced homepage and tracker blocking lock fields")
    func homepageAndTrackers() {
        let user = BrowserSettings(blocksTrackers: false, homepage: "https://example.com")
        let policy = ManagedPolicy(homepageURL: "https://corp.example/", forceTrackerBlocking: true)
        let snapshot = ManagedPolicyApplication.apply(user: user, policy: policy)
        #expect(snapshot.settings.homepage == "https://corp.example/")
        #expect(snapshot.settings.blocksTrackers)
        #expect(snapshot.locked == [.homepage, .blocksTrackers])
    }

    @Test("Built-in search engine override")
    func builtInSearch() {
        let user = BrowserSettings(searchEngine: .duckduckgo)
        let policy = ManagedPolicy(defaultSearchEngine: .builtIn(.google))
        let snapshot = ManagedPolicyApplication.apply(user: user, policy: policy)
        #expect(snapshot.settings.searchEngine == .google)
        #expect(snapshot.locked.contains(.searchEngine))
    }

    @Test("Managed search engine leaves an unlocked homepage alone")
    func searchKeepsHomepage() {
        let user = BrowserSettings(searchEngine: .duckduckgo, homepage: "https://duckduckgo.com")
        let builtIn = ManagedPolicyApplication.apply(user: user, policy: ManagedPolicy(defaultSearchEngine: .builtIn(.bing)))
        #expect(builtIn.settings.homepage == "https://duckduckgo.com")
        let template = ManagedDefaultSearchEngine.customTemplate("https://search.corp.test/?q=%s")
        let custom = ManagedPolicyApplication.apply(user: user, policy: ManagedPolicy(defaultSearchEngine: template))
        #expect(custom.settings.homepage == "https://duckduckgo.com")
        #expect(!custom.locked.contains(.homepage))
    }

    @Test("Persist keeps locked fields from stored copy")
    func persistRespectsLocks() {
        let stored = BrowserSettings(blocksTrackers: false, homepage: "https://stored.test")
        let effective = BrowserSettings(blocksTrackers: true, homepage: "https://managed.test")
        let policy = ManagedPolicy(homepageURL: "https://managed.test", forceTrackerBlocking: true)
        let saved = ManagedPolicyApplication.storedUserSettings(
            effective: effective,
            previousStored: stored,
            policy: policy
        )
        #expect(saved.homepage == "https://stored.test")
        #expect(saved.blocksTrackers == false)
    }

    @Test("Persist writes every unlocked field the user edited")
    func persistKeepsUnlockedEdits() {
        let stored = BrowserSettings(homepage: "https://stored.test")
        var effective = BrowserSettings(tabLayout: .top, homepage: "https://managed.test")
        effective.showsUpcomingMeetings = true
        effective.tidyTabsThreshold = TidyTabsThreshold.allCases.last ?? .off
        let saved = ManagedPolicyApplication.storedUserSettings(
            effective: effective,
            previousStored: stored,
            policy: ManagedPolicy(homepageURL: "https://managed.test")
        )
        var expected = effective
        expected.homepage = "https://stored.test"
        #expect(saved == expected)
    }
}
