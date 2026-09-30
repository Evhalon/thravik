import Foundation
import RedentKit

/// Reads form-history messages from `redent-form-history.js`. Everything in
/// them came from the page: sizes are capped and malformed messages dropped.
enum FormSignalParser {
    enum Parsed {
        case ready(PageSignal)
        /// Still in the page's CSS pixels; only the tab knows where that is on screen.
        case active(FormFieldDescriptor, typed: String, pageRect: CGRect)

        @MainActor
        func resolve(in tab: WebTab) -> PageSignal? {
            switch self {
            case .ready(let signal):
                return signal
            case .active(let field, let typed, let pageRect):
                guard let anchor = tab.screenRect(forPageRect: pageRect) else { return nil }
                return .formFieldActive(FormFieldFocus(field: field, typed: typed, anchor: anchor))
            }
        }
    }

    private static let maximumEntries = 64

    static func parse(_ body: Any) -> Parsed? {
        guard let dict = body as? [String: Any], let type = dict["type"] as? String else { return nil }
        switch type {
        case "formFieldActive":
            guard let rect = rect(dict["rect"]) else { return nil }
            return .active(descriptor(dict), typed: text(dict["typed"]), pageRect: rect)
        case "formFieldInactive":
            return .ready(.formFieldInactive)
        case "formSuggestionHighlighted":
            return (dict["index"] as? Int).map { .ready(.formSuggestionHighlighted(index: $0)) }
        case "formSuggestionChosen":
            return (dict["index"] as? Int).map { .ready(.formSuggestionChosen(index: $0)) }
        case "formSubmitted":
            guard let entries = dict["entries"] as? [[String: Any]] else { return nil }
            let values = entries.prefix(maximumEntries).map {
                FormFieldValue(field: descriptor($0), value: text($0["value"]))
            }
            return .ready(.formSubmitted(values))
        default:
            return nil
        }
    }

    private static func descriptor(_ dict: [String: Any]) -> FormFieldDescriptor {
        FormFieldDescriptor(
            autocomplete: text(dict["autocomplete"]),
            type: text(dict["inputType"]),
            name: text(dict["name"]),
            identifier: text(dict["identifier"])
        )
    }

    private static func text(_ raw: Any?) -> String {
        String((raw as? String ?? "").prefix(FormEntry.maximumLength))
    }

    private static func rect(_ raw: Any?) -> CGRect? {
        guard let dict = raw as? [String: Any],
              let x = (dict["x"] as? NSNumber)?.doubleValue, let y = (dict["y"] as? NSNumber)?.doubleValue,
              let width = (dict["width"] as? NSNumber)?.doubleValue,
              let height = (dict["height"] as? NSNumber)?.doubleValue,
              [x, y, width, height].allSatisfy(\.isFinite), width > 0, height > 0
        else { return nil }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
