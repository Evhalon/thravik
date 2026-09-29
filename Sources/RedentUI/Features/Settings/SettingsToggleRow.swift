import RedentDesign
import SwiftUI

/// A settings switch with optional caption. Switch sits on the trailing edge
/// so the title can wrap without shoving the control.
struct SettingsToggleRow: View {
    private let title: String
    private let caption: String?
    @Binding private var isOn: Bool

    init(_ title: String, caption: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.caption = caption
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .top, spacing: Metric.gutter) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                if let caption {
                    Text(caption)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.chromeSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Metric.gutter)
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.vertical, 2)
    }
}
