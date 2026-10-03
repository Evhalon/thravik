import Foundation
import RedentKit

extension WebTab {
    public func setCustomEmoji(_ raw: String?) {
        let emoji: String?
        if let raw {
            guard let valid = TabCustomEmoji.validated(raw) else { return }
            emoji = valid
        } else {
            emoji = nil
        }
        guard snapshot.customEmoji != emoji else { return }
        if let controller {
            try? controller.perform(.setCustomEmoji(id: id, emoji: emoji))
        } else {
            snapshot.customEmoji = emoji
        }
    }
}
