import RedentDesign
import SwiftUI

/// Shown on a profile with no history and no bookmarks yet.
///
/// A brand-new browser is the one moment when importing is obviously the right
/// next step, so the page offers it rather than showing an empty grid.
struct NewTabEmptyState: View {
    let onImport: () -> Void
    let onCreateFolder: () -> Void

    var body: some View {
        VStack(spacing: Metric.gutter + 2) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.accent)

            VStack(spacing: 4) {
                Text("Bring your browsing with you")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                Text("Import history, bookmarks and saved passwords from Comet,\nChrome, Brave, Arc or Edge.")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.chromeSecondaryText)
            }

            HStack(spacing: Metric.tightGutter) {
                Button("Import…", action: onImport)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                Button("New Favorites Folder", action: onCreateFolder)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 34)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        .frame(maxWidth: 400)
    }
}
