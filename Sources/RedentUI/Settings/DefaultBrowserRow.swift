import RedentDesign
import SwiftUI

/// The Settings row for taking over web links — the way back for anyone who
/// dismissed the offer at launch.
struct DefaultBrowserRow: View {
    @Bindable var model: DefaultBrowserModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.isDefault
                     ? "\(AppIdentity.displayName) is your default browser"
                     : "Open web links in \(AppIdentity.displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                Text("Links from other apps open here. macOS asks you to confirm.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer(minLength: Metric.gutter)
            if model.isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.accent)
            } else {
                Button("Make Default") { Task { await model.makeDefault() } }
                    .disabled(model.isWorking)
            }
        }
        .task { await model.refreshStatus() }
    }
}
