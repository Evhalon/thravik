import RedentDesign
import RedentKit
import SwiftUI

/// One saved login: favicon, username, a masked password revealed on
/// request, and copy/delete actions.
struct PasswordRow: View {
    let credential: Credential
    /// Which profile saved it, so two accounts on one site are legible.
    let spaceName: String?
    let onCopyUsername: () -> Void
    let onCopyPassword: () -> Void
    let onDelete: () -> Void

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: Metric.gutter) {
            FaviconView(data: nil, host: credential.origin.displayHost, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(credential.username).font(.body)
                    if let spaceName {
                        Text(spaceName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Palette.chromeSecondaryText)
                    }
                }
                Text(isRevealed ? credential.password : maskedPassword)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer()
            SecureRevealButton(isRevealed: $isRevealed)
            Button(action: onCopyUsername) { Image(systemName: "person") }
                .buttonStyle(.plain).help("Copy username")
            Button(action: onCopyPassword) { Image(systemName: "doc.on.doc") }
                .buttonStyle(.plain).help("Copy password")
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(.plain).help("Delete")
        }
        .padding(.vertical, Metric.tightGutter)
    }

    private var maskedPassword: String { String(repeating: "•", count: 10) }
}
