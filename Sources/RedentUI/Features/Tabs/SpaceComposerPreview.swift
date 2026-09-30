import RedentDesign
import RedentKit
import SwiftUI

/// The Space as it will appear, redrawn on every keystroke and pick.
struct SpaceComposerPreview: View {
    let draft: SpaceDraft

    var body: some View {
        VStack(spacing: 8) {
            ChromeOrb(systemImage: draft.look.icon, tint: tint, isSelected: true, size: 58)
                .background { Circle().fill(tint.opacity(0.35)).blur(radius: 22).scaleEffect(1.6) }
                .contentTransition(.symbolEffect(.replace))
            Text(draft.trimmedName ?? (draft.isEditing ? "Untitled" : "New Space"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(draft.trimmedName == nil ? Palette.chromeSecondaryText : Palette.chromeText)
                .lineLimit(1)
                .contentTransition(.interpolate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .animation(.spring(duration: 0.35), value: draft.look)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color { SpacePalette.color(draft.look.colorToken) }
}
