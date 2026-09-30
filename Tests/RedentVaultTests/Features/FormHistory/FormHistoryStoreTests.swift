import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Form history storage")
struct FormHistoryStoreTests {
    private let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "redent-forms-\(UUID().uuidString).json")
    private let email = FormFieldKey(rawValue: "ac:email")

    @Test("Values survive a new store over the same file, readable by the owner only")
    func roundTrip() async throws {
        await JSONFormHistoryStore(fileURL: fileURL).record([FormEntry(key: email, value: "a@example.com")], at: Date())

        let reopened = JSONFormHistoryStore(fileURL: fileURL)
        #expect(await reopened.suggestions(for: email, matching: "a", limit: 5) == ["a@example.com"])
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }

    @Test("Forgetting one value, then everything, leaves nothing on disk")
    func forgetting() async {
        let store = JSONFormHistoryStore(fileURL: fileURL)
        await store.record([FormEntry(key: email, value: "a@example.com"), FormEntry(key: email, value: "b@example.com")], at: Date())
        await store.remove("a@example.com", for: email)
        #expect(await store.suggestions(for: email, matching: "", limit: 5) == ["b@example.com"])

        await store.removeAll()
        #expect(await store.suggestions(for: email, matching: "", limit: 5).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("A corrupt file is an empty history, not a failure")
    func corruptFile() async throws {
        try Data("not json".utf8).write(to: fileURL)
        #expect(await JSONFormHistoryStore(fileURL: fileURL).suggestions(for: email, matching: "", limit: 5).isEmpty)
    }
}
