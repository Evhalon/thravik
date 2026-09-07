import Foundation

enum HistorySQL {
    static func escapedLike(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    static func domain(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !value.isEmpty, !value.contains("/") else { return nil }
        return value
    }

}
