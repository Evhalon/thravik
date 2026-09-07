import RedentDesign
import SwiftUI

/// Stands in for a screen that needs something the window does not have yet —
/// a site to inspect, most often. Says why, rather than opening empty.
public struct SheetPlaceholder: View {
    private let message: String
    @Environment(\.dismiss) private var dismiss

    public init(message: String) { self.message = message }

    public var body: some View {
        VStack(spacing: Metric.gutter) {
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeSecondaryText)
            Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 380)
    }
}
