import RedentDesign
import SwiftUI

struct AccountSignInField: View {
    let placeholder: String
    @Binding var text: String
    var isCode = false
    var isSecure = false
    let onSubmit: () -> Void

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .foregroundStyle(Palette.chromeText)
            .textContentType(isSecure ? .newPassword : isCode ? .oneTimeCode : .emailAddress)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background { chrome }
            .onSubmit(onSubmit)
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(.black.opacity(0.16))
            .overlay {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
            }
    }
}
