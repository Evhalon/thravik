import AppKit

/// Copies a secret to the general pasteboard, marked so well-behaved
/// clipboard managers (Alfred, Maccy, Pastebot, …) skip recording it.
///
/// There's no first-party AppKit API for "don't remember this" — the
/// convention, documented at nspasteboard.org, is that an app writes an
/// extra, valueless pasteboard type alongside the real one and clipboard
/// history tools that respect it simply don't persist the item.
enum ConcealedPasteboard {
    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    static func copy(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        pasteboard.setData(Data(), forType: concealedType)
    }
}
