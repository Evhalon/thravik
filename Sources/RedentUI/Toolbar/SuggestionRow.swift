import AppKit
import RedentDesign
import RedentKit
import SwiftUI

/// One row of the address bar dropdown: the site's icon, the title with the
/// matched text in bold, where it lives, and — on the lit row — what return
/// will do with it.
struct SuggestionRow: View {
    enum Emphasis { case plain, hovered, active }

    let suggestion: AddressSuggestion
    let query: String
    let emphasis: Emphasis
    let onOpen: (_ commandHeld: Bool) -> Void

    var body: some View {
        HStack(spacing: 9) {
            icon
            VStack(alignment: .leading, spacing: 1) {
                title
                if !suggestion.subtitle.isEmpty {
                    Text(suggestion.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.chromeSecondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            actionHint
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius + 1, style: .continuous)
                .fill(fill)
        }
        .contentShape(.rect)
        .onTapGesture { onOpen(NSEvent.modifierFlags.contains(.command)) }
    }

    private var title: some View {
        HStack(spacing: 5) {
            Text(MatchHighlight.attributed(suggestion.title, matching: query))
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            if suggestion.kind == .bookmark {
                Image(systemName: suggestion.kind.symbol)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Palette.accent)
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        if suggestion.kind == .search {
            Image(systemName: suggestion.kind.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 18, height: 18)
        } else {
            FaviconView(data: suggestion.faviconData, host: Origin(url: suggestion.url)?.displayHost, size: 18)
        }
    }

    /// An open tab always says so — switching is a different act from
    /// loading. Every other row only explains itself once it is lit.
    @ViewBuilder
    private var actionHint: some View {
        if suggestion.kind == .openTab || emphasis == .active {
            HStack(spacing: 4) {
                Text(actionLabel)
                if emphasis == .active { Image(systemName: "return") }
            }
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Palette.chromeSecondaryText)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(Capsule().fill(.white.opacity(emphasis == .active ? 0.10 : 0.06)))
        }
    }

    private var actionLabel: String {
        switch suggestion.kind {
        case .openTab: "Switch to Tab"
        case .search: "Search"
        case .history, .bookmark, .directURL: "Open"
        }
    }

    private var fill: Color {
        switch emphasis {
        case .active: Palette.accent.opacity(0.28)
        case .hovered: .white.opacity(0.07)
        case .plain: .clear
        }
    }
}
