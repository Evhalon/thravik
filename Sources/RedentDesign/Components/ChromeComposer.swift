import SwiftUI

/// Create/rename field used by management sheets. A glass pill, not a bezel.
public struct ChromeComposer: View {
    private let placeholder: String
    private let actionTitle: String
    @Binding private var text: String
    private let action: () -> Void

    public init(
        placeholder: String,
        actionTitle: String,
        text: Binding<String>,
        action: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self.actionTitle = actionTitle
        self._text = text
        self.action = action
    }

    public var body: some View {
        HStack(spacing: Metric.tightGutter) {
            field
            submit
        }
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var field: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(Palette.chromeText)
            .padding(.horizontal, 12)
            .frame(height: Metric.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(.black.opacity(0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: Metric.hairWidth)
                    }
            }
            .onSubmit {
                guard canSubmit else { return }
                action()
            }
    }

    private var submit: some View {
        Button(actionTitle, action: action)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(canSubmit ? Color.white : Palette.chromeSecondaryText)
            .padding(.horizontal, 12)
            .frame(height: Metric.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(Palette.accent.opacity(canSubmit ? 0.85 : 0.18))
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canSubmit)
    }
}
