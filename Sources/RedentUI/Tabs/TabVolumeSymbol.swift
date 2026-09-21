/// One speaker glyph for a tab's audio state, shared by the tab badge and the
/// toolbar control so the two never disagree.
enum TabVolumeSymbol {
    static func name(muted: Bool, level: Double) -> String {
        if muted || level == 0 { return "speaker.slash.fill" }
        if level < 0.34 { return "speaker.wave.1.fill" }
        if level < 0.67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}
