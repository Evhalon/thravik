# Thravik

A native macOS browser. Glass chrome, Dia-style tabs, saved passwords, and a
floating button that fills your Google Authenticator code when a site asks for it.

Built on **system WebKit**, not Chromium. There is no browser engine inside the
app bundle — macOS already ships one, and it is already resident. The whole app
is a few megabytes, and a background tab costs nothing once it hibernates.

## Why not Chromium

| | Chromium-based (Electron/CEF) | Thravik |
|---|---|---|
| Engine in the bundle | ~150–250 MB | 0 — uses the system's |
| Cold app footprint | Hundreds of MB | Single-digit MB |
| Idle background tab | A live renderer process | Torn down; a snapshot remains |
| GPU / compositing | Own stack | Shared with the OS |
| Security updates | Ship a new build | Arrive with macOS |

## Features

- **Liquid Glass chrome** — real `glassEffect`, not a blur image.
- **Tabs where you want them** — a vertical rail like Dia, or a horizontal strip
  like Chrome. `⌘B` collapses and restores the sidebar; `⌘⇧F`
  removes the chrome entirely. Drag the seam to resize.
- **A clean top edge** — Settings → Appearance → Hide top navigation bar moves
  navigation and the address field into the sidebar. Collapse it with `⌘B` for
  a full-height page; hover the left edge for the sidebar or the top edge for
  navigation. Both slide over the page and hide when you move away. `⌘B` keeps
  the sidebar open, and `⌘L` brings its address field back.
- **Tab hibernation** — idle background tabs release their web view and their
  content process. Configurable: never / 15 min / 3 min.
- **Floating video** — click Float video over the video, use its navigation
  button (including sidebar navigation), or press `⌃⌘V` for a
  main-page HTML5 video. The original player stays alive above other windows.
  Drag it, or swipe with two fingers with amplified movement and flick to throw
  it into a smooth decelerating glide across connected displays.
  Click-and-drag keeps the pointer visible.
  Two-finger dragging hides and carries the pointer, with a haptic pickup and a
  small lift while held. Drag the corner grip to resize without stretching.
  The player animates out from its position on the page and back when returned.
  Hover for Liquid Glass controls, including a timeline, volume, mute, pause,
  close, and return. Embedded iframe players keep
  their site's native picture-in-picture controls.
- **Passwords in the Keychain** — offered on submit, filled on request, matched
  by registrable domain so a lookalike host never sees your credentials.
  Autofill never submits the form.
- **Native passkeys** — WebKit uses the macOS passkey picker for website sign-in
  and registration. Settings → Privacy → Passkeys shows access and lets you
  grant permission. Requires an Apple-approved browser provisioning profile;
  ordinary local builds show that saved passkeys are unavailable. See
  [passkey setup](docs/PASSKEYS.md).
- **Google Authenticator import** — scan the export QR with the camera, drop a
  screenshot of it, or paste the payload. Multi-QR batched exports accumulate.
- **Floating code button** — when a page shows a one-time-code field, a glass
  capsule appears with the live code and a countdown ring. One press fills it.
- **Tracker blocking** — a compiled `WKContentRuleList`, on by default.
- **Import from Comet** (and Chrome, Brave, Edge, Arc, Vivaldi, Dia) — history,
  bookmarks and saved passwords, read straight from the local profile. Nothing
  leaves the Mac.
- **Bookmarks and favorites** — starred pages appear on the new-tab grid.
- **Address bar suggestions** — bookmarks and history ranked by frecency, with a
  direct-open row for anything that parses as an address. Query strings are
  stripped before history is ever written.
- **New-tab page** — greeting, search field, and the sites you actually use,
  each tile lit by its own favicon's color.

## Build

```
make app     # builds and bundles dist/Thravik.app
make run     # builds, bundles, launches
make verify  # line limits + architecture rules + build + tests
```

Use `make run` for local development. It signs every rebuild with the same
local identity, so passwords, authenticator accounts, cookies and permissions
survive subsequent runs. `swift run` bypasses that identity and is unsupported.

Every push to `main` builds and publishes a new unnotarized GitHub release.
Release setup is documented in [docs/RELEASING.md](docs/RELEASING.md).

Requires macOS 26 and Xcode 26.

## Architecture

Product direction and phased implementation: [Product roadmap](docs/PRODUCT_ROADMAP.md).
The strategic core is Command Bar + Spaces + Tabs + Smart History.

Dependencies point inward. See [AGENTS.md](AGENTS.md) for the rules every change
must satisfy, and [docs/CONTRACTS.md](docs/CONTRACTS.md) for the boundaries
between targets.

Code is grouped by feature inside each target, with shared helpers and application
wiring kept together. See [Source organization](docs/CODE_STRUCTURE.md).

```
Redent          composition root — the only place concrete types are named
RedentUI        views + view models, talking to ports
RedentEngine    the only target that imports WebKit
RedentDesign    glass, tokens, primitives
RedentVault     Keychain, history (SQLite) and bookmark (JSON) adapters
RedentImport    Chromium profile reader — history, bookmarks, password decryption
RedentOTPAuth   otpauth:// and Google's otpauth-migration:// protobuf
RedentCrypto    Base32, HMAC, HOTP, TOTP — pure, RFC-tested
RedentKit       domain models and ports. Foundation only.
```

No file exceeds 150 lines. `make verify` enforces it.

## Privacy

Passwords and TOTP seeds live in the login Keychain and nowhere else. Nothing is
synced, uploaded, or telemetered. Page content never reaches a log line.
