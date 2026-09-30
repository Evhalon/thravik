/// The sections of the Settings page, in the order the page lists them.
enum SettingsPane: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case privacy = "Privacy"
    case updates = "Updates"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .privacy: "hand.raised"
        case .updates: "arrow.triangle.2.circlepath"
        }
    }
}
