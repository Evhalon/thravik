import RedentDesign
import RedentKit
import SwiftUI

struct OnboardingImportReceiptView: View {
    let receipt: BrowserImportReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: receipt.problem == nil ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(receipt.problem == nil ? Palette.accent : Palette.danger)
            row("Bookmarks", symbol: "star", count: receipt.summary.bookmarks)
            row("Browsing history", symbol: "clock", count: receipt.summary.history)
            row("Saved passwords", symbol: "key", count: receipt.summary.passwords)
            Divider().overlay(.white.opacity(0.08))
            Text("LAST IMPORT · \(receipt.profileNames.count) PROFILES")
                .font(.system(size: 10, weight: .semibold)).tracking(0.8).foregroundStyle(.secondary)
            ScrollView {
                Text(receipt.profileNames.joined(separator: " · "))
                    .font(.system(size: 12)).foregroundStyle(Palette.chromeSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 60)
            if let problem = receipt.problem {
                Text(problem).font(.caption).foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 14))
    }

    private var title: String {
        if receipt.problem != nil { return "Import finished with issues" }
        return receipt.summary.isEmpty ? "Import finished — no new items" : "Import complete"
    }

    private func row(_ title: String, symbol: String, count: Int) -> some View {
        HStack {
            Label(title, systemImage: symbol).font(.system(size: 15))
            Spacer()
            Text(count, format: .number).font(.system(size: 15, weight: .semibold))
                .monospacedDigit().foregroundStyle(count > 0 ? Palette.chromeText : Palette.chromeSecondaryText)
        }
    }
}
