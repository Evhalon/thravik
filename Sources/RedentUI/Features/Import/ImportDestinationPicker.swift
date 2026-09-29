import RedentDesign
import SwiftUI

/// Which Space an import lands in. Bookmarks and logins belong to a profile,
/// so bringing another browser's account across means naming the profile.
struct ImportDestinationPicker: View {
    @Binding var destination: ImportDestination

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            Text("INTO WHICH SPACE").font(.system(size: 9.5, weight: .bold)).tracking(1)
                .foregroundStyle(Palette.chromeSecondaryText)
            Picker("Space", selection: $destination.spaceID) {
                ForEach(destination.spaces) { space in
                    Text(space.name).tag(UUID?.some(space.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
            Text("Bookmarks and logins join this Space. History is shared across all of them.")
                .font(.system(size: 10.5))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }
}
