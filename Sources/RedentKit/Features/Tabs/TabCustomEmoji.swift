import Foundation

/// One grapheme that reads as emoji. Letters, digits, and runs of more than
/// one cluster are rejected so a tab icon stays a single pictograph.
public enum TabCustomEmoji: Sendable {
    /// The longest real sequences (kiss with two skin tones, tag flags) stay
    /// near ten scalars; anything far beyond is synced or pasted abuse.
    private static let maxScalars = 16
    private static let allowedMarks: Set<UInt32> = [0xFE0E, 0xFE0F, 0x20E3]

    public static func validated(_ raw: String?) -> String? {
        guard let raw, raw.utf8.count <= 256 else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 1, let character = trimmed.first, isEmoji(character) else {
            return nil
        }
        return String(character)
    }

    public static func isEmoji(_ character: Character) -> Bool {
        let scalars = Array(character.unicodeScalars)
        guard !scalars.isEmpty, scalars.count <= maxScalars, !hasStrayMarks(scalars),
              !isTextPresentation(scalars) else { return false }
        if scalars.contains(where: { $0.properties.isEmojiPresentation }) { return true }
        if isRegionalFlag(scalars) { return true }
        return hasEmojiBase(scalars) && hasEmojiSelector(scalars)
    }

    private static func isTextPresentation(_ scalars: [Unicode.Scalar]) -> Bool {
        scalars.contains { $0.value == 0xFE0E }
            && !scalars.contains { $0.value == 0xFE0F || $0.properties.isEmojiPresentation }
    }

    private static func hasStrayMarks(_ scalars: [Unicode.Scalar]) -> Bool {
        scalars.contains { scalar in
            switch scalar.properties.generalCategory {
            case .nonspacingMark, .spacingMark, .enclosingMark: !allowedMarks.contains(scalar.value)
            default: false
            }
        }
    }

    private static func isRegionalFlag(_ scalars: [Unicode.Scalar]) -> Bool {
        scalars.count == 2 && scalars.allSatisfy { (0x1F1E6...0x1F1FF).contains($0.value) }
    }

    private static func hasEmojiBase(_ scalars: [Unicode.Scalar]) -> Bool {
        scalars.contains { $0.properties.isEmoji }
    }

    private static func hasEmojiSelector(_ scalars: [Unicode.Scalar]) -> Bool {
        scalars.contains {
            $0.value == 0xFE0F || $0.value == 0x20E3 || $0.properties.isEmojiModifier
        }
    }
}
