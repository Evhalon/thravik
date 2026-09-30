import RedentDesign
import SwiftUI

/// The Settings page's own index, down its leading edge.
struct SettingsPaneList: View {
    @Binding var selection: SettingsPane

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .padding(.horizontal, Metric.tightGutter + 4)
                .padding(.bottom, 14)
            ForEach(SettingsPane.allCases) { pane in
                row(pane)
            }
            Spacer()
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 14)
        .frame(width: 200, alignment: .leading)
    }

    private func row(_ pane: SettingsPane) -> some View {
        Button { selection = pane } label: {
            Label(pane.rawValue, systemImage: pane.symbol)
                .font(.system(size: 13, weight: selection == pane ? .semibold : .regular))
                .foregroundStyle(selection == pane ? Palette.chromeText : Palette.chromeSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Metric.tightGutter + 4)
                .frame(height: 30)
                .background {
                    if selection == pane {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Palette.chromeFill)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
