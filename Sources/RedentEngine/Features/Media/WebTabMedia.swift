import RedentKit
import WebKit

/// Tab audio: which frames are making sound, and the user's mute and volume.
/// Both belong to the tab, not the page, so they survive navigating to a new site.
extension WebTab {
    /// A page could post as many frame IDs as it likes; past this many the set
    /// stops growing rather than letting it inflate native memory.
    private static let audibleFrameLimit = 64

    public func setMuted(_ muted: Bool) {
        isMuted = muted
        applyAudio()
    }

    /// Scales every player in the page, from silent up to the page's own level.
    public func setVolume(_ level: Double) {
        let clamped = level.isFinite ? min(max(level, 0), 1) : 1
        guard clamped != volume else { return }
        volume = clamped
        applyAudio()
    }

    func mediaFrame(_ frame: String, isAudible: Bool) {
        if isAudible {
            guard audibleFrames.count < Self.audibleFrameLimit else { return }
            let isNewFrame = audibleFrames.insert(frame).inserted
            // A frame created after the mute or volume change has not heard it yet.
            if isNewFrame, isAdjusted { applyAudio() }
        } else {
            audibleFrames.remove(frame)
        }
        isPlayingAudio = !audibleFrames.isEmpty
    }

    /// Called as a new main-frame document starts: the old page's frames are gone.
    func resetMediaFrames() {
        audibleFrames.removeAll()
        isPlayingAudio = false
        if isAdjusted { applyAudio() }
    }

    private var isAdjusted: Bool { isMuted || volume < 1 }

    private func applyAudio() {
        guard let webView else { return }
        let script = """
        if (typeof window.redentSetAudio === 'function') { window.redentSetAudio(\(isMuted), \(volume)); }
        """
        webView.evaluateJavaScript(script, in: nil, in: PageScripts.contentWorld) { _ in }
    }
}
