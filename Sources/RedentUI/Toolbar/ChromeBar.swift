import RedentDesign
import SwiftUI

/// The window's one toolbar row.
///
/// `PageColumn` gives it a row above the page card rather than floating it over
/// the content, so it never covers a site's own header. The same row serves both
/// tab layouts, so the address never moves when the rail is toggled.
struct ChromeBar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            if !model.isSidebarVisible {
                SpaceSwitcher(model: model, current: model.currentSpace)
                    .frame(minWidth: 96, maxWidth: 168, alignment: .leading)
            }
            NavigationControls(model: model)
                .frame(width: 132)
            AddressField(model: model)
                .frame(maxWidth: 720)
                .zIndex(2)
            if model.isPrivate { ChromeBadge("PRIVATE", tint: Palette.accent) }
            if model.showsVolumeControl { TabVolumeButton(model: model) }
            DownloadsButton(model: model)
            BrowserMenu(model: model)
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .padding(.vertical, Metric.tightGutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { TitlebarDragRegion() }
    }
}
