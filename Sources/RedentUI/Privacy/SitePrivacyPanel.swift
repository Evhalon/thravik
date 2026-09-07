import RedentDesign
import RedentKit
import SwiftUI

/// What one site is allowed to do and what it has stored, with an honest
/// account of what a Forget pass removed and what it deliberately kept.
public struct SitePrivacyPanel: View {
    @State private var model: SitePrivacyModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirming = false

    public init(model: SitePrivacyModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.origin.displayHost).font(.title2.bold())
            permissions
            storedData
            if let report = model.report { SiteForgetSummary(report: report) }
            Spacer(minLength: 0)
            HStack {
                Button("Forget This Site", role: .destructive) { isConfirming = true }
                    .disabled(model.isWorking)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 540, height: 480)
        .task { await model.load() }
        .confirmationDialog(
            "Forget \(model.deletionScope)?", isPresented: $isConfirming, titleVisibility: .visible
        ) {
            Button("Forget Site", role: .destructive) { Task { await model.forgetSite() } }
        } message: {
            Text("Cookies, storage and history for \(model.deletionScope) are removed in every Container. Bookmarks and saved passwords are kept. This cannot be undone.")
        }
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Permissions").font(.headline)
            ForEach(SitePermission.allCases, id: \.self) { permission in
                Picker(permission.label, selection: binding(for: permission)) {
                    ForEach(PermissionDecision.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private var storedData: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stored data").font(.headline)
            if model.records.isEmpty {
                Text(model.isWorking ? "Checking…" : "Nothing stored in this Container.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.chromeSecondaryText)
            } else {
                ForEach(model.records) { record in
                    Text("\(record.displayName) — \(record.dataTypes.count) kinds of data")
                        .font(.system(size: 12))
                }
            }
        }
    }

    private func binding(for permission: SitePermission) -> Binding<PermissionDecision> {
        Binding(
            get: { model.policy.decision(for: permission) },
            set: { model.set($0, for: permission) }
        )
    }
}
