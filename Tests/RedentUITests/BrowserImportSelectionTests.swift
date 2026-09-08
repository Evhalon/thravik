import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Importing several profiles at once")
struct BrowserImportSelectionTests {
    private static let profiles = [
        ImportableBrowser.fake("Dia/User Data/Default", name: "Dia — Personal"),
        ImportableBrowser.fake("Dia/User Data/Profile 1", name: "Dia — Work"),
        ImportableBrowser.fake("Dia/User Data/Profile 2", name: "Dia — Side")
    ]

    private func makeModel(
        _ importer: FakeBrowserImporter,
        bookmarks: RecordingBookmarkStore = RecordingBookmarkStore(),
        into spaceID: UUID = BrowserSpace.travelID
    ) -> BrowserImportModel {
        BrowserImportModel(
            importer: importer,
            history: RecordingHistoryStore(),
            bookmarks: bookmarks,
            credentials: FakeCredentialStore(),
            destination: ImportDestination(spaces: BrowserSpace.starterSpaces, spaceID: spaceID)
        )
    }

    private func importer(_ seed: [String: FakeBrowserImporter.Profile]) -> FakeBrowserImporter {
        FakeBrowserImporter(profiles: seed, browsers: Self.profiles)
    }

    @Test("Every selected profile is read, and the counts add up")
    func importsAllSelectedProfiles() async {
        let model = makeModel(importer([
            "Dia/User Data/Default": .init(history: 3, bookmarks: 1),
            "Dia/User Data/Profile 1": .init(history: 2, bookmarks: 4),
            "Dia/User Data/Profile 2": .init(history: 5, bookmarks: 2)
        ]))
        model.discover()
        model.selectAll()
        model.kinds = [.history, .bookmarks]

        await model.run()

        #expect(model.summary?.history == 10)
        #expect(model.summary?.bookmarks == 7)
        #expect(model.problem == nil)
    }

    @Test("Unselected profiles are left alone")
    func skipsUnselectedProfiles() async {
        let model = makeModel(importer([
            "Dia/User Data/Default": .init(history: 3),
            "Dia/User Data/Profile 1": .init(history: 2),
            "Dia/User Data/Profile 2": .init(history: 5)
        ]))
        model.discover()
        model.deselectAll()
        model.toggle(browserID: "Dia/User Data/Profile 2")
        model.kinds = [.history]

        await model.run()

        #expect(model.summary?.history == 5)
    }

    @Test("One failing profile does not stop the others")
    func keepsGoingAfterAFailure() async {
        let model = makeModel(importer([
            "Dia/User Data/Default": .init(passwords: 2),
            "Dia/User Data/Profile 1": .init(passwordError: .decryptionKeyUnavailable),
            "Dia/User Data/Profile 2": .init(passwords: 3)
        ]))
        model.discover()
        model.selectAll()
        model.kinds = [.passwords]

        await model.run()

        #expect(model.summary?.passwords == 5)
        #expect(model.problem?.contains("Allow") == true)
    }

    @Test("Discovery selects one profile, and toggling is independent")
    func selectionDefaultsAndToggles() {
        let model = makeModel(importer([:]))
        model.discover()

        #expect(model.selectedIDs == ["Dia/User Data/Default"])
        #expect(!model.isEverythingSelected)

        model.toggle(browserID: "Dia/User Data/Profile 1")
        #expect(model.selectedIDs.count == 2)
        #expect(model.selectedBrowsers.map(\.id) == [
            "Dia/User Data/Default", "Dia/User Data/Profile 1"
        ])

        model.toggle(browserID: "Dia/User Data/Default")
        #expect(model.selectedIDs == ["Dia/User Data/Profile 1"])

        model.selectAll()
        #expect(model.isEverythingSelected)
        #expect(model.canRun)

        model.deselectAll()
        #expect(!model.canRun)
    }

    @Test("Imported bookmarks join the chosen Space")
    func bookmarksJoinTheChosenSpace() async {
        let bookmarks = RecordingBookmarkStore()
        let model = makeModel(
            importer(["Dia/User Data/Default": .init(history: 0, bookmarks: 2)]),
            bookmarks: bookmarks,
            into: BrowserSpace.researchID
        )
        model.discover()
        model.selectAll()
        model.kinds = [.bookmarks]

        await model.run()

        let saved = await bookmarks.merged
        #expect(saved.isEmpty == false)
        #expect(saved.allSatisfy { $0.spaceID == BrowserSpace.researchID })
    }
}
