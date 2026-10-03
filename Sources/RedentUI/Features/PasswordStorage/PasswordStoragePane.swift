import RedentDesign
import RedentKit
import SwiftUI

struct PasswordStoragePane: View {
    @Bindable var model: PasswordStorageModel
    @State private var destination: PasswordStorageMode = .local
    @State private var copiesPasswords = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Password storage").font(.headline)
            providerControls
            if model.selectedMode == .redentCloud {
                Button("Sync Now") { Task { await model.synchronize() } }
            }
            if let reason = model.iCloudUnavailableReason { Text(reason).font(.caption) }
            if model.isCloudSignedIn { CloudPasswordVaultPane(model: model) }
            if model.isBusy { ProgressView() }
            ForEach(model.conflicts) { conflict in
                PasswordConflictRow(conflict: conflict, model: model)
            }
            if let message = model.message { Text(message).font(.caption) }
        }
        .disabled(model.isBusy)
        .task { await model.restore(); destination = model.selectedMode }
        .onChange(of: model.selectedMode) { _, mode in destination = mode }
    }

    private var providerControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Store passwords in", selection: $destination) {
                ForEach(PasswordStorageMode.allCases, id: \.self) { mode in
                    Text(label(mode)).tag(mode).disabled(!model.availableModes.contains(mode))
                }
            }
            Text("Current: \(label(model.selectedMode))")
            Toggle("Copy current passwords to the selected provider", isOn: $copiesPasswords)
            Text("Original passwords are retained. Only the selected provider receives future saves.")
                .font(.caption).foregroundStyle(Palette.chromeSecondaryText)
            Button("Apply") { Task { await model.select(destination, copyingCurrent: copiesPasswords) } }
                .disabled(destination == model.selectedMode || !model.availableModes.contains(destination))
        }
    }

    private func label(_ mode: PasswordStorageMode) -> String {
        switch mode {
        case .local: "This Mac (Keychain)"
        case .redentCloud: "Redent Cloud (end-to-end encrypted)"
        case .iCloud: "iCloud Keychain"
        }
    }
}
