import RedentDesign
import RedentKit
import SwiftUI

/// Saved authenticator accounts, with codes refreshed by one shared
/// `TimelineView` tick — not one timer per row.
struct AuthenticatorListView: View {
    @Bindable var model: VaultListModel
    let generator: any TOTPGenerating
    let onImport: () -> Void

    @State private var pendingDelete: TOTPAccount?

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.authenticatorError {
                VaultEmptyState(systemImage: "exclamationmark.triangle", message: error)
            } else if model.accounts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .confirmationDialog(
            "Delete this account?", isPresented: isShowingDeleteConfirm, presenting: pendingDelete
        ) { account in
            Button("Delete", role: .destructive) {
                Task { await model.deleteAccount(account.id) }
            }
        } message: { account in
            Text("This removes \(account.displayName) and its saved codes.")
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            importButton
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                List(model.accounts) { account in
                    AuthenticatorRow(
                        account: account,
                        code: try? generator.code(for: account, at: timeline.date),
                        now: timeline.date,
                        onCopy: { copyCode(for: account) },
                        onDelete: { pendingDelete = account }
                    )
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Metric.gutter) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text("Nothing saved yet")
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
            Button("Scan QR with Camera", action: onImport)
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var importButton: some View {
        HStack {
            Spacer()
            Button("Scan QR with Camera", action: onImport)
                .buttonStyle(.borderless)
                .padding(.horizontal, Metric.gutter)
                .padding(.vertical, Metric.tightGutter)
        }
    }

    private func copyCode(for account: TOTPAccount) {
        guard let code = try? generator.code(for: account) else { return }
        ConcealedPasteboard.copy(code.digits)
    }

    private var isShowingDeleteConfirm: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}
