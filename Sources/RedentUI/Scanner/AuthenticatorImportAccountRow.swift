import RedentDesign
import RedentKit
import SwiftUI

/// One imported account on the success screen: email first, issuer underneath.
/// Never shows the seed.
struct AuthenticatorImportAccountRow: View {
    let account: TOTPAccount

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(primaryLabel).font(.body.weight(.medium))
                if let secondaryLabel {
                    Text(secondaryLabel)
                        .font(.caption)
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
            }
            Spacer()
        }
        .padding(.vertical, Metric.tightGutter)
    }

    private var primaryLabel: String {
        account.accountName.isEmpty ? account.issuer : account.accountName
    }

    private var secondaryLabel: String? {
        guard !account.issuer.isEmpty, !account.accountName.isEmpty else { return nil }
        return account.issuer
    }
}
