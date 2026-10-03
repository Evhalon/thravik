import RedentDesign
import RedentKit
import SwiftUI

struct OnboardingImportPage: View {
    @Bindable var model: OnboardingModel
    @State private var demoImported = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Bring a little of home.")
                .font(.system(size: 30, weight: .medium, design: .rounded))
            Text("Move your bookmarks, history and saved passwords from another browser.")
                .foregroundStyle(Palette.chromeSecondaryText)
            if let receipt {
                OnboardingImportReceiptView(receipt: receipt)
            } else {
                categories
            }
            Text(importDetail)
                .font(.caption).foregroundStyle(.secondary)
            Button(hasImport ? "Import again" : "Choose browser…", action: openImport)
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!model.isDemo && model.onImportBrowser == nil)
            navigation
        }
    }

    private var navigation: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button("Back", action: model.back)
                Spacer()
                Button("Continue", action: model.advance)
            }
            .buttonStyle(.plain)
            if !hasImport {
                Button("Skip import for now", action: model.advance)
                    .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var importDetail: String {
        if model.isDemo { return "Demo import. No browser data is read or changed." }
        if model.importReceipt != nil { return "Your latest import is shown above. You can continue or import from another browser." }
        return "Choose the profiles and data to bring. Import runs locally; passwords may require permission from macOS."
    }

    private var receipt: BrowserImportReceipt? {
        guard model.isDemo else { return model.importReceipt }
        guard demoImported else { return nil }
        return BrowserImportReceipt(summary: ImportSummary(history: 48, bookmarks: 12, passwords: 3),
                                    profileNames: ["Demo browser — Personal", "Demo browser — Work"], problem: nil)
    }

    private var hasImport: Bool { model.isDemo ? demoImported : model.importReceipt != nil }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Bookmarks", systemImage: "star")
            Label("Browsing history", systemImage: "clock")
            Label("Saved passwords", systemImage: "key")
        }
        .font(.system(size: 15)).padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 14))
    }

    private func openImport() {
        if model.isDemo { demoImported = true }
        else { model.onImportBrowser?() }
    }
}
