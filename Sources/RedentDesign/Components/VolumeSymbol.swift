/// Shared by volume controls so the same level always shows the same speaker glyph.
public enum VolumeSymbol {
    public static func name(muted: Bool, level: Double) -> String {
        if muted || level == 0 { return "speaker.slash.fill" }
        if level < 0.34 { return "speaker.wave.1.fill" }
        if level < 0.67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}
