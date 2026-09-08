import Foundation

/// A dotted release version compared field by field, so 0.1.10 correctly
/// outranks 0.1.9 — which sorting the strings would get backwards.
public struct AppVersion: Sendable, Equatable, Comparable, CustomStringConvertible {
    public let fields: [Int]

    /// Accepts `1.2.3` and GitHub's `v1.2.3`. A tag that is not a dotted run
    /// of non-negative integers is rejected: a version we cannot compare must
    /// never be treated as newer than what is installed.
    public init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.first == "v" || text.first == "V" { text.removeFirst() }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var parsed: [Int] = []
        for part in parts {
            guard part.allSatisfy(\.isNumber), let value = Int(part) else { return nil }
            parsed.append(value)
        }
        fields = parsed
    }

    public var description: String {
        fields.map(String.init).joined(separator: ".")
    }

    /// Written out rather than synthesized: synthesized equality compares the
    /// arrays, which would make 1.2 and 1.2.0 neither equal nor ordered, and a
    /// `Comparable` where none of `<`, `>`, `==` holds is a broken one.
    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let width = max(lhs.fields.count, rhs.fields.count)
        for index in 0..<width {
            let left = lhs.field(at: index)
            let right = rhs.field(at: index)
            if left != right { return left < right }
        }
        return false
    }

    /// Missing trailing fields are zero, so 1.2 and 1.2.0 are the same release.
    private func field(at index: Int) -> Int {
        index < fields.count ? fields[index] : 0
    }
}
