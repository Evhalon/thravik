import RedentDesign
import SwiftUI

/// Shown once after an update: the offer to hand web links to Redent.
///
/// macOS puts up its own confirmation on top of this one, so the sheet asks
/// plainly and gets out of the way.
public struct DefaultBrowserSheet: View {
    @Bindable private var model: DefaultBrowserModel
    @Environment(\.dismiss) private var dismiss

    public init(model: DefaultBrowserModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            Image(systemName: "globe")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.accent)

            SheetHeading(
                title: "Make \(AppIdentity.displayName) your default browser?",
                subtitle: "Links you open in Mail, Messages and everywhere else will "
                    + "come here instead of Safari. macOS will ask you to confirm."
            )

            Spacer(minLength: 0)
            buttons
        }
        .padding(Metric.gutter + 6)
        .sheetCanvas(width: 430, height: 260)
    }

    private var buttons: some View {
        HStack {
            Button("Don't Ask Again") {
                model.silence()
                dismiss()
            }
            .controlSize(.small)

            Spacer()
            Button("Not Now") { dismiss() }
            Button("Use \(AppIdentity.displayName)") {
                model.requestDefault()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}
