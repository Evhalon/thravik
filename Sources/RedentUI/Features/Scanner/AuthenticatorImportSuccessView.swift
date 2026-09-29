import RedentDesign
import SwiftUI

/// Shown after a valid QR is saved. Camera is already off — this view is
/// not in the same tree as `CameraScanRouteView`. Checkmark springs in,
/// then the imported emails, then "Add another".
struct AuthenticatorImportSuccessView: View {
    let outcome: AuthenticatorImportOutcome
    let onAddAnother: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Metric.gutter) {
            header
            accountList
            Spacer(minLength: 0)
            Button("Add another", action: onAddAnother)
                .buttonStyle(.glassProminent)
        }
        .onAppear { play() }
    }

    private var header: some View {
        VStack(spacing: Metric.tightGutter) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Palette.accent)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .scaleEffect(appeared ? 1 : 0.35)
                .opacity(appeared ? 1 : 0)
            Text(outcome.headline).font(.title2.bold())
                .opacity(appeared ? 1 : 0)
            Text(outcome.detail)
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
        }
        .padding(.top, Metric.gutter)
    }

    private var accountList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(outcome.accounts) { account in
                    AuthenticatorImportAccountRow(account: account)
                }
            }
            .padding(Metric.gutter)
        }
        .glassPanel(radius: Metric.cornerRadius, tint: nil)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private func play() {
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) { appeared = true }
    }
}
