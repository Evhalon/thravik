import RedentDesign
import RedentKit
import SwiftUI

/// The toolbar speaker: opens a slider for the tab in front, so one loud page
/// can be turned down without touching the Mac's own volume.
struct TabVolumeButton: View {
    @Bindable var model: BrowserModel
    @State private var isShowingSlider = false

    var body: some View {
        Button { isShowingSlider.toggle() } label: {
            Image(systemName: TabVolumeSymbol.name(muted: model.isSelectedTabMuted, level: model.selectedTabVolume))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 18)
        }
        .buttonStyle(PressScaleStyle())
        .help("Tab volume")
        .accessibilityLabel("Tab volume")
        .popover(isPresented: $isShowingSlider, arrowEdge: .bottom) {
            TabVolumePopover(model: model)
        }
    }

    private var tint: Color {
        model.isSelectedTabPlayingAudio && !model.isSelectedTabMuted ? Palette.accent : Palette.chromeSecondaryText
    }
}
