import RedentDesign
import RedentKit
import SwiftUI

/// The password + authenticator manager: one window, two lists behind a
/// segmented control, both driven by the storage ports.
public struct VaultWindowView: View {
    public enum InitialTab: Equatable {
        case passwords, authenticator
    }

    private enum Tab: String, CaseIterable, Identifiable {
        case passwords = "Passwords", authenticator = "Authenticator"
        var id: String { rawValue }
    }

    private let generator: any TOTPGenerating
    private let onImportAuthenticator: () -> Void
    @State private var model: VaultListModel
    @State private var tab: Tab = .passwords
    @Environment(\.dismiss) private var dismiss

    public init(
        sources: VaultSources,
        initialTab: InitialTab = .passwords,
        onImportAuthenticator: @escaping () -> Void = {}
    ) {
        self.generator = sources.generator
        self.onImportAuthenticator = onImportAuthenticator
        _model = State(initialValue: VaultListModel(
            credentialStore: sources.credentials,
            totpStore: sources.totp
        ))
        _tab = State(initialValue: initialTab == .authenticator ? .authenticator : .passwords)
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(Metric.gutter)

            switch tab {
            case .passwords: PasswordListView(model: model)
            case .authenticator:
                AuthenticatorListView(
                    model: model, generator: generator, onImport: onImportAuthenticator
                )
            }

            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(minWidth: 420, minHeight: 480)
        .sheetCanvas(width: 620, height: 560)
        .task { await model.load() }
    }
}
