import RedentDesign
import SwiftUI

/// The small close mark at the end of a floating sign-in pill. A pill the page
/// raised by mistake has to be removable by the user, not only by the page.
struct PillDismissButton: View {
    let help: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(isHovering ? Palette.chromeText : Palette.chromeSecondaryText)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.white.opacity(isHovering ? 0.16 : 0.08)))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(help)
    }
}
