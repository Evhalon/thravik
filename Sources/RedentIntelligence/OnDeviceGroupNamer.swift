import FoundationModels
import RedentKit

/// Names tab groups with Apple Intelligence's on-device model: no network, no
/// account, no cost. Where the model is missing — an unsupported Mac, Apple
/// Intelligence switched off, or the model still downloading — it answers nil
/// and the sidebar keeps the site name.
public struct OnDeviceGroupNamer: TabGroupNaming {
    public init() {}

    public func name(for pages: [TabGroupPage]) async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable, !pages.isEmpty else { return nil }
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let options = GenerationOptions(temperature: 0.2, maximumResponseTokens: 24)
        do {
            let response = try await session.respond(
                to: TabGroupLabel.prompt(for: pages), generating: GeneratedGroupName.self, options: options
            )
            return TabGroupLabel.sanitized(response.content.name)
        } catch {
            return nil
        }
    }

    private static let instructions = """
        You label a group of open browser tabs for a sidebar. Read the tab \
        titles and sites and reply with the shared topic in one to three words, \
        in the language of the titles. Prefer the task over the site name. \
        No quotes, no emoji, no trailing punctuation.
        """
}

@Generable
private struct GeneratedGroupName {
    @Guide(description: "One to three words naming what the tabs have in common")
    let name: String
}
