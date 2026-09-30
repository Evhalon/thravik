import Foundation

/// The attributes a page gives a text field, as read by the page script.
/// Untrusted input: every value here was written by the site.
public struct FormFieldDescriptor: Sendable, Equatable {
    public var autocomplete: String
    public var type: String
    public var name: String
    public var identifier: String

    public init(autocomplete: String = "", type: String = "text", name: String = "", identifier: String = "") {
        self.autocomplete = autocomplete
        self.type = type
        self.name = name
        self.identifier = identifier
    }
}

/// What a remembered entry is filed under. Two sites asking for an email share
/// one key, which is what makes an address typed once offer itself elsewhere.
public struct FormFieldKey: Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }

    /// Nil for any field that must never be remembered: passwords, card and
    /// one-time codes, and fields whose only name is one a framework generated.
    public init?(_ field: FormFieldDescriptor) {
        guard let key = Self.derive(field) else { return nil }
        rawValue = key
    }

    private static let textTypes: Set<String> = ["", "text", "email", "tel", "search", "url", "number"]
    private static let secretTokens: Set<String> = [
        "off", "current-password", "new-password", "one-time-code", "webauthn", "transaction-amount"
    ]
    /// Section and contact-kind prefixes say which address, not what the field is.
    private static let qualifierTokens: Set<String> = ["shipping", "billing", "home", "work", "mobile", "fax", "pager"]
    private static let sensitiveFragments = [
        "pass", "pwd", "otp", "2fa", "mfa", "cvv", "cvc", "csc", "card", "carta", "iban",
        "ssn", "socialsecurity", "fiscale", "taxid", "captcha", "secret", "token"
    ]
    private static let sensitiveWords: Set<String> = ["pin", "cid", "code"]

    private static func derive(_ field: FormFieldDescriptor) -> String? {
        let type = field.type.lowercased()
        guard textTypes.contains(type) else { return nil }
        let tokens = field.autocomplete.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
            .filter { !$0.hasPrefix("section-") && !qualifierTokens.contains($0) }
        if let token = tokens.last {
            if secretTokens.contains(token) || token.hasPrefix("cc-") { return nil }
            if token != "on" { return "ac:\(token)" }
        }
        let label = normalized(field.name.isEmpty ? field.identifier : field.name)
        if let label, isSensitive(label) { return nil }
        if type == "email" || type == "tel" { return "ac:\(type)" }
        return label.map { "name:\($0)" }
    }

    private static func isSensitive(_ label: String) -> Bool {
        let words = label.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let joined = words.joined()
        return sensitiveFragments.contains { joined.contains($0) } || words.contains { sensitiveWords.contains($0) }
    }

    /// React's `:r3:` ids and long numeric suffixes change every render, so a
    /// key built from them would never be seen twice.
    private static func normalized(_ raw: String) -> String? {
        let label = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !label.isEmpty, label.count <= 64, !label.contains(":") else { return nil }
        let digits = label.filter(\.isNumber).count
        guard digits < 6, digits * 2 < label.count else { return nil }
        return label
    }
}
