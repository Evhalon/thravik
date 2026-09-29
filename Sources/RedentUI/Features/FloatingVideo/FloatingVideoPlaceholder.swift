import RedentDesign
import RedentKit
import SwiftUI

struct FloatingVideoPlaceholder: View {
    let tab: any BrowserTab

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pip")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text("Video is floating")
                .font(.system(size: 15, weight: .medium))
            Button("Return to tab") { tab.returnVideoToTab() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
