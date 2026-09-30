import RedentDesign
import SwiftUI

/// Shares the update action and progress state with Settings in every window.
struct SpaceUpdateButton: View {
    let updates: UpdateModel

    @ViewBuilder
    var body: some View {
        switch updates.phase {
        case .available(let release):
            Button {
                Task { await updates.installAndRestart(release) }
            } label: {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Palette.accent.opacity(0.18)))
                    .contentShape(.circle)
            }
            .buttonStyle(PressScaleStyle())
            .help("Download update \(release.version.description) and restart")
            .accessibilityLabel("Download update \(release.version.description) and restart")
        case .installing, .restarting:
            ProgressView()
                .controlSize(.mini)
                .frame(width: 22, height: 22)
                .accessibilityLabel("Installing update")
        default:
            EmptyView()
        }
    }
}
