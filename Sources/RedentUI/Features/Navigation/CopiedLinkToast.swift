import RedentDesign
import SwiftUI

/// The top-right confirmation for ⇧⌘C, saying whether tracking was removed too.
struct CopiedLinkToast: View {
    let chrome: PageChromeModel
    let notice: CopiedLinkNotice

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: notice.removedTracking ? "checkmark.shield.fill" : "link")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Link copied")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                if notice.removedTracking {
                    Text("Removed all the tracking")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassPanel()
        .allowsHitTesting(false)
        .task(id: notice.id, showThenHide)
        .accessibilityElement(children: .combine)
    }

    private func showThenHide() async {
        announce()
        try? await Task.sleep(for: .seconds(1.8))
        guard !Task.isCancelled, chrome.copiedLink?.id == notice.id else { return }
        withAnimation(.easeOut(duration: 0.2)) { chrome.copiedLink = nil }
    }

    private func announce() {
        let text = notice.removedTracking ? "Link copied. Removed all the tracking" : "Link copied"
        AccessibilityNotification.Announcement(text).post()
    }
}
