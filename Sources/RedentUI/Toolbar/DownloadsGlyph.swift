import RedentDesign
import SwiftUI

/// What the downloads button draws: a ring that fills while files arrive,
/// a checkmark that pops in when one lands, and the plain arrow otherwise.
struct DownloadsGlyph: View {
    let activeFraction: Double?
    let isActive: Bool
    let showsCompletion: Bool
    let hasUnseenCompletion: Bool
    /// Changes once per new download; each change drops the arrow in.
    let arrivals: Int

    var body: some View {
        ZStack {
            if isActive && !showsCompletion {
                ProgressRing(fraction: activeFraction, lineWidth: 1.6)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            Image(systemName: symbol)
                .font(.system(size: isActive && !showsCompletion ? 8 : 12.5, weight: .bold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace.downUp))
                .symbolEffect(.bounce.down, value: arrivals)
        }
        .frame(width: 17, height: 17)
        .overlay(alignment: .topTrailing) { badge }
        .animation(.spring(duration: 0.35, bounce: 0.3), value: isActive)
        .animation(.spring(duration: 0.35, bounce: 0.4), value: showsCompletion)
    }

    private var symbol: String {
        if showsCompletion { return "checkmark.circle.fill" }
        return isActive ? "arrow.down" : "arrow.down.circle"
    }

    private var tint: Color {
        isActive || showsCompletion || hasUnseenCompletion ? Palette.accent : Palette.chromeSecondaryText
    }

    @ViewBuilder
    private var badge: some View {
        if hasUnseenCompletion && !isActive && !showsCompletion {
            Circle()
                .fill(Palette.accent)
                .frame(width: 5, height: 5)
                .offset(x: 2, y: -1)
                .transition(.scale.combined(with: .opacity))
        }
    }
}
