import RedentKit
import SwiftUI

struct FloatingVideoTimeline: View {
    let model: FloatingVideoModel
    @State private var draftTime: Double?

    var body: some View {
        VStack(spacing: 2) {
            Slider(value: position, in: model.playback.seekRange, onEditingChanged: finishScrubbing)
                .controlSize(.mini)
                .disabled(!model.playback.canSeek)
                .accessibilityLabel("Video playback position")
            HStack {
                Text(FloatingVideoPlayback.timestamp(draftTime ?? model.playback.elapsed))
                Spacer()
                Text(model.playback.isLive ? "LIVE" : FloatingVideoPlayback.timestamp(model.playback.duration))
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
    }

    private var position: Binding<Double> {
        Binding(get: {
            model.playback.clampedTime(draftTime ?? model.playback.elapsed) ?? 0
        }, set: { draftTime = $0 })
    }

    private func finishScrubbing(_ editing: Bool) {
        guard !editing, let draftTime else { return }
        model.seek(draftTime)
        self.draftTime = nil
    }
}
