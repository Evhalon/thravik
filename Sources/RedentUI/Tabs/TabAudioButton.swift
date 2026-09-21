import RedentDesign
import RedentKit
import SwiftUI

/// The speaker beside a tab's title: says the tab is making sound, and silences
/// it in one click without having to find it first.
struct TabAudioButton: View {
    let tab: any BrowserTab

    var body: some View {
        Button { tab.setMuted(!tab.isMuted) } label: {
            Image(systemName: TabVolumeSymbol.name(muted: tab.isMuted, level: tab.volume))
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(tab.isMuted ? Palette.chromeSecondaryText : Palette.accent)
                .symbolEffect(.variableColor.iterative, isActive: tab.isPlayingAudio && !tab.isMuted)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tab.isMuted ? "Unmute this tab" : "Mute this tab")
        .accessibilityLabel(tab.isMuted ? "Unmute tab" : "Mute tab")
    }
}
