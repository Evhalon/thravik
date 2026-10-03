import RedentDesign
import RedentKit
import SwiftUI

struct ShortcutBindingRow: View {
    let row: ShortcutRowModel
    let onRecord: () -> Void
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Text(row.id.title)
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeText)
                .frame(maxWidth: .infinity, alignment: .leading)
            if row.isCustomized {
                Button("Default", action: onRestore)
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.accent)
            }
            Button(action: onRecord) {
                Text(row.isRecording ? "Type shortcut…" : (row.chord?.displayString ?? "None"))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(row.isRecording ? Palette.accent : Palette.chromeText)
                    .padding(.horizontal, 10)
                    .frame(minWidth: 88)
                    .frame(height: 26)
                    .background {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Palette.chromeFill)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}
