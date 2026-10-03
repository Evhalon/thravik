import RedentDesign
import RedentKit
import SwiftUI

/// Settings as a page of the window: it takes the page's place, so there is
/// room to read every option, and the tabs stay one click away.
struct SettingsPage: View {
    @Bindable var model: BrowserModel
    let services: SettingsServices
    @State private var pane: SettingsPane = .general

    var body: some View {
        HStack(spacing: 0) {
            SettingsPaneList(selection: $pane)
            Rectangle()
                .fill(Palette.hairline)
                .frame(width: 1)
            scroll
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.pageChrome)
        .overlay(alignment: .topTrailing) {
            PillDismissButton(help: "Close Settings", action: model.closeSettings)
                .padding(Metric.gutter + 4)
        }
        .onExitCommand(perform: model.closeSettings)
        .onChange(of: services.extensions?.wantsReveal, initial: true) { revealExtensionsIfAsked() }
    }

    private var scroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !showsSignIn {
                    SheetHeading(
                        title: pane.rawValue,
                        subtitle: pane == .testing ? "Real setup and client demos." : "Changes apply immediately. There is no separate Save."
                    )
                }
                paneContent
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.automatic)
    }

    private var showsSignIn: Bool {
        pane == .account && services.account?.session == nil
    }

    private func revealExtensionsIfAsked() {
        guard let extensions = services.extensions, extensions.wantsReveal else { return }
        extensions.wantsReveal = false
        pane = .extensions
        guard !extensions.storeLinkText.isEmpty else { return }
        Task { await extensions.addFromStoreLink() }
    }

    @ViewBuilder
    private var paneContent: some View {
        switch pane {
        case .account:
            if let account = services.account {
                AccountSettingsPane(
                    model: account, passwords: services.passwordStorage,
                    devices: services.devices, workspace: services.workspace,
                    accountSyncManaged: !(model.accountSyncAllowed?() ?? true)
                )
            }
        case .general:
            GeneralSettingsPane(
                settings: $model.settings,
                locks: model.managedPolicyLocks,
                defaultBrowser: services.defaultBrowser,
                onResetWorkspace: model.resetWorkspace
            )
        case .appearance:
            AppearanceSettingsPane(settings: $model.settings)
        case .shortcuts:
            ShortcutsSettingsPane(settings: $model.settings)
        case .privacy:
            PrivacySettingsPane(
                settings: $model.settings,
                locks: model.managedPolicyLocks,
                passkeys: services.passkeys,
                onOpenPasswords: { model.sheet = .passwords },
                onOpenAuthenticatorImport: { model.sheet = .importAuthenticator }
            )
        case .extensions:
            if let extensions = services.extensions {
                ExtensionsSettingsPane(
                    extensions: extensions,
                    onOpenStore: { model.openExtensionStore() },
                    onOpenOptions: model.closeSettings
                )
            }
        case .updates:
            UpdatesSettingsPane(updates: services.updates)
        case .testing:
            TestingSettingsPane(restartOnboarding: services.restartOnboarding,
                                restartRealOnboarding: services.restartRealOnboarding,
                                simulateStaleTabs: { model.simulateStaleTabsForTidyDemo() },
                                onDismiss: model.closeSettings)
        }
    }
}
