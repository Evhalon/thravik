import RedentDesign
import RedentKit
import SwiftUI

/// Hibernation, ad/tracker blocking, autofill offers, and vault entry points.
struct PrivacySettingsPane: View {
    @Binding var settings: BrowserSettings
    let onOpenPasswords: () -> Void
    let onOpenAuthenticatorImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            memory
            privacy
            vault
        }
    }

    private var memory: some View {
        SettingsSection("MEMORY") {
            Picker("Hibernate background tabs", selection: $settings.hibernation) {
                ForEach(HibernationPolicy.selectableCases) { policy in
                    Text(policy.label).tag(policy)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            if settings.hibernation == .custom {
                customMinutesField
            }
            Text(hibernationExplanation)
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var customMinutesField: some View {
        HStack(spacing: 8) {
            TextField("Minutes", value: customMinutes, format: .number)
                .frame(width: 72)
                .textFieldStyle(.roundedBorder)
            Text("minutes")
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private var customMinutes: Binding<Int> {
        Binding(
            get: { max(settings.customHibernationMinutes ?? 15, 1) },
            set: { settings.customHibernationMinutes = max($0, 1) }
        )
    }

    private var privacy: some View {
        SettingsSection("PRIVACY") {
            SettingsToggleRow(
                "Block ads and trackers",
                caption: "On by default, like Brave Shields. YouTube stays unblocked so the player does not die.",
                isOn: $settings.blocksTrackers
            )
            SettingsToggleRow("Offer to save passwords", isOn: $settings.offersPasswordSave)
            SettingsToggleRow("Show one-time code button", isOn: $settings.showsTOTPButton)
        }
    }

    private var vault: some View {
        SettingsSection("VAULT") {
            SettingsLinkRow("Password Manager", systemImage: "key.fill", action: onOpenPasswords)
            SettingsLinkRow(
                "Import from Google Authenticator",
                systemImage: "qrcode.viewfinder",
                action: onOpenAuthenticatorImport
            )
        }
    }

    private var hibernationExplanation: String {
        switch settings.hibernation {
        case .off: "Tabs stay loaded and ready, but use the most memory."
        case .balanced: "Frees memory from idle tabs without losing your place too soon."
        case .aggressive: "Frees memory fastest. Idle tabs may need to reload more often."
        case .thirtyMinutes, .fortyFiveMinutes, .sixtyMinutes:
            "Frees memory after the selected idle time."
        case .custom: "Frees memory after your custom idle time."
        }
    }
}
