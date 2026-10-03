import RedentKit

struct PendingShortcutConflict: Equatable {
    var id: ShortcutID
    var chord: KeyChord
    var others: [ShortcutID]

    var message: String {
        let names = others.map(\.title).joined(separator: ", ")
        return "\(chord.displayString) is used by \(names). Reassign it?"
    }
}
