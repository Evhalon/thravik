import AppKit

@MainActor
final class FloatingVideoReturnButton: NSButton {
    static let side: CGFloat = 32

    init(action: @escaping @MainActor () -> Void) {
        super.init(frame: .zero)
        let label = "Return video to tab"
        image = NSImage(systemSymbolName: "pip.exit", accessibilityDescription: label)
        symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        contentTintColor = .white
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = Self.side / 2
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.45).cgColor
        toolTip = label
        setAccessibilityLabel(label)
        alphaValue = 0
        target = self
        self.action = #selector(fire)
        handler = action
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private var handler: (@MainActor () -> Void)?

    @objc private func fire() { handler?() }
}
