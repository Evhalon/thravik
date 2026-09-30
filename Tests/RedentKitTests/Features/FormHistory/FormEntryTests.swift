import RedentKit
import Testing

@Suite("Form entries")
struct FormEntryTests {
    private let city = FormFieldDescriptor(name: "city")

    @Test("A value is trimmed before it is remembered")
    func trims() {
        #expect(FormEntry(field: city, value: "  Milano \t")?.value == "Milano")
    }

    @Test("Empty, multi-line and overlong values are dropped", arguments: [
        "", "   ", "line one\nline two", String(repeating: "a", count: FormEntry.maximumLength + 1)
    ])
    func refused(value: String) {
        #expect(FormEntry(field: city, value: value) == nil)
    }

    @Test("A card number is dropped even from a field that does not say so", arguments: [
        "4111 1111 1111 1111", "4111-1111-1111-1111", "5555555555554444", "378282246310005"
    ])
    func cardNumbersRefused(value: String) {
        #expect(FormEntry(field: city, value: value) == nil)
    }

    @Test("Numbers that are not cards stay", arguments: ["+39 333 123 4567", "20121", "4111111111111112"])
    func otherNumbersKept(value: String) {
        #expect(FormEntry(field: city, value: value) != nil)
    }

    @Test("A password field's value is dropped whatever it holds")
    func passwordRefused() {
        #expect(FormEntry(field: FormFieldDescriptor(type: "password", name: "p"), value: "hunter2") == nil)
    }
}
