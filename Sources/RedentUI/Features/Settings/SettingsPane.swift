/// The sections of the Settings page, in the order the page lists them.
enum SettingsPane: String, CaseIterable, Identifiable {
    case account = "Account"
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case privacy = "Privacy"
    case extensions = "Extensions"
    case updates = "Updates"
    case testing = "Testing"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .account: "person.crop.circle"
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .shortcuts: "keyboard"
        case .privacy: "hand.raised"
        case .extensions: "puzzlepiece.extension"
        case .updates: "arrow.triangle.2.circlepath"
        case .testing: "flask"
        }
    }
}
