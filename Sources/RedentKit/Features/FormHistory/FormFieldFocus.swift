import CoreGraphics
import Foundation

/// The user is working in a text field that form history can help with.
public struct FormFieldFocus: Sendable, Equatable {
    public let field: FormFieldDescriptor
    /// What the field holds right now; suggestions must start with it.
    public let typed: String
    /// The field's frame in screen coordinates, origin bottom-left.
    public let anchor: CGRect

    public init(field: FormFieldDescriptor, typed: String, anchor: CGRect) {
        self.field = field
        self.typed = typed
        self.anchor = anchor
    }
}
