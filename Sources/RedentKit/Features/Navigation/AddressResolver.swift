import Foundation

/// Turns whatever the user typed in the address bar into something to load.
public enum AddressResolver {
    private static let knownSchemes: Set<String> = [
        "http", "https", "file", "about", "data", "blob", "redent"
    ]

    public static func resolve(_ input: String, using engine: SearchEngine) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let url = explicitURL(from: text) { return url }
        if looksLikeHost(text), let url = URL(string: "https://\(text)") { return url }
        return engine.searchURL(for: text)
    }

    private static func explicitURL(from text: String) -> URL? {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              knownSchemes.contains(scheme)
        else { return nil }
        // `URL` happily parses "foo:bar" — require a real authority for web schemes.
        if scheme == "http" || scheme == "https" { return url.host() == nil ? nil : url }
        return url
    }

    /// `example.com`, `sub.example.co.uk:8080/path`, `localhost:3000` — but not
    /// `how to cook rice` or `1 + 2`.
    private static func looksLikeHost(_ text: String) -> Bool {
        guard !text.contains(" ") else { return false }
        let hostPart = text.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        let bare = hostPart.split(separator: ":").first.map(String.init) ?? String(hostPart)
        if bare == "localhost" { return true }
        guard bare.contains("."), !bare.hasPrefix("."), !bare.hasSuffix(".") else { return false }
        guard let tld = bare.split(separator: ".").last, tld.count >= 2 else { return false }
        return tld.allSatisfy(\.isLetter) && bare.allSatisfy(isHostCharacter)
    }

    private static func isHostCharacter(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "." || c == "-" || c == "_"
    }
}
