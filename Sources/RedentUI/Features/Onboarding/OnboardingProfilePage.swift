import RedentDesign
import SwiftUI

struct OnboardingProfilePage: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Make yourself at home.")
                .font(.system(size: 32, weight: .medium, design: .rounded))
            Text("A little about you. A browser that feels like yours.")
                .foregroundStyle(Palette.chromeSecondaryText)
            TextField("What should we call you?", text: $model.displayName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { model.advance() }
            Picker("Your main focus", selection: $model.purpose) {
                ForEach(["Personal", "Work", "Study", "Exploring"], id: \.self) { Text($0).tag($0) }
            }
            Text("Your name and focus stay in your workspace; cloud sync encrypts them.")
                .font(.caption).foregroundStyle(Palette.chromeSecondaryText)
            HStack {
                Button("Back") { model.back() }
                Spacer()
                Button("Continue") { model.advance() }
                    .buttonStyle(.borderedProminent).disabled(!model.canContinue)
            }
        }
    }
}
