import Foundation
import RedentKit

/// The form-history menu as it should be on screen right now.
public struct FormSuggestionMenu: Equatable, Sendable {
    public let tabID: UUID
    public let key: FormFieldKey
    /// The field's frame on screen; the menu hangs under it.
    public let anchor: CGRect
    public let items: [String]
    /// What the user has typed so far, for bolding the matched part.
    public let typed: String
    /// -1 when no row is lit.
    public var highlighted: Int = -1
}
