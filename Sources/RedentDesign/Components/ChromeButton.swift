import SwiftUI

/// An icon button for the chrome.
///
/// Deliberately unbezelled: on a glass slab, macOS's default button chrome
/// fights the surface. The affordance comes from a hover fill and a subtle
/// press scale instead.
public struct ChromeButton: View {
    private let systemImage: String
    private let help: String
    private let isEnabled: Bool
    private let action: () -> Void

    @State private var isHovering = false

    public init(
        systemImage: String,
        help: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.help = help
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isEnabled ? Palette.chromeText : Palette.chromeSecondaryText)
                .frame(width: Metric.controlHeight, height: Metric.controlHeight)
                .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .chromeHoverEffect(isActive: isHovering && isEnabled, radius: Metric.smallRadius)
        .onHover { isHovering = $0 }
        .help(help)
    }
}

/// The press feedback shared by every chrome control.
public struct PressScaleStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(duration: 0.22), value: configuration.isPressed)
    }
}
