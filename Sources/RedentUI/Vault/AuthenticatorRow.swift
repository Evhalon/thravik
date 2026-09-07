import RedentDesign
import RedentKit
import SwiftUI

/// One authenticator account: issuer/name, the current code, its countdown,
/// a copy button, linked domains, and delete.
struct AuthenticatorRow: View {
    let account: TOTPAccount
    let code: TOTPCode?
    let now: Date
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            details
            Spacer()
            if let code {
                Text(code.grouped).font(.system(.title3, design: .monospaced))
                CountdownRing(fraction: code.fractionRemaining(at: now), lineWidth: 2, tint: Palette.accent)
                    .frame(width: 20, height: 20)
                Button(action: onCopy) { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.plain).help("Copy code")
            }
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(.plain).help("Delete")
        }
        .padding(.vertical, Metric.tightGutter)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(account.displayName).font(.body)
            if !account.linkedDomains.isEmpty {
                Text(account.linkedDomains.sorted().joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
        }
    }
}
