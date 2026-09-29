import RedentDesign
import SwiftUI

struct PasskeyAccessRow: View {
    @Bindable var model: PasskeyAccessModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HStack(alignment: .top, spacing: Metric.gutter) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Passkeys")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                Text(model.caption)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            action
        }
        .task { await model.refresh() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await model.refresh() }
        }
    }

    @ViewBuilder
    private var action: some View {
        if model.isWorking {
            ProgressView().controlSize(.small)
        } else if model.access == .notDetermined {
            Button("Allow Passkeys") { Task { await model.requestAccess() } }
        } else if model.access == .denied {
            Button("Check Again") { Task { await model.refresh() } }
        } else if model.access == .authorized {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.accent)
        }
    }
}
