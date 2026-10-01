import SwiftUI

/// A colored glass disc with an icon. Arc's Space mark: solid when selected,
/// a tinted chip when not.
public struct ChromeOrb: View {
    private let systemImage: String
    private let tint: Color
    private let isSelected: Bool
    private let size: CGFloat
    @Environment(\.self) private var environment
    @Environment(\.colorScheme) private var scheme

    public init(systemImage: String, tint: Color, isSelected: Bool = false, size: CGFloat = 26) {
        self.systemImage = systemImage
        self.tint = tint
        self.isSelected = isSelected
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(glyph)
            .frame(width: size, height: size)
            .background { disc }
            .shadow(color: tint.opacity(isSelected ? 0.55 : 0), radius: 8, y: 2)
            .animation(.spring(duration: 0.28), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var disc: some View {
        Circle()
            .fill(tint.opacity(isSelected ? 1 : (scheme == .dark ? 0.36 : 0.28)))
            .overlay { sheen }
            .overlay {
                Circle().strokeBorder(rim, lineWidth: Metric.hairWidth)
            }
    }

    private var sheen: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(isSelected ? 0.26 : 0.14), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
    }

    private var rim: Color {
        isSelected ? .white.opacity(0.38) : tint.opacity(scheme == .dark ? 0.55 : 0.45)
    }

    /// Light hues (yellow, mint, lime) wash out under a white glyph, so the
    /// glyph flips to a deep shade of the hue once white drops below 3:1.
    private var glyph: Color {
        guard isSelected else {
            return scheme == .dark ? tint.mix(with: .white, by: 0.25) : tint.mix(with: .black, by: 0.42)
        }
        return luminance < 0.30 ? .white : tint.mix(with: .black, by: 0.78)
    }

    private var luminance: Float {
        let resolved = tint.resolve(in: environment)
        return 0.2126 * resolved.linearRed + 0.7152 * resolved.linearGreen + 0.0722 * resolved.linearBlue
    }
}
