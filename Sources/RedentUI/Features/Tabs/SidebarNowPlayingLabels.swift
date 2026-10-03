import RedentDesign
import RedentKit
import SwiftUI

struct SidebarNowPlayingLabels: View {
    let item: NowPlaying

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            if let artist = item.artist {
                Text(artist)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
