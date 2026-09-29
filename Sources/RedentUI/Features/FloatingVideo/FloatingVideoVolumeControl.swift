import RedentDesign
import SwiftUI

struct FloatingVideoVolumeControl: View {
    let model: FloatingVideoModel

    var body: some View {
        HStack(spacing: 6) {
            Button(action: model.toggleMute) {
                Image(systemName: VolumeSymbol.name(muted: model.playback.isMuted, level: model.playback.volume))
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 20, height: 28)
            }
            .buttonStyle(PressScaleStyle())
            .help(model.playback.isMuted ? "Unmute video" : "Mute video")
            .accessibilityLabel(model.playback.isMuted ? "Unmute video" : "Mute video")
            Slider(value: Binding(get: {
                model.playback.isMuted ? 0 : model.playback.volume
            }, set: { model.setVolume($0) }), in: 0...1)
                .controlSize(.mini)
                .frame(minWidth: 32, maxWidth: 80)
                .accessibilityLabel("Video volume")
        }
    }
}
