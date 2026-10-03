import Foundation

/// A tab's name and pinned page — what the user says about a tab rather than
/// where it sits — split out of `WorkspaceState.swift`.
extension WorkspaceState {
    mutating func applyTabLabel(_ action: WorkspaceAction) throws {
        switch action {
        case let .renameTab(id, title):
            let index = try tabIndex(id)
            let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            session.tabs[index].customTitle = trimmed.isEmpty ? nil : trimmed
        case let .setPinnedURL(id, url):
            let index = try tabIndex(id)
            guard session.tabs[index].isPinned else { return }
            session.tabs[index].pinnedURL = url
        case let .setCustomEmoji(id, emoji):
            try applyCustomEmoji(id, emoji)
        default:
            return
        }
    }

    private mutating func applyCustomEmoji(_ id: UUID, _ emoji: String?) throws {
        let index = try tabIndex(id)
        if let emoji {
            guard let valid = TabCustomEmoji.validated(emoji) else { return }
            session.tabs[index].customEmoji = valid
        } else {
            session.tabs[index].customEmoji = nil
        }
    }

    private func tabIndex(_ id: UUID) throws -> Int {
        guard let index = session.tabs.firstIndex(where: { $0.id == id }) else {
            throw WorkspaceActionError.missingTab(id)
        }
        return index
    }
}
