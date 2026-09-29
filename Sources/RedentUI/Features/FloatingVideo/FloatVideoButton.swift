import RedentDesign
import SwiftUI

struct FloatVideoButton: View {
    @Bindable var model: BrowserModel

    var body: some View {
        Button(action: model.toggleFloatingVideo) {
            Image(systemName: model.isVideoFloating ? "pip.exit" : "pip.enter")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(model.isVideoFloating ? Palette.accent : Palette.chromeSecondaryText)
                .frame(width: 18)
        }
        .buttonStyle(PressScaleStyle())
        .help(model.isVideoFloating ? "Return video to tab" : "Float video")
        .accessibilityLabel(model.isVideoFloating ? "Return video to tab" : "Float video")
    }
}
