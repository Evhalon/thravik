import Foundation

/// Builds the shell script that swaps the app in after this process exits.
///
/// The swap cannot happen in-process: the running app *is* the bundle being
/// replaced. So a detached `/bin/sh` waits for our PID to disappear, moves the
/// old bundle aside, copies the new one in, and reopens it. Every failure path
/// restores the old bundle and reopens that instead — the user must never be
/// left with no browser.
enum RelaunchScript {
    static func source(stagedApp: URL, target: URL, pid: Int32) -> String {
        let staged = quoted(stagedApp.path)
        let destination = quoted(target.path)
        return """
        #!/bin/sh
        staged=\(staged)
        target=\(destination)
        backup="$target.previous"

        while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done

        rm -rf "$backup"
        if ! mv "$target" "$backup"; then
          open "$target"
          exit 1
        fi
        if ditto "$staged" "$target"; then
          rm -rf "$backup"
        else
          rm -rf "$target"
          mv "$backup" "$target"
        fi
        rm -rf "$staged"
        open "$target"
        """
    }

    /// Single-quoting is the only POSIX form with no escapes inside it, so a
    /// path containing quotes or spaces cannot break out into a command.
    private static func quoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
