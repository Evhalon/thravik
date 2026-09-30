import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Form history suggestions")
struct FormHistoryCoordinatorTests {
    private let emailField = FormFieldDescriptor(type: "email", name: "email")
    private let anchor = CGRect(x: 10, y: 20, width: 240, height: 24)
    private let saved = [
        FormEntry(key: FormFieldKey(rawValue: "ac:email"), value: "anna@example.com"),
        FormEntry(key: FormFieldKey(rawValue: "ac:email"), value: "bob@example.com")
    ]

    private func focus(_ typed: String, field: FormFieldDescriptor? = nil) -> FormFieldFocus {
        FormFieldFocus(field: field ?? emailField, typed: typed, anchor: anchor)
    }

    @Test("Typing in a field lists matching values under it and tells the page how many")
    func showsMatches() async {
        let coordinator = FormHistoryCoordinator(store: FakeFormHistoryStore(saved))
        let tab = FormRecordingTab()

        await coordinator.fieldActive(focus("an"), in: tab)

        #expect(coordinator.menu?.items == ["anna@example.com"])
        #expect(coordinator.menu?.anchor == anchor)
        #expect(tab.announcedCounts == [1])
    }

    @Test("No match, a secret field, or the setting off: no menu", arguments: [0, 1, 2])
    func staysClosed(caseIndex: Int) async {
        let coordinator = FormHistoryCoordinator(store: FakeFormHistoryStore(saved), isEnabled: caseIndex != 2)
        let tab = FormRecordingTab()
        let field = caseIndex == 1 ? FormFieldDescriptor(type: "password", name: "email") : emailField

        await coordinator.fieldActive(focus(caseIndex == 0 ? "zed" : "", field: field), in: tab)

        #expect(coordinator.menu == nil)
        #expect(tab.announcedCounts == [0])
    }

    @Test("Choosing a row fills that value and closes the menu; the form is not sent")
    func choosing() async {
        let coordinator = FormHistoryCoordinator(store: FakeFormHistoryStore(saved))
        let tab = FormRecordingTab()
        await coordinator.fieldActive(focus(""), in: tab)
        coordinator.highlight(1)
        #expect(coordinator.menu?.highlighted == 1)

        coordinator.choose(at: 1, in: tab)

        #expect(tab.filledValues.count == 1)
        #expect(coordinator.menu == nil)
    }

    @Test("A sent form is remembered without its secrets")
    func remembers() async {
        let store = FakeFormHistoryStore()
        let coordinator = FormHistoryCoordinator(store: store)
        let values = [
            FormFieldValue(field: emailField, value: "new@example.com"),
            FormFieldValue(field: FormFieldDescriptor(type: "password", name: "p"), value: "hunter2"),
            FormFieldValue(field: FormFieldDescriptor(name: "note"), value: "4111 1111 1111 1111")
        ]

        await coordinator.submitted(values, remembers: true, in: FormRecordingTab())

        #expect(await store.rows.map(\.value) == ["new@example.com"])
    }

    @Test("A private or temporary tab's form leaves nothing behind")
    func privateForgets() async {
        let store = FakeFormHistoryStore()
        let coordinator = FormHistoryCoordinator(store: store)

        await coordinator.submitted([FormFieldValue(field: emailField, value: "a@b.co")], remembers: false, in: FormRecordingTab())

        #expect(await store.rows.isEmpty)
    }

    @Test("Removing a row forgets it and keeps the rest on screen")
    func forgetting() async {
        let store = FakeFormHistoryStore(saved)
        let coordinator = FormHistoryCoordinator(store: store)
        let tab = FormRecordingTab()
        await coordinator.fieldActive(focus(""), in: tab)

        await coordinator.forget("anna@example.com", in: tab)

        #expect(coordinator.menu?.items == ["bob@example.com"])
        #expect(tab.announcedCounts.last == 1)
        #expect(await store.rows.map(\.value) == ["bob@example.com"])
    }
}
