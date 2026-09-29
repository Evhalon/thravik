import RedentDesign
import SwiftUI

/// The address bar: a glass pill that lights up when focused.
struct AddressField: View {
    @Bindable var model: BrowserModel
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: Metric.tightGutter + 1) {
            Image(systemName: securitySymbol)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(securityTint)

            AddressEntryField(model: model, isFocused: $isFocused)

            if model.selectedTab?.url != nil {
                ReaderToggleButton(model: model)
                BookmarkToggleButton(model: model)
            }
            if model.autofill.hasSuggestions {
                AutofillMenu(model: model)
            }
        }
        .padding(.horizontal, Metric.gutter)
        .frame(height: Metric.controlHeight)
        .background { pill.onTapGesture { isFocused = true } }
        .background { reportFrame }
        .overlay(alignment: .bottomLeading) { progressBar }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }

    private var reportFrame: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: AddressFieldFrameKey.self,
                value: geometry.frame(in: .named(AddressFieldFrameKey.space))
            )
        }
    }

    private var pill: some View {
        let shape = RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
        return ZStack {
            shape.fill(.black.opacity(isFocused ? 0.26 : 0.16))
            shape.strokeBorder(
                LinearGradient(
                    colors: isFocused
                        ? [Palette.accent.opacity(0.8), Palette.accent.opacity(0.3)]
                        : [.white.opacity(0.20), .white.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: isFocused ? 1.2 : Metric.hairWidth
            )
        }
        .shadow(color: Palette.accent.opacity(isFocused ? 0.28 : 0), radius: 9)
    }

    @ViewBuilder
    private var progressBar: some View {
        if let tab = model.selectedTab, tab.isLoading {
            GeometryReader { geometry in
                Capsule()
                    .fill(LinearGradient(colors: [Palette.accent.opacity(0.5), Palette.accent],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * tab.progress, height: 2)
                    .animation(.easeOut(duration: 0.25), value: tab.progress)
            }
            .frame(height: 2)
            .padding(.horizontal, 6)
            .padding(.bottom, 1.5)
        }
    }

    private var isSecure: Bool { model.selectedTab?.origin?.scheme == "https" }

    private var securitySymbol: String {
        guard model.selectedTab?.url != nil else { return "magnifyingglass" }
        if model.selectedTab?.pageTrustIssue != nil { return "exclamationmark.triangle.fill" }
        return isSecure ? "lock.fill" : "exclamationmark.triangle.fill"
    }

    private var securityTint: Color {
        guard model.selectedTab?.url != nil else { return Palette.chromeSecondaryText }
        if model.selectedTab?.pageTrustIssue != nil { return Palette.danger }
        return isSecure ? Palette.chromeSecondaryText : Palette.danger
    }
}
