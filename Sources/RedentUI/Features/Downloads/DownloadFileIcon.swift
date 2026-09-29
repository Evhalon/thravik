import AppKit
import RedentKit
import SwiftUI
import UniformTypeIdentifiers

/// The Finder icon for a download's file type.
///
/// Resolved from the name's extension rather than the file on disk: no disk
/// read on the main actor, and the icon is right from the first byte instead
/// of changing once the file lands.
struct DownloadFileIcon: View {
    let filename: String
    var size: CGFloat = 30

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    private var icon: NSImage {
        let ext = (filename as NSString).pathExtension
        let type = UTType(filenameExtension: ext) ?? .data
        return NSWorkspace.shared.icon(for: type)
    }
}
