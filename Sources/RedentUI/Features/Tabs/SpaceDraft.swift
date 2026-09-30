import Foundation
import RedentKit

/// A Space being made or reshaped, walked through name → color → icon.
///
/// Held apart from the views so the funnel's rules — when it may advance,
/// what committing it asks of the workspace — can be tested on their own.
struct SpaceDraft: Equatable {
    enum Step: Int, CaseIterable {
        case name
        case color
        case icon

        var title: String {
            switch self {
            case .name: "Name"
            case .color: "Color"
            case .icon: "Icon"
            }
        }
    }

    let original: BrowserSpace?
    var name: String
    var look: SpaceIdentity.Look
    var step: Step = .name

    /// The seed only chooses the opening look, so a new Space starts from
    /// something other than the same color every time.
    static func new(seed: UUID = UUID()) -> SpaceDraft {
        SpaceDraft(original: nil, name: "", look: SpaceIdentity.derived(from: seed))
    }

    static func editing(_ space: BrowserSpace) -> SpaceDraft {
        let look = SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken)
        return SpaceDraft(original: space, name: space.name, look: look)
    }

    var isEditing: Bool { original != nil }
    var isLastStep: Bool { step == Step.allCases.last }
    var isFirstStep: Bool { step == Step.allCases.first }

    var trimmedName: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Every later step needs a name to show in its preview.
    func canReach(_ target: Step) -> Bool {
        target == .name || trimmedName != nil
    }

    mutating func advance() {
        guard let next = Step(rawValue: step.rawValue + 1), canReach(next) else { return }
        step = next
    }

    mutating func retreat() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// Only what changed, so an untouched edit leaves nothing to undo.
    var actions: [BrowserAction] {
        guard let name = trimmedName else { return [] }
        guard let original else { return [.createSpace(name: name, look: look)] }
        var actions: [BrowserAction] = []
        if name != original.name { actions.append(.renameSpace(id: original.id, name: name)) }
        if look != SpaceDraft.editing(original).look {
            actions.append(.setSpaceLook(id: original.id, look: look))
        }
        return actions
    }
}
