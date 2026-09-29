import RedentDesign
import SwiftUI

/// An eye-icon toggle that flips `isRevealed`. Used for masked passwords —
/// nothing decrypts or displays until the user explicitly asks.
struct SecureRevealButton: View {
    @Binding var isRevealed: Bool

    var body: some View {
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .buttonStyle(.plain)
        .help(isRevealed ? "Hide password" : "Reveal password")
    }
}
