import Foundation
import RedentKit
import Testing

@Suite("Form history ranking")
struct FormHistoryIndexTests {
    private let email = FormFieldKey(rawValue: "ac:email")
    private let city = FormFieldKey(rawValue: "name:city")
    private let start = Date(timeIntervalSince1970: 1_000)

    private func entry(_ value: String, _ key: FormFieldKey? = nil) -> FormEntry {
        FormEntry(key: key ?? email, value: value)
    }

    @Test("The most used value comes first, the newest among equals")
    func ranking() {
        var index = FormHistoryIndex()
        index.record([entry("old@example.com")], at: start)
        index.record([entry("new@example.com")], at: start + 10)
        index.record([entry("work@example.com")], at: start + 1)
        index.record([entry("work@example.com")], at: start + 2)

        #expect(index.suggestions(for: email, matching: "", limit: 5)
            == ["work@example.com", "new@example.com", "old@example.com"])
    }

    @Test("Matching is a case-insensitive prefix, and what is fully typed is not offered")
    func prefix() {
        var index = FormHistoryIndex()
        index.record([entry("Anna@example.com"), entry("bob@example.com"), entry("an")], at: start)

        #expect(index.suggestions(for: email, matching: "AN", limit: 5) == ["Anna@example.com"])
    }

    @Test("A value differing only in case is one entry, spelled the latest way")
    func caseFolds() {
        var index = FormHistoryIndex()
        index.record([entry("milano", city)], at: start)
        index.record([entry("Milano", city)], at: start + 1)

        #expect(index.rows.count == 1)
        #expect(index.rows.first?.value == "Milano")
        #expect(index.rows.first?.useCount == 2)
    }

    @Test("Keys never mix, and a removed value is gone")
    func keysAndRemoval() {
        var index = FormHistoryIndex()
        index.record([entry("Roma", city), entry("roma@example.com")], at: start)
        index.remove("ROMA", for: city)

        #expect(index.suggestions(for: city, matching: "", limit: 5).isEmpty)
        #expect(index.suggestions(for: email, matching: "r", limit: 5) == ["roma@example.com"])
    }

    @Test("Past capacity, the least recently used values go first")
    func prunes() {
        var index = FormHistoryIndex()
        let entries = (0...FormHistoryIndex.capacity).map { entry("user\($0)@example.com") }
        for (offset, item) in entries.enumerated() { index.record([item], at: start + Double(offset)) }

        #expect(index.rows.count == FormHistoryIndex.capacity)
        #expect(!index.rows.contains { $0.value == "user0@example.com" })
    }
}
