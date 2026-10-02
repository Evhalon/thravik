import RedentDesign
import RedentKit
import SwiftUI

struct FindBar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
                .accessibilityHidden(true)
            FindEntryField(model: model)
            counter
            stepper(symbol: "chevron.up", label: "Previous match") { model.findNext(forward: false) }
            stepper(symbol: "chevron.down", label: "Next match") { model.findNext(forward: true) }
            closeButton
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.vertical, Metric.tightGutter)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous))
        .onExitCommand(perform: model.closeFindBar)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Find on page")
    }

    private var closeButton: some View {
        Button(action: model.closeFindBar) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel("Close find on page")
        .help("Close (Esc)")
    }

    private func stepper(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(model.chrome.findQuery.isEmpty || model.chrome.findMatches?.isEmpty == true)
        .accessibilityLabel(label)
        .help(label == "Next match" ? "Next match (Return / ⌘G)" : "Previous match (⇧Return / ⇧⌘G)")
    }

    @ViewBuilder private var counter: some View {
        if let matches = model.chrome.findMatches, !model.chrome.findQuery.isEmpty {
            Text(matches.isCountExact ? "\(matches.current)/\(matches.total)" : "Match found")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(matches.isEmpty ? Palette.danger : Palette.chromeSecondaryText)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.18), value: matches)
                .fixedSize()
                .accessibilityLabel(counterDescription(matches))
        }
    }

    private func counterDescription(_ matches: FindMatches) -> String {
        guard !matches.isEmpty else { return "No matches" }
        guard matches.isCountExact else { return "Match found" }
        return "\(matches.current) of \(matches.total) matches"
    }
}
