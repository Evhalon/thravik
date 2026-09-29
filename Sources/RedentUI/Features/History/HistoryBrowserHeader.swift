import RedentDesign
import SwiftUI

/// The top of the history sheet: title, the search that is focused the moment
/// the sheet opens, and whether to look beyond the current Space.
struct HistoryBrowserHeader: View {
    @Binding var query: String
    @Binding var allSpaces: Bool
    let subtitle: String
    let onKey: (KeyPress) -> KeyPress.Result
    let onDone: () -> Void
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: Metric.gutter) {
            HStack(alignment: .firstTextBaseline) {
                SheetHeading(title: "History", subtitle: subtitle)
                Spacer()
                Picker("Scope", selection: $allSpaces) {
                    Text("This Space").tag(false)
                    Text("All Spaces").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Button("Done", action: onDone)
                    .keyboardShortcut(.cancelAction)
            }
            searchField
        }
        .padding(Metric.gutter + 2)
        .onAppear { isSearchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
            TextField("Search pages you have visited", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)
                .onKeyPress(action: onKey)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Palette.chromeFill, in: .rect(cornerRadius: Metric.mediumRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .strokeBorder(isSearchFocused ? Palette.accent.opacity(0.6) : Palette.hairline, lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.15), value: isSearchFocused)
    }
}
