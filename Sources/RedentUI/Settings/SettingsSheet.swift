import RedentDesign
import RedentKit
import SwiftUI

/// Settings as a glass sheet. Segmented panes, not `TabView` — macOS 26's
/// tab bar tries to own the window chrome and clips the footer in a sheet.
public struct SettingsSheet: View {
    private enum Pane: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case privacy = "Privacy"
        case updates = "Updates"
        var id: String { rawValue }
    }

    @Binding private var settings: BrowserSettings
    private let updates: UpdateModel
    private let defaultBrowser: DefaultBrowserModel
    private let onOpenPasswords: () -> Void
    private let onOpenAuthenticatorImport: () -> Void
    private let onResetWorkspace: () -> Void
    @State private var pane: Pane = .general
    @Environment(\.dismiss) private var dismiss

    public init(
        settings: Binding<BrowserSettings>,
        updates: UpdateModel,
        defaultBrowser: DefaultBrowserModel,
        onOpenPasswords: @escaping () -> Void,
        onOpenAuthenticatorImport: @escaping () -> Void,
        onResetWorkspace: @escaping () -> Void
    ) {
        self._settings = settings
        self.updates = updates
        self.defaultBrowser = defaultBrowser
        self.onOpenPasswords = onOpenPasswords
        self.onOpenAuthenticatorImport = onOpenAuthenticatorImport
        self.onResetWorkspace = onResetWorkspace
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeading(
                title: "Settings",
                subtitle: "Changes apply immediately. There is no separate Save."
            )
            picker
            ScrollView {
                paneContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            }
            .scrollIndicators(.never)
            footer
        }
        .padding(20)
        .sheetCanvas(width: 560, height: 540)
        .presentationBackground(.ultraThinMaterial)
    }

    private var picker: some View {
        Picker("", selection: $pane) {
            ForEach(Pane.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var paneContent: some View {
        switch pane {
        case .general:
            GeneralSettingsPane(
                settings: $settings,
                defaultBrowser: defaultBrowser,
                onResetWorkspace: onResetWorkspace
            )
        case .appearance:
            AppearanceSettingsPane(settings: $settings)
        case .privacy:
            PrivacySettingsPane(
                settings: $settings,
                onOpenPasswords: onOpenPasswords,
                onOpenAuthenticatorImport: onOpenAuthenticatorImport
            )
        case .updates:
            UpdatesSettingsPane(updates: updates)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .keyboardShortcut(.defaultAction)
        }
    }
}

#if DEBUG
/// The preview needs a model, not a network round trip.
private struct QuietUpdateChecker: UpdateChecking {
    func latestRelease() async throws -> AppRelease { throw CancellationError() }
}

private struct QuietUpdateInstaller: UpdateInstalling {
    func stage(_ release: AppRelease) async throws {}
}

private struct QuietDefaultBrowser: DefaultBrowserManaging {
    func isDefault() async -> Bool { false }
    func makeDefault() async -> Bool { false }
}

private struct QuietPromptStore: DefaultBrowserPromptStoring {
    var lastPromptedVersion: String? { nil }
    var isSilenced: Bool { true }
    func recordPrompt(for version: String?) {}
    func silence() {}
}

#Preview {
    @Previewable @State var settings = BrowserSettings()
    return SettingsSheet(
        settings: $settings,
        updates: UpdateModel(
            currentVersion: AppVersion("0.1.2"),
            checker: QuietUpdateChecker(),
            installer: QuietUpdateInstaller(),
            quit: {}
        ),
        defaultBrowser: DefaultBrowserModel(
            manager: QuietDefaultBrowser(),
            store: QuietPromptStore(),
            installedVersion: "0.1.2"
        ),
        onOpenPasswords: {},
        onOpenAuthenticatorImport: {},
        onResetWorkspace: {}
    )
}
#endif
