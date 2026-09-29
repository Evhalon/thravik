import RedentDesign
import SwiftUI

public struct FloatingVideoControls: View {
    private let model: FloatingVideoModel

    public init(model: FloatingVideoModel) { self.model = model }

    public var body: some View {
        GlassEffectContainer(spacing: 6) {
            VStack(spacing: 6) {
                FloatingVideoTimeline(model: model)
                transport
            }
            .padding(6)
        }
        .tint(.white)
        .environment(\.colorScheme, .dark)
    }

    private var transport: some View {
        HStack(spacing: 8) {
            control("xmark", label: "Close floating video", action: model.close)
            control(model.isPlaying ? "pause.fill" : "play.fill",
                    label: model.isPlaying ? "Pause" : "Play", action: model.togglePlayback)
            control("pip.exit", label: "Return video to tab", action: model.returnToTab)
            Spacer(minLength: 0)
            FloatingVideoVolumeControl(model: model)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func control(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 28)
                .contentShape(.circle)
        }
        .buttonStyle(PressScaleStyle())
        .help(label)
        .accessibilityLabel(label)
    }
}
