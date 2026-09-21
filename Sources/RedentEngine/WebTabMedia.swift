import RedentKit
import WebKit

/// Tab audio: which frames are making sound, and the user's mute. The mute
/// belongs to the tab, not the page, so it survives navigating to a new site.
extension WebTab {
    /// A page could post as many frame IDs as it likes; past this many the set
    /// stops growing rather than letting it inflate native memory.
    private static let audibleFrameLimit = 64

    public func setMuted(_ muted: Bool) {
        isMuted = muted
        applyMute()
    }

    func mediaFrame(_ frame: String, isAudible: Bool) {
        if isAudible {
            guard audibleFrames.count < Self.audibleFrameLimit else { return }
            let isNewFrame = audibleFrames.insert(frame).inserted
            // A frame created after the mute has not heard it yet.
            if isNewFrame, isMuted { applyMute() }
        } else {
            audibleFrames.remove(frame)
        }
        isPlayingAudio = !audibleFrames.isEmpty
    }

    /// Called as a new main-frame document starts: the old page's frames are gone.
    func resetMediaFrames() {
        audibleFrames.removeAll()
        isPlayingAudio = false
        if isMuted { applyMute() }
    }

    private func applyMute() {
        guard let webView else { return }
        let script = """
        if (typeof window.redentSetMuted === 'function') { window.redentSetMuted(\(isMuted)); }
        """
        webView.evaluateJavaScript(script, in: nil, in: PageScripts.contentWorld) { _ in }
    }
}
