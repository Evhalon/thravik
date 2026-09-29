import RedentDesign
import RedentKit
import SwiftUI

/// Quiet mode's account of the page on screen, so the silence is something the
/// user can check rather than take on faith.
struct QuietReceiptRow: View {
    let receipt: QuietReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quiet").font(.headline)
            Label(summary, systemImage: receipt.isEmpty ? "moon" : "moon.fill")
                .font(.system(size: 12))
                .foregroundStyle(receipt.isEmpty ? Palette.chromeSecondaryText : Palette.chromeText)
        }
    }

    private var summary: String {
        guard !receipt.isEmpty else { return "Nothing on this page needed quieting." }
        var parts: [String] = []
        if receipt.declinedCookieBanners > 0 { parts.append("Declined the cookie banner") }
        if receipt.stoppedAutoplays > 0 {
            let count = receipt.stoppedAutoplays
            parts.append("stopped \(count) \(count == 1 ? "video" : "videos") playing sound on its own")
        }
        return parts.joined(separator: ", ") + "."
    }
}
