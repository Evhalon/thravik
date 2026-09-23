import Foundation
import RedentKit

/// A command definition. The action builder keeps contextual IDs out of the
/// registry and lets the composition root inject additional commands.
public struct CommandDescriptor: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let keywords: [String]
    public let symbol: String
    private let buildAction: @Sendable (CommandBarContext, String) -> BrowserAction?
    /// Set for a command that needs an argument: pressing it types this into
    /// the field so the argument can be picked from the rows that follow.
    public let completion: String?

    public init(
        id: String,
        title: String,
        keywords: [String] = [],
        symbol: String = "command",
        action: @escaping @Sendable (CommandBarContext, String) -> BrowserAction?
    ) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.symbol = symbol
        self.buildAction = action
        self.completion = nil
    }

    /// A command that asks for its argument instead of running.
    public init(id: String, title: String, keywords: [String] = [], symbol: String = "command", completion: String) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.symbol = symbol
        self.buildAction = { _, _ in nil }
        self.completion = completion
    }

    public func action(in context: CommandBarContext, query: String = "") -> BrowserAction? {
        buildAction(context, query)
    }

    /// The row this command shows, or nil when it does not apply right now.
    func row(in context: CommandBarContext, query: String) -> CommandBarResult? {
        let action = action(in: context, query: query)
        guard action != nil || completion != nil else { return nil }
        var row = CommandBarResult(id: "command:\(id)", title: title, subtitle: "Command",
                                   source: .command, action: action)
        row.symbol = symbol
        row.completion = completion
        return row
    }

    func matches(_ query: String) -> Bool {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return true }
        let haystack = ([title] + keywords).joined(separator: " ").lowercased()
        let terms = text.split(separator: " ")
        let titleTerms = title.lowercased().split(separator: " ")
        let startsWithTitle = terms.count >= titleTerms.count
            && zip(terms, titleTerms).allSatisfy { $0 == $1 }
        return startsWithTitle || terms.allSatisfy { haystack.contains($0) }
            || FuzzyMatch.matches(text, fields: [title] + keywords)
    }
}

enum CommandArguments {
    static func after(_ prefix: String, in query: String) -> String? {
        guard query.lowercased().hasPrefix(prefix) else { return nil }
        let value = String(query.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
