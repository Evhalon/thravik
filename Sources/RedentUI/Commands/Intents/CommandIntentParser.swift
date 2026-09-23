import Foundation
import RedentKit

/// Reads plain commands — "close youtube tabs", "move this tab to Work",
/// "resume Lisbon" — into actions, by keyword and nothing cleverer. The same
/// words always do the same thing, and no text leaves the machine.
///
/// Every reading is a row the user still presses: an intent is a proposal,
/// shown with what it will touch, never an action taken on a guess.
enum CommandIntentParser {
    static func intents(
        for query: String, in context: CommandBarContext, searchEngine: SearchEngine
    ) -> [CommandBarResult] {
        let phrase = CommandPhrase(query)
        guard !phrase.text.isEmpty else { return [] }
        return CloseIntents.parse(phrase, in: context)
            + MoveIntents.parse(phrase, in: context)
            + BrowserIntents.parse(phrase, in: context, searchEngine: searchEngine)
            + ResumeIntents.parse(phrase, in: context)
    }

    static func row(_ title: String, subtitle: String, action: BrowserAction) -> CommandBarResult {
        CommandBarResult(id: "intent:\(action)", title: title, subtitle: subtitle,
                         source: .command, action: action)
    }
}
