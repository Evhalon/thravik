import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Import destination Spaces")
struct BrowserImportDestinationTests {
    private let profiles = [
        ImportableBrowser.fake("Chrome/Default"),
        ImportableBrowser.fake("Chrome/Profile 1"),
        ImportableBrowser.fake("Chrome/Profile 2")
    ]

    @Test("Each source profile gets a distinct Space and retry reuses them")
    func createsOneSpacePerProfileAndReusesOnRetry() async {
        let bookmarks = RecordingBookmarkStore()
        let model = makeModel(bookmarks: bookmarks, profiles: profiles)
        var created: [String: UUID] = [:]
        model.createSpace = { name in
            let id = UUID()
            created[name] = id
            return id
        }
        model.kinds = [.bookmarks]
        model.discover()

        await model.run()
        await model.run()

        let saved = await bookmarks.merged
        #expect(created.count == profiles.count)
        #expect(Set(created.values).count == profiles.count)
        #expect(Set(saved.compactMap(\.spaceID)) == Set(created.values))
        #expect(saved.count == profiles.count)
    }

    @Test("A failed Space creation skips that profile and continues")
    func creationFailureDoesNotStopOtherProfiles() async {
        let bookmarks = RecordingBookmarkStore()
        let model = makeModel(bookmarks: bookmarks, profiles: profiles)
        model.createSpace = { name in
            if name == profiles[0].name { throw CocoaError(.fileWriteUnknown) }
            return UUID()
        }
        model.kinds = [.bookmarks]
        model.discover()

        await model.run()

        let saved = await bookmarks.merged
        #expect(model.summary?.bookmarks == 2)
        #expect(saved.count == 2)
        #expect(model.problem?.contains("Those profiles were skipped") == true)
    }

    private func makeModel(
        bookmarks: RecordingBookmarkStore,
        profiles: [ImportableBrowser]
    ) -> BrowserImportModel {
        let seed = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, FakeBrowserImporter.Profile(bookmarks: 1)) })
        return BrowserImportModel(
            importer: FakeBrowserImporter(profiles: seed, browsers: profiles),
            history: RecordingHistoryStore(),
            bookmarks: bookmarks,
            credentials: FakeCredentialStore(),
            destination: ImportDestination(spaces: BrowserSpace.starterSpaces, spaceID: BrowserSpace.travelID)
        )
    }
}
