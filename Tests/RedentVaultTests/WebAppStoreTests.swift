import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Web app storage")
struct WebAppStoreTests {
    private let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "redent-apps-\(UUID().uuidString).json")

    @Test("Apps survive a new store over the same file; a deleted one does not")
    func roundTrip() async throws {
        let space = UUID()
        let github = WebApp(name: "GitHub", url: try #require(URL(string: "https://github.com/")), spaceID: space)
        let linear = WebApp(name: "Linear", url: try #require(URL(string: "https://linear.app/")))
        let store = JSONWebAppStore(fileURL: fileURL)
        await store.save(github)
        await store.save(linear)
        await store.delete(linear.id)

        let reopened = await JSONWebAppStore(fileURL: fileURL).all()

        #expect(reopened == [github])
        #expect(reopened.first?.spaceID == space)
    }

    @Test("Saving an app again renames it instead of listing it twice")
    func saveReplaces() async throws {
        var app = WebApp(name: "Mail", url: try #require(URL(string: "https://mail.example/")))
        let store = JSONWebAppStore(fileURL: fileURL)
        await store.save(app)
        app.name = "Work Mail"
        await store.save(app)

        #expect(await store.all().map(\.name) == ["Work Mail"])
    }

    @Test("A missing file is no apps, not a failure")
    func missingFile() async {
        #expect(await JSONWebAppStore(fileURL: fileURL).all().isEmpty)
    }
}
