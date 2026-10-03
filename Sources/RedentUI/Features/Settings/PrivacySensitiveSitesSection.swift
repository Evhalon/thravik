import RedentDesign
import RedentKit
import SwiftUI

struct PrivacySensitiveSitesSection: View {
    @Binding var settings: BrowserSettings
    @State private var draft = ""
    @State private var inputError: String?

    var body: some View {
        SettingsToggleRow(
            "Don't record history for banking and health sites",
            caption: "Uses a small built-in list of well-known financial and health registrable domains.",
            isOn: $settings.excludeBankingAndHealthFromHistory
        )
        VStack(alignment: .leading, spacing: 8) {
            Text("Never record history for these sites")
                .font(.system(size: 12, weight: .medium))
            HStack(spacing: 8) {
                TextField("example.com", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addDomain)
                Button("Add", action: addDomain)
            }
            if let inputError {
                Text(inputError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
            if settings.sensitiveSiteHistoryDomains.isEmpty {
                Text("No custom domains yet.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            } else {
                ForEach(settings.sensitiveSiteHistoryDomains, id: \.self) { domain in
                    HStack {
                        Text(domain).font(.system(size: 12))
                        Spacer()
                        Button("Remove") { remove(domain) }
                    }
                }
            }
        }
    }

    private func addDomain() {
        switch settings.addSensitiveHistoryDomain(draft) {
        case .success:
            draft = ""
            inputError = nil
        case .failure(.empty):
            inputError = "Enter a domain or site address."
        case .failure(.invalidHost):
            inputError = "Enter a valid host or registrable domain."
        }
    }

    private func remove(_ domain: String) {
        settings.sensitiveSiteHistoryDomains.removeAll { $0 == domain }
    }
}
