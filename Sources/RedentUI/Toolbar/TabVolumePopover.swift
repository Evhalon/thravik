import RedentDesign
import SwiftUI

/// The popover's content: mute beside a slider, and the level in words.
struct TabVolumePopover: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: 10) {
            Button(action: model.toggleMute) {
                Image(systemName: TabVolumeSymbol.name(muted: model.isSelectedTabMuted, level: model.selectedTabVolume))
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .help(model.isSelectedTabMuted ? "Unmute tab" : "Mute tab")
            Slider(value: level, in: 0...1)
                .frame(width: 160)
                .accessibilityLabel("Tab volume")
                .accessibilityValue("\(percent) percent")
            Text("\(percent)%")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(12)
    }

    private var percent: Int { Int((model.selectedTabVolume * 100).rounded()) }

    /// Dragging the slider off zero is how people unmute; it should work that way.
    private var level: Binding<Double> {
        Binding(
            get: { model.isSelectedTabMuted ? 0 : model.selectedTabVolume },
            set: { value in
                if model.isSelectedTabMuted, value > 0 { model.toggleMute() }
                model.setSelectedTabVolume(value)
            }
        )
    }
}
