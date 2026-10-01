import RedentDesign
import SwiftUI

/// The window's one toolbar row.
///
/// `PageColumn` gives it a row above the page card rather than floating it over
/// the content, so it never covers a site's own header. The same row serves both
/// tab layouts, and the address stays centered on the row whichever buttons are
/// showing, so it never moves when the rail is toggled.
struct ChromeBar: View {
    @Bindable var model: BrowserModel
    @Environment(\.extensionToolbar) private var extensionToolbar

    var body: some View {
        ChromeBarLayout(spacing: Metric.tightGutter, centerMaxWidth: 132 + Metric.tightGutter + 720,
                        centerMinWidth: 420) {
            leadingCluster
            addressCluster
            trailingCluster
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .padding(.vertical, Metric.tightGutter)
        .frame(maxWidth: .infinity)
        .background { TitlebarDragRegion() }
    }

    /// Without the rail nothing else holds the window buttons, so the row
    /// starts clear of them.
    private var leadingCluster: some View {
        HStack(spacing: Metric.tightGutter) {
            if !model.isSidebarVisible {
                Color.clear.frame(width: Metric.windowButtonsWidth - Metric.tightGutter, height: 1)
                SpaceSwitcher(model: model, current: model.currentSpace)
                    .frame(minWidth: 96, maxWidth: 168, alignment: .leading)
            }
        }
    }

    private var addressCluster: some View {
        HStack(spacing: Metric.tightGutter) {
            NavigationControls(model: model)
                .frame(width: 132)
            AddressField(model: model)
                .frame(maxWidth: .infinity)
        }
        .zIndex(2)
    }

    private var trailingCluster: some View {
        HStack(spacing: Metric.tightGutter) {
            if model.isPrivate { ChromeBadge("PRIVATE", tint: Palette.accent) }
            if model.showsFloatVideoControl { FloatVideoButton(model: model) }
            if model.showsVolumeControl { TabVolumeButton(model: model) }
            if let extensionToolbar { extensionToolbar }
            DownloadsButton(model: model)
            BrowserMenu(model: model)
        }
    }
}
