import Foundation

/// A value the user sent in one field of a submitted form.
public struct FormEntry: Sendable, Equatable {
    public let key: FormFieldKey
    public let value: String

    public init(key: FormFieldKey, value: String) {
        self.key = key
        self.value = value
    }

    /// Nil when the value is not worth remembering or must not be: empty,
    /// overlong, multi-line, or shaped like a payment card number.
    public init?(field: FormFieldDescriptor, value raw: String) {
        guard let key = FormFieldKey(field) else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= Self.maximumLength,
              !value.contains(where: \.isNewline), !Self.looksLikeCardNumber(value)
        else { return nil }
        self.init(key: key, value: value)
    }

    public static let maximumLength = 200

    /// Luhn over 13–19 digits: a card number typed into a field the page did
    /// not label as one still never reaches the file.
    static func looksLikeCardNumber(_ value: String) -> Bool {
        let stripped = value.filter { $0 != " " && $0 != "-" }
        guard (13...19).contains(stripped.count) else { return false }
        let digits = stripped.compactMap(\.wholeNumberValue)
        guard digits.count == stripped.count else { return false }
        let sum = digits.reversed().enumerated().reduce(0) { total, pair in
            guard pair.offset.isMultiple(of: 2) == false else { return total + pair.element }
            let doubled = pair.element * 2
            return total + (doubled > 9 ? doubled - 9 : doubled)
        }
        return sum.isMultiple(of: 10)
    }
}

/// Remembered form values. Holds what the user typed into ordinary fields —
/// never passwords, card or one-time codes; those are filtered before here.
public protocol FormHistoryStoring: Sendable {
    func record(_ entries: [FormEntry], at date: Date) async
    func suggestions(for key: FormFieldKey, matching prefix: String, limit: Int) async -> [String]
    func remove(_ value: String, for key: FormFieldKey) async
    func removeAll() async
}
