import RedentDesign
import SwiftUI

struct ManagedPolicyCaption: View {
    var body: some View {
        Text("Managed by your organization")
            .font(.system(size: 11))
            .foregroundStyle(Palette.chromeSecondaryText)
    }
}

extension View {
    func managedPolicyLocked(_ isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            self.disabled(isLocked)
            if isLocked { ManagedPolicyCaption() }
        }
    }
}
