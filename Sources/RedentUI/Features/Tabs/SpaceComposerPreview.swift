import RedentDesign
import RedentKit
import SwiftUI

/// The Space as it will appear, redrawn on every keystroke and pick.
struct SpaceComposerPreview: View {
    let draft: SpaceDraft

    var body: some View {
        VStack(spacing: 8) {
            ChromeOrb(systemImage: draft.look.icon, tint: tint, isSelected: true, size: 58)
                .background { halo }
                .contentTransition(.symbolEffect(.replace))
            Text(draft.trimmedName ?? (draft.isEditing ? "Untitled" : "New Space"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(draft.trimmedName == nil ? Palette.chromeSecondaryText : Palette.chromeText)
                .lineLimit(1)
                .contentTransition(.interpolate)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .animation(.spring(duration: 0.35), value: draft.look)
        .accessibilityElement(children: .combine)
    }

    /// A radial falloff looks like a blurred disc but costs no offscreen
    /// pass, which matters while the color animates on every pick.
    private var halo: some View {
        RadialGradient(colors: [tint.opacity(0.4), tint.opacity(0)], center: .center, startRadius: 20, endRadius: 64)
            .frame(width: 128, height: 128)
            .allowsHitTesting(false)
    }

    private var tint: Color { SpaceTintColor.color(draft.look.colorToken) }
}
