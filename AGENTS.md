# Redent — Agent Contract

Redent is a native macOS browser. Fast, quiet, glass. No Chromium.

Product target: Command Bar + Spaces + Tabs + Smart History form the strategic
core. Follow `docs/PRODUCT_ROADMAP.md` for the complete fourteen-feature target,
code reuse, dependencies, migrations, and phased acceptance gates. Implement
incrementally; later milestones remain required product scope. Roadmap proposals
do not imply that their features or architectural changes already exist.

Every agent working in this repo MUST follow the rules below. They are not
suggestions. Code that violates them is rejected and rewritten.

---

## 1. Hard limits

| Rule | Limit |
|---|---|
| Lines per Swift file | **150 max**, including imports and comments |
| Types per file | **1 primary type** (plus its private helpers) |
| Function length | 40 lines max |
| Function parameters | 5 max — beyond that, pass a struct |
| Nesting depth | 3 max |
| Cyclomatic branches per function | Keep it flat. Early-return, don't pyramid. |

If a file approaches 150 lines, **split it** — by responsibility, not by
arbitrary line count. `FooView.swift` + `FooView+Layout.swift` is a smell;
`TabStrip.swift` + `TabStripItem.swift` is correct.

## 2. Clean architecture — dependency rule

Dependencies point **inward only**. An inner layer never imports an outer one.

```
        Redent (executable / composition root)
                      │
                  RedentUI            ← SwiftUI views, view models
              ┌───────┴────────┐
        RedentEngine      RedentDesign ← WebKit adapters / design system
        RedentVault
        RedentOTPAuth
              │
        RedentCrypto                   ← pure algorithms
              │
          RedentKit                    ← domain: models + ports. Zero platform deps.
```

- **RedentKit** — domain models and *ports* (protocols). Imports `Foundation` only.
  No `SwiftUI`, no `WebKit`, no `AppKit`, no `Security`.
- **RedentCrypto** — pure functions: Base32, HMAC, HOTP/TOTP. Deterministic,
  no I/O, no clock reads (time is injected).
- **RedentOTPAuth** — `otpauth://` and `otpauth-migration://` parsing. Pure.
- **RedentVault** — Keychain adapters that *implement* RedentKit ports.
- **RedentEngine** — WKWebView adapters. The only target allowed to `import WebKit`.
- **RedentDesign** — tokens, materials, reusable primitives. No feature logic.
- **RedentUI** — feature views + view models. Talks to ports, never to concrete adapters.
- **Redent** — the only place that constructs concrete types and wires them together.

**Consequence:** a view model never says `KeychainCredentialStore()`. It takes a
`any CredentialStoring` in its initializer. The composition root decides which.

## 3. Swift style — write like a staff engineer

- Swift 6, strict concurrency. `@MainActor` on UI types; `actor` or `Sendable`
  value types across boundaries. **Zero** `@unchecked Sendable` without a
  one-line comment justifying it.
- `struct` by default. `final class` when reference semantics are genuinely
  required (WebKit interop, `Observable` view models).
- No force unwraps (`!`), no `try!`, no `as!` in non-test code. Ever.
  `guard let … else { return }` or a typed error.
- Errors are typed enums conforming to `Error`. Never `NSError`, never
  stringly-typed failures.
- `private` is the default access level. Widen only when a caller needs it.
- Name things for the reader: `hibernatedTabIDs`, not `tmp`, `data2`, `mgr`.
- No singletons except `Logger`. No global mutable state.
- Comments explain **why**, never **what**. If a comment restates the code,
  delete the comment. If the code needs a comment to be understood, rewrite
  the code first.
- No dead code, no commented-out code, no `TODO` without an owner and reason.
- Prefer `some View` and small view bodies. A `body` over 30 lines must be
  decomposed into child views or computed properties.

## 4. Performance is a feature, not a phase

This browser exists because Chromium is heavy. Behave accordingly.

- One shared `WKWebsiteDataStore`. Never one data store per tab.
- Background tabs **hibernate**: after the idle threshold, tear down the
  `WKWebView`, keep a lightweight snapshot + restore state. This is the single
  biggest memory win — do not regress it.
- Never hold a strong reference from a WebKit delegate back to a view model
  without breaking the cycle. Retain cycles here leak whole web processes.
- No polling timers for state that WebKit publishes via KVO.
- One timer drives all TOTP countdowns — not one timer per code.
- Do not block the main actor. Parsing, crypto, and Keychain I/O run off-main.
- Measure before optimizing, but never ship an obvious O(n²) over tabs.

## 5. Security is not optional

- Secrets (passwords, TOTP seeds) live in the **Keychain**, never in
  `UserDefaults`, never on disk in plaintext, never in a log line.
- TOTP seeds are `Data`, zeroed after use where the API permits. Never `String`.
- Never log a URL's query string, a form value, or anything from a page.
- Injected JavaScript runs in an isolated content world
  (`WKContentWorld.world(name:)`), never `.page`.
- Autofill **never** auto-submits a form. The user presses the button.
- Credentials are matched by **eTLD+1 origin**, never by substring.

## 6. Testing

- Every pure algorithm in `RedentCrypto` and `RedentOTPAuth` has tests,
  including the RFC 4226 / RFC 6238 published vectors.
- Bug fix ⇒ regression test in the same change.
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`).
- UI is not unit-tested; view models are.

## 7. Definition of done

A change is done when **all** of these hold:

1. `swift build` succeeds with **zero warnings**.
2. `swift test` passes.
3. No file exceeds 150 lines: `make check-lines` is clean.
4. The dependency rule in §2 is unviolated.
5. No force unwraps, no dead code, no stray print statements.

Run `make verify` before declaring completion. If it fails, you are not done.
