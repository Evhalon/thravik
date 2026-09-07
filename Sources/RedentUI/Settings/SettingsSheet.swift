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
        var id: String { rawValue }
    }

    @Binding private var settings: BrowserSettings
    private let onOpenPasswords: () -> Void
    private let onOpenAuthenticatorImport: () -> Void
    @State private var pane: Pane = .general
    @Environment(\.dismiss) private var dismiss

    public init(
        settings: Binding<BrowserSettings>,
        onOpenPasswords: @escaping () -> Void,
        onOpenAuthenticatorImport: @escaping () -> Void
    ) {
        self._settings = settings
        self.onOpenPasswords = onOpenPasswords
        self.onOpenAuthenticatorImport = onOpenAuthenticatorImport
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
            GeneralSettingsPane(settings: $settings)
        case .appearance:
            AppearanceSettingsPane(settings: $settings)
        case .privacy:
            PrivacySettingsPane(
                settings: $settings,
                onOpenPasswords: onOpenPasswords,
                onOpenAuthenticatorImport: onOpenAuthenticatorImport
            )
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
#Preview {
    @Previewable @State var settings = BrowserSettings()
    return SettingsSheet(
        settings: $settings, onOpenPasswords: {}, onOpenAuthenticatorImport: {}
    )
}
#endif
