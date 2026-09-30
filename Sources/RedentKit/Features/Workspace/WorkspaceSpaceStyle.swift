import Foundation

/// What a Space is called, how it looks and where it sits in the order —
/// split out of `WorkspaceState.swift`.
extension WorkspaceState {
    mutating func applySpaceStyle(_ action: WorkspaceAction) throws {
        switch action {
        case let .createSpace(name, look): createSpace(name: name, look: look)
        case let .renameSpace(id, name):
            let index = try spaceIndex(id)
            guard let trimmed = Self.trimmedName(name) else { return }
            session.spaces[index].name = trimmed
        case let .setSpaceLook(id, look):
            let index = try spaceIndex(id)
            session.spaces[index].icon = look.icon
            session.spaces[index].colorToken = look.colorToken
        case let .moveSpace(id, toIndex):
            let index = try spaceIndex(id)
            let space = session.spaces.remove(at: index)
            session.spaces.insert(space, at: min(max(toIndex, 0), session.spaces.count))
        default:
            return
        }
    }

    private mutating func createSpace(name: String, look: SpaceIdentity.Look?) {
        guard let trimmed = Self.trimmedName(name) else { return }
        var space = BrowserSpace(name: trimmed)
        if let look {
            space.icon = look.icon
            space.colorToken = look.colorToken
        }
        session.spaces.append(space)
    }

    private func spaceIndex(_ id: UUID) throws -> Int {
        guard let index = session.spaces.firstIndex(where: { $0.id == id }) else {
            throw WorkspaceActionError.missingSpace(id)
        }
        return index
    }

    private static func trimmedName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
