import RedentDesign
import RedentKit
import SwiftUI

/// The compact list that drops from the toolbar's downloads button: the recent
/// files, newest on top, with each new arrival sliding in above the rest.
struct DownloadsPopover: View {
    @Bindable var downloads: DownloadsModel
    let onShowAll: () -> Void

    /// Past this the list scrolls; the popover should never cover the page.
    private static let visibleRows = 6
    private static let rowHeight: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(downloads.items) { item in
                        row(for: item)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, 6)
            }
            .frame(height: listHeight)
            .scrollBounceBehavior(.basedOnSize)
            Divider().padding(.top, 6)
            footer
        }
        .frame(width: 340)
        .animation(.spring(duration: 0.38, bounce: 0.25), value: downloads.items.map(\.id))
        .onAppear(perform: downloads.markSeen)
    }

    private var listHeight: CGFloat {
        CGFloat(min(downloads.items.count, Self.visibleRows)) * Self.rowHeight
    }

    private var header: some View {
        HStack {
            Text("Downloads").font(.system(size: 13, weight: .semibold))
            Spacer()
            Button("Clear", action: downloads.clearFinished)
                .buttonStyle(.plain)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
                .disabled(downloads.items.allSatisfy(\.isActive))
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var footer: some View {
        HStack {
            Button("Open Downloads Folder", action: downloads.openDownloadsFolder)
            Spacer()
            Button("Show All", action: onShowAll)
        }
        .buttonStyle(.plain)
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(Palette.accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func row(for item: DownloadItem) -> some View {
        DownloadRow(
            item: item,
            onCancel: { downloads.cancel(item.id) },
            onReveal: { downloads.revealInFinder(item) },
            onOpen: { downloads.openFile(item) },
            onRemove: { downloads.remove(item.id) }
        )
    }
}
