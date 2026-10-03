import RedentDesign
import RedentKit
import SwiftUI

/// Compact background-tab player at the foot of the sidebar.
struct SidebarNowPlayingCard: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if let item = model.sidebarNowPlaying, let tab = model.nowPlayingTab {
            HStack(spacing: Metric.tightGutter) {
                focusButton(item, tab: tab)
                playbackButton(isPlaying: item.isPlaying)
                muteButton(tab)
                dismissButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background { chrome }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(item.artist.map { "\($0), \(item.title)" } ?? item.title)
        }
    }

    private func focusButton(_ item: NowPlaying, tab: any BrowserTab) -> some View {
        Button(action: model.focusNowPlayingTab) {
            HStack(spacing: Metric.tightGutter) {
                SidebarNowPlayingArtwork(item: item, tab: tab)
                SidebarNowPlayingLabels(item: item)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Show this tab")
    }

    private func playbackButton(isPlaying: Bool) -> some View {
        control(
            symbol: isPlaying ? "pause.fill" : "play.fill",
            label: isPlaying ? "Pause" : "Play",
            action: model.toggleNowPlayingPlayback
        )
    }

    private func muteButton(_ tab: any BrowserTab) -> some View {
        control(
            symbol: VolumeSymbol.name(muted: tab.isMuted, level: tab.volume),
            label: tab.isMuted ? "Unmute" : "Mute",
            tint: tab.isMuted ? Palette.chromeSecondaryText : Palette.accent,
            action: model.toggleNowPlayingMute
        )
    }

    private var dismissButton: some View {
        control(
            symbol: "xmark",
            label: "Stop and hide",
            tint: Palette.chromeSecondaryText,
            action: model.dismissNowPlaying
        )
    }

    private func control(
        symbol: String,
        label: String,
        tint: Color = Palette.chromeText,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(Palette.chromeFill)
            .overlay {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
            }
    }
}
