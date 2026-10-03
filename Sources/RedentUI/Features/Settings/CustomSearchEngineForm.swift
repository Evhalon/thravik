import RedentDesign
import RedentKit
import SwiftUI

struct CustomSearchEngineForm: View {
    @Binding var settings: BrowserSettings
    @State private var name = ""
    @State private var keyword = ""
    @State private var template = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            field("Name", text: $name, prompt: "YouTube")
            field("Keyword", text: $keyword, prompt: "yt")
            field("URL with %s", text: $template, prompt: "https://www.youtube.com/results?search_query=%s")
            HStack {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.danger)
                }
                Spacer(minLength: Metric.gutter)
                Button("Add Engine", action: add)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeText)
                .frame(width: 88, alignment: .leading)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeText)
                .padding(.horizontal, 12)
                .frame(height: Metric.controlHeight)
                .background {
                    RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                        .fill(Palette.chromeFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                                .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
                        }
                }
        }
    }

    private func add() {
        switch CustomSearchEngine.make(
            name: name, keyword: keyword, template: template, existing: settings.customSearchEngines
        ) {
        case .success(let engine):
            settings.addCustomSearchEngine(engine)
            name = ""
            keyword = ""
            template = ""
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.message
        }
    }
}
