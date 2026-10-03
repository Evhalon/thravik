import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Browser import receipt")
struct BrowserImportReceiptTests {
    @Test("Completion reports this run's selected profiles and partial counts")
    func publishesLatestPartialImport() async {
        let browsers = [
            ImportableBrowser.fake("Source/Personal", name: "Source — Personal"),
            ImportableBrowser.fake("Source/Work", name: "Source — Work")
        ]
        let importer = FakeBrowserImporter(profiles: [
            browsers[0].id: .init(history: 2, passwords: 1),
            browsers[1].id: .init(history: 3, passwordError: .decryptionKeyUnavailable)
        ], browsers: browsers)
        let model = BrowserImportModel(
            importer: importer,
            history: RecordingHistoryStore(),
            bookmarks: RecordingBookmarkStore(),
            credentials: FakeCredentialStore(),
            destination: ImportDestination(spaces: BrowserSpace.starterSpaces, spaceID: BrowserSpace.travelID)
        )
        model.createSpace = { _ in UUID() }
        model.kinds = [.history, .passwords]
        model.discover()
        var receipt: BrowserImportReceipt?
        model.onComplete = { receipt = $0 }

        await model.run()

        #expect(receipt?.summary.history == 5)
        #expect(receipt?.summary.passwords == 1)
        #expect(receipt?.profileNames == browsers.map(\.name))
        #expect(receipt?.problem?.contains("Always Allow") == true)
    }

    @Test("A successful empty import still reports completion")
    func publishesEmptyImport() async {
        let browser = ImportableBrowser.fake("Source/Default")
        let model = BrowserImportModel(
            importer: FakeBrowserImporter(profiles: [:], browsers: [browser]),
            history: RecordingHistoryStore(),
            bookmarks: RecordingBookmarkStore(),
            credentials: FakeCredentialStore(),
            destination: ImportDestination(spaces: BrowserSpace.starterSpaces, spaceID: BrowserSpace.travelID)
        )
        model.createSpace = { _ in UUID() }
        model.kinds = [.history]
        model.discover()
        var receipt: BrowserImportReceipt?
        model.onComplete = { receipt = $0 }

        await model.run()

        #expect(receipt?.summary.isEmpty == true)
        #expect(receipt?.problem == nil)
    }
}
