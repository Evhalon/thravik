import RedentDesign
import RedentKit
import SwiftUI

struct SidebarNowPlayingArtwork: View {
    let item: NowPlaying
    let tab: any BrowserTab

    var body: some View {
        ZStack {
            FaviconView(data: tab.snapshot.faviconData, host: tab.origin?.displayHost, size: 28)
            if let url = item.artworkURL {
                AsyncImage(url: url) { image in
                    image.resizable().interpolation(.high).aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(width: 28, height: 28)
    }
}
