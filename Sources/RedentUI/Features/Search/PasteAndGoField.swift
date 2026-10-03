import Foundation

/// Which browser search field owns Paste and Go. A web page keeps this nil
/// so ⌘⇧V stays a plain paste inside the document.
enum PasteAndGoField: Equatable {
    case address
    case floatingNewTab
    case newTabPage
}
