import SwiftUI

struct FloatingNewTabPanelMotion: ViewModifier {
    let revealed: Bool
    let isClosing: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        let raised = reduceMotion || (revealed && !isClosing)
        content
            .rotation3DEffect(.degrees(raised ? 0 : -6), axis: (x: 1, y: 0, z: 0),
                              anchor: .top, perspective: 0.55)
            .scaleEffect(raised ? 1 : 0.97, anchor: .top)
            .offset(y: raised ? 0 : 8)
            .blur(radius: reduceMotion || raised ? 0 : 10)
    }
}
