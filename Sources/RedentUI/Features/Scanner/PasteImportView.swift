import RedentDesign
import SwiftUI

/// The paste route: for people who already extracted the raw
/// `otpauth://` or `otpauth-migration://` string, e.g. from a password
/// manager's export or another tool.
struct PasteImportView: View {
    let collector: ScannedPayloadCollector

    @State private var text = ""
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            Text("Paste an otpauth:// or otpauth-migration:// link")
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
            TextField("otpauth://totp/...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(Metric.tightGutter)
                .glassPanel(radius: Metric.smallRadius, tint: nil)
            HStack {
                Button("Add", action: submit)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if let statusMessage {
                    Text(statusMessage).font(.caption).foregroundStyle(Palette.chromeSecondaryText)
                }
            }
        }
    }

    private func submit() {
        let payload = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return }
        Task {
            switch await collector.add(payloadText: payload) {
            case .added(let count):
                statusMessage = count > 0 ? "Added \(count) account\(count == 1 ? "" : "s")." : "Already added."
                text = ""
            case .duplicate:
                statusMessage = "Already scanned that one."
            case .failed:
                statusMessage = "That doesn't look like a valid export."
            }
        }
    }
}
