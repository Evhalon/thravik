import RedentDesign
import RedentKit
import SwiftUI

/// Saved logins grouped by site, with a search field and per-row actions.
struct PasswordListView: View {
    @Bindable var model: VaultListModel

    @State private var pendingDelete: Credential?

    var body: some View {
        VStack(spacing: 0) {
            searchField
            if model.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.credentialError {
                VaultEmptyState(systemImage: "exclamationmark.triangle", message: error)
            } else if model.groupedCredentials.isEmpty {
                VaultEmptyState(systemImage: "key", message: "Nothing saved yet")
            } else {
                list
            }
        }
        .confirmationDialog(
            "Delete this password?", isPresented: isShowingDeleteConfirm, presenting: pendingDelete
        ) { credential in
            Button("Delete", role: .destructive) {
                Task { await model.deleteCredential(credential.id) }
            }
        } message: { credential in
            Text("This removes the saved login for \(credential.origin.displayHost).")
        }
    }

    private var searchField: some View {
        TextField("Search passwords", text: $model.searchText)
            .textFieldStyle(.plain)
            .padding(Metric.gutter)
    }

    private var list: some View {
        List {
            ForEach(model.groupedCredentials, id: \.host) { group in
                Section(group.host) {
                    ForEach(group.items) { credential in
                        PasswordRow(
                            credential: credential,
                            spaceName: model.spaceName(for: credential),
                            onCopyUsername: { model.copyUsername(credential) },
                            onCopyPassword: { model.copyPassword(credential) },
                            onDelete: { pendingDelete = credential }
                        )
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private var isShowingDeleteConfirm: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}
