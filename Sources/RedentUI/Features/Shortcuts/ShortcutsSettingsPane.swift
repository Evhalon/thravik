import AppKit
import RedentDesign
import RedentKit
import SwiftUI

struct ShortcutsSettingsPane: View {
    @Binding var settings: BrowserSettings
    @State private var recordingID: ShortcutID?
    @State private var conflict: PendingShortcutConflict?
    @State private var showsReserved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            restoreAll
            ShortcutBindingsList(
                bindings: settings.shortcutBindings,
                recordingID: $recordingID,
                onRestore: restore
            )
        }
        .background {
            if recordingID != nil {
                ShortcutCaptureHost(onEvent: handleEvent)
                    .frame(width: 1, height: 1)
            }
        }
        .alert("Shortcut in use", isPresented: conflictPresented) {
            Button("Cancel", role: .cancel) { conflict = nil }
            Button("Reassign", action: reassign)
        } message: {
            Text(conflict?.message ?? "")
        }
        .alert("Reserved shortcut", isPresented: $showsReserved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("That key is reserved by macOS, the Edit menu, or the numbered tab and Space keys.")
        }
    }

    private var restoreAll: some View {
        HStack {
            Text("Menu and context-menu keys. Numbered tabs stay ⌘1–9.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
            Spacer(minLength: Metric.gutter)
            Button("Restore Defaults") { settings.shortcutBindings.restoreAllDefaults() }
        }
    }

    private var conflictPresented: Binding<Bool> {
        Binding(get: { conflict != nil }, set: { if !$0 { conflict = nil } })
    }

    private func handleEvent(_ event: NSEvent) {
        if KeyChordFromEvent.isEscape(event) { recordingID = nil; return }
        if KeyChordFromEvent.isClear(event) { apply(nil); return }
        guard let chord = KeyChordFromEvent.make(from: event) else { return }
        apply(chord)
    }

    private func apply(_ chord: KeyChord?) {
        guard let id = recordingID else { return }
        recordingID = nil
        present(settings.shortcutBindings.setChord(chord, for: id), id: id, chord: chord)
    }

    private func restore(_ id: ShortcutID) {
        recordingID = nil
        let change = settings.shortcutBindings.restoreDefault(for: id)
        present(change, id: id, chord: ShortcutBindings.defaults[id])
    }

    private func present(_ change: ShortcutChange, id: ShortcutID, chord: KeyChord?) {
        switch change {
        case .applied: break
        case .reserved: showsReserved = true
        case .conflict(let others):
            if let chord { conflict = PendingShortcutConflict(id: id, chord: chord, others: others) }
        }
    }

    private func reassign() {
        guard let conflict else { return }
        settings.shortcutBindings.reassign(conflict.chord, to: conflict.id)
        self.conflict = nil
    }
}
