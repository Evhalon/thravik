import SwiftUI

/// A quiet capsule label for chrome rows — "Space default", counts, kinds.
public struct ChromeBadge: View {
    private let title: String
    private let tint: Color

    public init(_ title: String, tint: Color = Palette.chromeSecondaryText) {
        self.title = title
        self.tint = tint
    }

    public var body: some View {
        Text(title)
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(Capsule(style: .continuous).fill(tint.opacity(0.16)))
    }
}
