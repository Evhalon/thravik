import SwiftUI

/// A colored glass disc with an icon. Arc's Space mark: solid when selected,
/// a tinted chip when not.
public struct ChromeOrb: View {
    private let systemImage: String
    private let tint: Color
    private let isSelected: Bool
    private let size: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(systemImage: String, tint: Color, isSelected: Bool = false, size: CGFloat = 26) {
        self.systemImage = systemImage
        self.tint = tint
        self.isSelected = isSelected
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: size, height: size)
            .background { disc }
            .shadow(color: tint.opacity(isSelected ? 0.48 : 0), radius: 8, y: 2)
            .animation(.spring(duration: 0.28), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var disc: some View {
        Circle()
            .fill(tint.opacity(isSelected ? 0.95 : (scheme == .dark ? 0.24 : 0.20)))
            .overlay { sheen }
            .overlay {
                Circle().strokeBorder(.white.opacity(isSelected ? 0.38 : 0.16), lineWidth: Metric.hairWidth)
            }
    }

    private var sheen: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(isSelected ? 0.32 : 0.18), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
    }
}
