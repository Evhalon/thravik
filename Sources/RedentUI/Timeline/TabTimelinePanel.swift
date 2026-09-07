import RedentDesign
import RedentKit
import SwiftUI

/// The path one tab took, newest first, and what can actually be restored from
/// each point. A step whose live state is gone offers a reload, not a promise.
public struct TabTimelinePanel: View {
    private let tab: any BrowserTab
    @Environment(\.dismiss) private var dismiss

    public init(tab: any BrowserTab) { self.tab = tab }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tab Timeline").font(.title2.bold())
            Text(tab.snapshot.displayTitle)
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeSecondaryText)
                .lineLimit(1)
            content
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 560, height: 460)
    }

    @ViewBuilder
    private var content: some View {
        if tab.timeline.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 24, weight: .light))
                Text("This tab has not navigated yet.").font(.system(size: 12))
            }
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(tab.timeline.reversed()) { entry in
                TabTimelineRow(entry: entry) { tab.travel(to: entry); dismiss() }
            }
            .listStyle(.inset)
        }
    }
}
