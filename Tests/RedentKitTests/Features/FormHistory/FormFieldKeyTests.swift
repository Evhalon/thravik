import RedentKit
import Testing

@Suite("Form field keys")
struct FormFieldKeyTests {
    private func key(_ field: FormFieldDescriptor) -> String? { FormFieldKey(field)?.rawValue }

    @Test("An email field is one key on every site, however it is named")
    func emailSharesKey() {
        #expect(key(FormFieldDescriptor(type: "email", name: "contact")) == "ac:email")
        #expect(key(FormFieldDescriptor(autocomplete: "email", type: "text")) == "ac:email")
        #expect(key(FormFieldDescriptor(autocomplete: "section-a shipping email")) == "ac:email")
    }

    @Test("A plain text field is filed under its name, lowercased")
    func namedField() {
        #expect(key(FormFieldDescriptor(name: " City ")) == "name:city")
        #expect(key(FormFieldDescriptor(identifier: "Surname")) == "name:surname")
        #expect(key(FormFieldDescriptor(autocomplete: "on", name: "city")) == "name:city")
    }

    @Test("Secrets are never keyed", arguments: [
        FormFieldDescriptor(type: "password", name: "login"),
        FormFieldDescriptor(type: "hidden", name: "csrf"),
        FormFieldDescriptor(autocomplete: "cc-number", name: "number"),
        FormFieldDescriptor(autocomplete: "one-time-code", name: "code"),
        FormFieldDescriptor(autocomplete: "off", name: "city"),
        FormFieldDescriptor(autocomplete: "new-password", name: "p"),
        FormFieldDescriptor(name: "user_password"),
        FormFieldDescriptor(name: "card-holder"),
        FormFieldDescriptor(name: "pin"),
        FormFieldDescriptor(name: "security_code"),
        FormFieldDescriptor(type: "tel", name: "otp")
    ])
    func secretsRefused(field: FormFieldDescriptor) {
        #expect(FormFieldKey(field) == nil)
    }

    @Test("Names a framework generated per render are not keys", arguments: [":r3:", "field_1234567", "a91823"])
    func generatedNamesRefused(name: String) {
        #expect(FormFieldKey(FormFieldDescriptor(identifier: name)) == nil)
    }

    @Test("A field with no name at all has nothing to file under")
    func anonymousField() {
        #expect(FormFieldKey(FormFieldDescriptor()) == nil)
    }
}
