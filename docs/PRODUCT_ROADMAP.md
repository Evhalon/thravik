# Redent product implementation roadmap

Target: evolve this existing Swift/WebKit browser around **Command Bar + Spaces + Tabs + Smart History**. All fourteen requested capabilities belong to the target product. Milestones below sequence implementation; later placement does not remove scope.

Scope: planning and source audit, not feature implementation. Status means code present in this checkout, not interactive validation. Baseline: Swift 6, macOS 26 minimum, system WebKit, no external package dependencies (`Package.swift`).

Baseline verification (2026-09-06): `make verify` passed with normal Swift cache access; release/debug builds completed without warnings in that run, 166 Swift Testing tests across 39 suites passed, line/import/force-try-cast checks passed. Initial sandboxed attempt failed on cache permissions, not application compilation. No application code changed for this roadmap.

## Existing foundation and concrete gaps

| Evidence | Present behavior | Product consequence |
|---|---|---|
| `Sources/RedentEngine/TabController.swift`, `TabControllerOrdering.swift` | Flat tab array, one selected ID, pinning, ordering API, ten-entry in-memory reopen stack | Preserve behavior; separate workspace ownership from web-view lifecycle before Spaces/groups |
| `Sources/RedentKit/Models/TabSnapshot.swift` | URL/title/favicon/pin/activity; `BrowserSession` contains tabs and selection | No Space, Container, group, window, lifespan, or timeline identity |
| `Sources/RedentVault/CodableStore.swift` | One JSON session in UserDefaults; decode failure falls back to empty session | Versioned migration and recoverable storage errors needed before schema expansion |
| `Sources/Redent/AppContainer.swift`, `RedentApp.swift`, `AppDelegate.swift` | App-level container/model shared through `WindowGroup`; save on termination | Multiple independent browser windows are not modeled; closed-window restore cannot yet work correctly |
| `Sources/RedentUI/Model/BrowserModel.swift` | Concrete `TabController` and `WebTab` references; per-second tick drives address/history observation | Existing ports rule is incomplete in practice; expose domain state/events and inject rendering |
| `Sources/RedentUI/Model/SuggestionEngine.swift`, `AddressSuggestionsModel.swift` | Debounced history/bookmark suggestions, direct navigation, search-engine fallback | Strong reuse for Command Bar; URL-only results cannot execute commands or select existing entities |
| `Sources/RedentVault/History/HistoryDatabase.swift`, `HistoryRanking.swift` | URL-unique aggregate rows, title/URL/host LIKE matching, frecency; unordered candidate limit 200 | Existing baseline is useful, but misses contextual visits and can exclude stronger matches before ranking |
| `Sources/RedentUI/Model/VisitRecorder.swift` | Polls selected settled tab; one URL/title fingerprint | Background navigation missed; switching tabs can change counts; no navigation-event identity |
| `Sources/RedentEngine/TabHibernation.swift` | Releases WKWebView; wakes by loading last URL; selected/pinned tabs exempt | No screenshot or full navigation-state capture today; preserve teardown and avoid claiming exact restoration |
| `Sources/RedentEngine/WebViewFactory.swift` | Static default website-data store | Existing shared cookies must survive migration; isolation requires explicit context lookup |
| `Sources/RedentEngine/WebTabDelegate.swift` | `_blank` opens URL through `newTab`; supplied configuration is ignored | Must propagate context and validate popup/opener behavior before Containers ship |
| `Sources/RedentUI/Shell/BrowserCommands.swift`, `BrowserWindowView.swift` | Native menus; new/close/reopen/tab switching; Focus Mode shortcut | Extend existing menu infrastructure; Focus Mode already implemented |
| `Sources/RedentEngine/ContentBlocker.swift`, `RedentUI/Settings/PrivacySettingsPane.swift` | Global tracker-blocking setting; no site dashboard | Reuse rule compiler, add scoped settings and truthful capability reporting |

Tests already cover crypto, OTP parsing, imports, history/bookmark stores, suggestions, autofill, and OTP coordination. `Package.swift` has no Engine test target. No dedicated workspace, undo, timeline, or browser-window lifecycle coverage exists.

## Architecture decisions for this target

These are implementation defaults for the roadmap. Existing runtime code remains unchanged.

1. **Space = persistent workflow context.** Owns ordered tabs/groups, remembered selection, and default Container. Work, Personal, Research, Travel are editable starter Spaces; custom Spaces use the same model. Switching preserves each Space's context. Space does not automatically mean a separate login session.
2. **Container = website-data boundary.** Default Container retains `WKWebsiteDataStore.default()` and existing cookies. Named Containers use stable UUID-backed stores. Tabs sharing a Container share its store; never create persistent stores per tab. Temporary private sessions share an explicitly scoped ephemeral store. This revises AGENTS.md §4's one-global-store rule to one-store-per-browsing-context, as required by the target's isolation feature. Update contract in the Container milestone; do not silently violate it.
3. **Move between Spaces preserves Container.** Changing Container is a separate explicit action that recreates the web view and reloads its destination; no cookie copying. Popup and link-open requests inherit originating tab context unless user chooses another.
4. **Window owns presentation, Space owns membership.** Initial release has one browser window. Later, each Space has one owning window at a time; switching to an already-visible Space focuses that window or explicitly transfers ownership. Never attach the same WKWebView to two view hierarchies.
5. **Typed actions drive commands and undo.** One dispatcher serves menus, Command Bar, gestures, and feature buttons. Add inverse records only for reversible mutations. Page navigation, server effects, data deletion, and AI requests are not browser-structure undo actions.
6. **Events replace web-state polling.** Engine emits stable tab/navigation IDs and navigation outcomes. Application services decide history/timeline policy; KVO remains for published display state. Clock remains for deadlines, hibernation and TOTP, with injected time for tests.
7. **Incremental ports, existing targets.** Domain DTOs/protocols in RedentKit; engine implementations in RedentEngine; persistence in RedentVault; feature models/views in RedentUI; concrete wiring in Redent. Inject an engine-owned rendering bridge from composition root so UI feature models stop depending on `WebTab`/`TabController`. No new package or generic plugin framework required for core.
8. **Persistence is explicit.** Versioned workspace storage with atomic commits/recovery, debounced saves after structural changes, flush on lifecycle transitions. Keep settings in UserDefaults and secrets in Keychain. Start workspace persistence as atomic JSON in existing Vault target; SQLite remains history storage. Report storage failures rather than silently discarding workspace state.
9. **Privacy policy precedes optional capture.** Preserve history URL query/fragment stripping. Strip URL userinfo too. Metadata initially means timestamps, Space/Container, navigation source and user labels, not page bodies. Exact session URLs need a separate retention policy; no form bodies, credentials, or OTP seeds in session/timeline/undo storage. Temporary and preview state excluded from normal persistence/search/import aggregation.

`docs/CONTRACTS.md` describes a historical frozen construction contract. Before implementation, update it additively where practical and document replacements/migrations where required. Its blanket “RedentKit ... do not modify” restriction cannot remain the future product contract because requested domain models and ports must expand. Do not restructure existing code solely to match an ideal diagram.

## Delivery order and independent gates

Relative size: S = bounded change; M = feature across layers; L = several independently reviewed changes. Sizes are scope signals, not calendar promises. Complete and validate each row before starting its dependent row.

| Milestone | Scope and dependency | Why now / risk | Independent release gate |
|---|---|---|---|
| M0 — Safe evolution | Characterization tests, additive tab state/event ports, v1→v2 session migration, storage error handling, renderer injection seam; none | M; prerequisites prevent state loss and untestable command coupling | Old sessions/pins/bookmarks/logins retained; bad migration recoverable; existing browser unchanged |
| M1 — Command Bar v1 | Typed dispatcher; ⌘K searches tabs/history/bookmarks, navigates, runs existing commands; M0 | M; earliest differentiating workflow, low WebKit risk | Complete keyboard-only browse/switch/reopen/bookmark flow; stale search cannot execute wrong action |
| M2 — Spaces + reversible tabs | Starter/custom Spaces, ownership/selection, movement, persistent pin ordering, close/move/Space undo; M1 | L; central product model | Switch Work→Research→Work across restart with same tab IDs/order; undo move/close/delete restores ownership |
| M3 — Smart History | Navigation events, contextual visit schema/indexes, Space filters, improved ranking, dedicated history UI; M2 | L; completes strategic center before peripheral features | Fixture relevance beats current candidate truncation; background visits and Space attribution correct |
| M4 — Smart tab organization | Manual groups, group undo, deterministic grouping suggestions; M2–M3 | M; direct value from established context | Accept/reject suggestion, move group, undo, restart without losing tabs |
| M5 — Containers + Temporary Tabs | Store registry and isolation spike first, then Container UI; lifespan/expiry and ephemeral session policy; M2–M3 | L/high risk; website-data lifecycle must precede safe cleanup | Two accounts isolated; same-Container tabs share login; expired temporary session absent from history/relaunch |
| M6 — Per-site privacy | Scoped policies/cookies/data and Forget Site; M3, M5 | L/high risk; verified deletion scope needed before more capture | Clear test site in one Container without affecting unrelated sites/Containers; deleted data not resurrected |
| M7a — Tab Timeline | Navigation-event timeline, live navigation restore and bounded hibernation restoration spike; M3, M5–M6 | M; adds navigational context on stable privacy/event model | Navigate A→B→C, inspect timeline, restore supported entry; fallback honestly labeled |
| M7b — Split View + Focus polish | Two panes, active-pane routing, visible-view hibernation rules; M2, M5 | M; builds on ownership without requiring AI | Both panes remain usable; keyboard navigation/autofill target active pane; Focus entry/exit preserves layout |
| M7c — Link Preview | Transient engine page role, keyboard/mouse invocation, promotion/dismissal; M5–M6 | M; ephemeral policy and scoped data lifecycle now available | Preview causes no normal tab/history entry; dismissal releases view; promotion preserves chosen context |
| M8 — Native multiwindow + full structural Undo | Independent window models, focused commands, closed-window records; M2, M4, M7b | L; most complex ownership changes come after single-window validation | Two windows have independent selections; restoring one closed window does not steal/duplicate live tabs |
| M9 — Optional AI | Provider ports, disabled/local/remote modes, page/selection/tab tasks, semantic index, suggestions; M3–M8 | L; quality/privacy/cost risk; no core dependency on AI | All core flows work with AI disabled/offline; local provider stays local; remote sends only approved scope |

**First product validation checkpoint: M3.** User can create Research Space, use ⌘K to find/open/move tabs, recover a mistaken close or move, return next day, and find pages by title/URL/Space. Stop expanding breadth if this workflow is slow or confusing; improve it before M4.

Suggested performance acceptance budgets, to measure on a declared reference Mac: command overlay visible p95 ≤100 ms; results p95 ≤200 ms after debounce with 1,000 tab records and 100,000 history visits; Space chrome switch p95 ≤100 ms excluding network/hibernated-page load. Record baseline first. Measure memory across awake/hibernated tabs and Containers; do not promise fixed per-tab process savings because WebKit owns process allocation.

## Data evolution

Add models when their milestone arrives; reserve stable IDs and versioning in M0 without implementing future feature payloads prematurely.

| Model | Required fields and invariants | First use |
|---|---|---|
| WorkspaceSnapshot | schemaVersion, revision, spaces, tabs, initial window selection; validated ID references | M0–M2 |
| Space | id, name, icon/color token, ordered tab/group membership, selectedTabID, defaultContainerID | M2 |
| TabSnapshot extension | spaceID, containerID, groupID?, lifespan; existing id/url/title/pin/activity retained | M2, M4–M5 |
| BrowserAction / ActionResult | typed payload, origin window/Space/tab context, revision/preconditions, typed error | M1 |
| UndoRecord | inverse structural state, affected IDs/order/selection, bounded size, expiry and deletion barriers | M2 |
| HistoryVisit | navigationID, pageID, tabID?, Space/Container at visit time, timestamp, source, transition | M3 |
| HistoryPage / HistoryQuery | sanitized URL/title aggregate; query text, scope, filters, limit, sort | M3 |
| TabGroup | id, spaceID, name/color, ordered membership; pin/group policy explicit | M4 |
| GroupingSuggestion | stable candidate tab IDs, reason, source revision, accepted/dismissed state | M4 |
| Container | id, name/color, default/named-persistent/ephemeral kind, persistent store UUID where applicable | M5 |
| TabLifespan | normal or temporary(sessionID, expiresAt?, cleanup policy); never implicit incognito inference | M5 |
| SitePolicy | Container ID + exact security origin for permissions; site/domain scope separately for data controls | M6 |
| NavigationEntry | id, navigationID, tabID, timestamp, redacted URL/title, transition, restore capability/token | M7a |
| PaneLayout / WindowSnapshot | windowID, spaceID, pane tab IDs, activePaneID, orientation/ratio; later window frame | M7b–M8 |
| AIRequest / AIResult | task kind, explicit input scope, provider capability, citations, cancellation; no auto-execution | M9 |

Migration: decode current BrowserSession as v1; retain tab IDs and selection; place existing tabs in Work using Default Container; create empty Personal/Research/Travel. Preserve current website store, history database, bookmarks and Keychain services. Back up original session before committing v2; validate references and make migration idempotent. Never reconstruct old per-visit chronology from aggregate visit counts: import legacy aggregates as unknown-context history, preserving counts and dates. Update Codable decoders with defaults; synthesized decoding alone will drop old sessions on newly required fields.

History migration uses SQLite schema version + transaction. Keep aggregate compatibility for `HistoryStoring` consumers during rollout; introduce contextual query/record methods and migrate fakes/import callers incrementally. History storage failures may leave browsing usable, but report history unavailable. Workspace and privacy deletion failures require explicit typed outcomes.

## Feature specifications

### 1. ⌘K Command Bar — M1, extended in every milestone

- **Current status:** Absent as command palette. Address suggestions cover history/bookmarks/direct URLs/search only; no ⌘K binding or entity/command result kinds.
- **Reuse:** `SuggestionEngine`, `AddressSuggestionsModel`, `AddressResolver`, `SuggestionList`/`SuggestionRow`, `BrowserCommands`, existing tab actions.
- **Architecture:** Separate search providers from typed execution. Menus/buttons/palette share action dispatcher and availability checks; resolve IDs against current state at execution time.
- **New components:** `CommandBarModel`, `CommandBarView`, command registry, result aggregator, tab/Space/history/bookmark/command providers. Registration occurs in composition root; extensibility initially in-process, no arbitrary third-party code loading.
- **Data changes:** `CommandID`, result ID/kind, label/subtitle, action payload, match score, scope; navigation result stores URL while entity results store IDs. No persisted closures.
- **WebKit APIs:** Existing load/back/forward/reload through engine port; palette itself needs none.
- **macOS APIs:** SwiftUI `Commands`, `.keyboardShortcut("k")`, `FocusState`, accessibility labels/actions; overlay in current window. `NSPanel` only if overlay proves insufficient.
- **Dependencies:** M0; Space provider in M2; contextual history in M3; later actions register as features land.
- **Implementation tasks:** Extract current URL providers; add cancellable concurrent lookup and deterministic ranking; keyboard highlight/Return/Escape; empty-query actions; tabs across Spaces; create/rename/switch/delete Space and move/pin/group tab commands. Keep ⌘L/address editing separate.
- **Testing tasks:** Extend suggestion tests for mixed kinds, duplicate URLs versus distinct tab IDs, out-of-order queries, deleted targets, disabled actions, focus restoration and keyboard-only manual flow.
- **Acceptance criteria:** All seven search/action surfaces requested work when their owning milestone ships; switching a result selects existing tab instead of duplicating it; Escape leaves browser state unchanged; matches show Space/Container context; latency budgets met.
- **Limitations:** “Extensible” means typed registered capabilities, not a plugin marketplace. No filesystem Spotlight indexing required. Large bookmark sets may eventually need indexed storage, based on measured latency.

### 2. Spaces — M2

- **Current status:** Absent; one flat session and selection.
- **Reuse:** `TabController` lifecycle/order operations, `BrowserSession`, session store, both tab strips and existing navigation controls.
- **Architecture:** Extract workspace ownership/selection from Engine. A workspace coordinator owns Space membership; Engine hosts pages by tab ID. Switching Space updates visible selection without rebuilding every tab.
- **New components:** Space model/coordinator, Space switcher/editor, workspace persistence adapter, Space command provider.
- **Data changes:** Space IDs/names/order/default Container; tab ownership; per-Space selection; initial workspace/window selection.
- **WebKit APIs:** Existing web-view lifecycle; website-data configuration stays Default until M5.
- **macOS APIs:** SwiftUI menu/picker/sidebar; proposed ⌃⌥1…9 switches Space, validated against system/user shortcuts; Command Bar always offers switching.
- **Dependencies:** M0–M1; isolated logins optional via M5, not prerequisite for workflow Spaces.
- **Implementation tasks:** Migration; starter/custom CRUD; remember selection/order; keyboard switching; move tab; last-Space protection; reversible deletion including owned tabs; preserve historic visit attribution after moves/deletion.
- **Testing tasks:** Workspace reducer tests for deletion/selection/movement; round-trip/migration/corrupt-store tests; switch while loading/hibernated; restart with invalid selected ID.
- **Acceptance criteria:** Work/Personal/Research/Travel/custom all function identically; each returns to prior tabs/order/selection after restart; moving tab preserves identity/login Container; switching does not wake all tabs.
- **Limitations:** Space separation alone does not isolate cookies. Explicit Container label prevents ambiguity. Deleted Space history retains historic context until user deletes that history.

### 3. Smart Tab Management — M2, M4, M5

- **Current status:** Pinning, ordering API, close-others, next/previous selection implemented. Groups, automatic suggestions, cross-Space moves, temporary policy absent. Both tab strips expose pin context menus; drag behavior needs validation rather than assumption from ordering API.
- **Reuse:** `TabControllerOrdering`, `TopTabStrip`, `SidebarTabStrip`, corresponding row/item views, `TabSnapshot.isPinned`.
- **Architecture:** Pure membership/order operations through dispatcher; grouping suggestions run over DTOs off-main and never move tabs without acceptance.
- **New components:** Group coordinator, group header/editor, drag/drop adapter, deterministic suggestion service and review UI.
- **Data changes:** TabGroup and ordered membership; group ID on tab; suggestion revision/reason; Space/temporary fields from owning features. Initial policy: pinned tabs occupy Space-level pinned section; pinning removes group membership, with inverse recorded.
- **WebKit APIs:** None for grouping/moving within same Container; existing engine hosting preserved.
- **macOS APIs:** SwiftUI drag/drop and context menus, keyboard actions through commands.
- **Dependencies:** M2 for ownership/undo; M3 for contextual suggestions; M5 for temporary integration; AI optional later.
- **Implementation tasks:** Manual group/rename/ungroup/reorder; move group between Spaces preserving Container IDs; enforce pinned ordering; suggest by registrable domain plus recent activity/Space; show reason and dismiss action; register commands.
- **Testing tasks:** Invariants under randomized move/pin/group/undo sequences; stale suggestions; deleted target Spaces; persistence; large-list performance; manual drag/drop in both layouts.
- **Acceptance criteria:** No operation duplicates/orphans tabs; pin order stable; suggestions require acceptance and remain explainable; all structural mutations undo correctly; temporary tabs remain visibly separate.
- **Limitations:** Rules-based suggestions cannot infer intent reliably; domain alone never triggers automatic movement. No AI dependency for shipped suggestions.

### 4. Temporary Tabs — M5

- **Current status:** Absent; every tab currently participates in session serialization and normal history policy.
- **Reuse:** New/close/hibernate lifecycle, clock, session snapshots, shared command infrastructure.
- **Architecture:** Separate temporary lifespan from website-data privacy. A temporary tab may use an existing Container with explicit data-retention notice, or an isolated ephemeral browsing session. Cleanup applies to owned ephemeral context, never blindly to a shared normal store.
- **New components:** Temporary-session coordinator, expiry policy, lifecycle cleanup service, temporary-tab affordance and “Keep Tab” action.
- **Data changes:** Temporary session ID, deadline, cleanup choice; normal snapshot serializer excludes temporary tabs, timeline, undo and previews. Ephemeral session registry remains in memory.
- **WebKit APIs:** `WKWebsiteDataStore.nonPersistent()`, configuration injection, teardown and website-data removal for explicitly owned scope. Store can be shared by related temporary tabs, not allocated blindly per tab.
- **macOS APIs:** Existing clock plus workspace sleep/wake/app activation notifications to reevaluate deadlines; no per-tab polling timers.
- **Dependencies:** Containers and recording-policy gates within M5; M2 session filtering, M3 event recording.
- **Implementation tasks:** Explicit new-temporary command; visible indicator/separate section; optional expiry UI; no expiry by default; active expired tab offers keep/close, background expired tab closes; reevaluate after wake. “Keep” selects destination Space/Container and reloads when storage boundary changes. Disable password-save capture by default in temporary role.
- **Testing tasks:** Injected clock, sleep past deadline, active prompt, shared ephemeral-session reference counts, shutdown/crash/restart exclusions; inspect history/session/favicon paths for residue; shared Container cleanup never clears ordinary tabs.
- **Acceptance criteria:** Temporary visits absent from normal history, favorites/frecency, workspace restore, AI index, and closed-tab history. Cleanup-enabled ephemeral session releases all view/store references when last tab closes. Keeping a tab requires explicit action.
- **Limitations:** Temporary does not mean anonymity. Shared-Container activity can change server/cookie state; cannot selectively erase only one tab's data. Ephemeral sessions cannot restore logged-in state after process exit; no secure physical-erasure claim.

### 5. Containers — M5, isolation spike first

- **Current status:** Absent. `WebViewFactory.sharedDataStore` forces one default store.
- **Reuse:** Factory, WebTab wake/hibernate, weak delegate/router lifecycle, existing Default login state.
- **Architecture:** Inject `BrowsingContextProviding` engine capability; registry owns one store per persistent Container or ephemeral session. Composition root constructs registry; domain/UI see identifiers, never WebKit stores.
- **New components:** Container registry/adapter, management model/view, context-aware open request, deletion coordinator.
- **Data changes:** Stable Container ID/store UUID; tab Container ID; Space default Container; distinct default-store mapping so migration never replaces existing cookies.
- **WebKit APIs:** `WKWebsiteDataStore(forIdentifier:)`, `.default()`, `.nonPersistent()`, identifiers enumeration/removal, `WKWebViewConfiguration.websiteDataStore`, `WKHTTPCookieStore`. Persistent profiles are supported since macOS 14, below this project's macOS 26 floor. [WebKit profile APIs](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/).
- **macOS APIs:** SwiftUI menu/picker and storage-management UI; no deprecated process-pool isolation approach.
- **Dependencies:** M0/M2 identity and persistence; M3 scoped recording; contract revision described above.
- **Implementation tasks:** Prove two persistent stores with test server; registry injection; selector and open-in-Container; popup/opener context routing; wake/reopen preserves Container; Container change rebuilds view; prevent deletion while referenced, then retire views/remove store/handle failure. Partition or bypass auxiliary URLSession favicon caches for ephemeral roles.
- **Testing tasks:** Same host, two cookies/accounts; same-Container sharing; localStorage/IndexedDB/cache isolation; restart; hibernation; popup and JS window.open; deletion while views active; no Default cookie migration loss.
- **Acceptance criteria:** Two accounts remain separate across restart; tab/Space movement cannot silently change Container; normal sibling tabs share login; isolated contexts never fall back to Default on error.
- **Limitations:** Data-store isolation is not guaranteed process isolation or separate network identity. Switching Container cannot preserve arbitrary JS/sessionStorage/form state. Store deletion can fail while in use; show recoverable failure. [Store lifecycle constraints](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/).

### 6. Smart History — M3, semantic extension M9

- **Current status:** Partial: local SQLite history, title/URL/host matching and frecency. No visit metadata, Space scope, history browser, or semantic index.
- **Reuse:** `HistoryEntry`, `HistoryStoring`, `SQLiteHistoryStore`, `HistoryDatabase`, `HistoryRanking`, `HistoryRow`, importer and existing store tests.
- **Architecture:** Replace selected-tab polling with engine navigation events; history recorder receives tab/Space/Container at event time. Separate immutable visits from aggregate pages and search indexing. Preserve query/fragment stripping and temporary exclusion before storage.
- **New components:** Navigation-event recorder, versioned history migration, contextual query service, history browser model/view, SQL search index/relevance fixtures.
- **Data changes:** HistoryVisit/HistoryPage, navigation ID, historic context, transition/source, user labels; query scopes and filters. Imported legacy rows retain unknown context and aggregate counts.
- **WebKit APIs:** `WKNavigationDelegate` commit/finish/failure callbacks; KVO URL/title for same-document changes; classify reload/back/forward/redirect with navigation IDs and live list where available. No WebKit global-history database API assumed.
- **macOS APIs:** Foundation/SQLite actor persistence, SwiftUI searchable/filter UI; no Spotlight publishing of private history by default.
- **Dependencies:** M2 Space identity; M0 event seam; enrich with Container IDs in M5.
- **Implementation tasks:** Typed event deduplication; record background visits; settle title updates without inventing visits; transactional schema migration; deterministic ranked candidate query replacing unordered LIMIT 200; evaluate SQLite FTS5 with runtime capability check and indexed fallback; literal-query escaping; current/all-Space filters, date/host/label filters; deletion/index propagation.
- **Testing tasks:** Redirect/reload/back/forward/SPA fixtures; same URL in two Spaces; delayed title and background finish; move during navigation; import migration; wildcard/Unicode queries; relevance corpus exceeding 200 candidates; 100k-visit benchmark; unavailable DB.
- **Acceptance criteria:** Known fixtures rank intended page above weaker matches; background finished navigation recorded once; Space filter reflects where visit happened; search remains local and usable offline; deletion removes all derived results.
- **Limitations:** Sanitized URLs collapse query-dependent pages and cannot reproduce every search/application route. SPA observability incomplete without invasive page-world hooks; keep isolated scripts and document observable coverage. Metadata search is not full page-content search.

### 7. Browser Undo — M2/M4, closed windows M8

- **Current status:** Partial: ten closed TabSnapshots in memory; reopen restores URL near current tab. No original-position, move/group/Space/window inverse history.
- **Reuse:** `closedStack`, `reopenLastClosed`, snapshots, ⌘⇧T menu action.
- **Architecture:** Central reversible-action coordinator applies validated structural changes and stores bounded inverse records. Group operations are atomic; reject stale inverse conflicts without partial mutation. Keep live WebKit objects out of undo records.
- **New components:** Action dispatcher, undo coordinator, snapshot inverse builder, native menu adapter, closed-window record adapter in M8.
- **Data changes:** Original Space/group/order/pin/selection/window plus bounded snapshot payload; record affected revision/IDs. Initial undo is session-memory only; persistent undo deferred until separately justified.
- **WebKit APIs:** Recreate/wake tab in same context; URL or supported interaction-state restoration, no server rollback.
- **macOS APIs:** `UndoManager` integration or validated app commands scoped through focused window; preserve web-page/text-field ⌘Z behavior. ⌘⇧T remains explicit reopen action.
- **Dependencies:** M2 workspace; M4 groups; M8 independent windows. Privacy deletion barrier arrives M6.
- **Implementation tasks:** Close/move/pin/Space create/rename/delete inverses; group transaction inverse; memory bound; contextual action names; conflict policy for deleted Containers; closed-window recreation; invalidate records referencing forgotten sites or temporary content.
- **Testing tasks:** Action/inverse equivalence; repeated undo/redo if exposed; bulk operation atomicity; stale revisions; intervening moves; data-deletion invalidation; focus/responder routing; window-ID collision.
- **Acceptance criteria:** Close/move/group/Space undo restores structural position and selection; closed-window action restores eligible normal tabs without duplicating existing ownership; user receives explicit fallback when page runtime cannot restore.
- **Limitations:** No reversal of submissions, external side effects, cleared site data, expired ephemeral sessions, or arbitrary page mutations. Exact previous DOM is not promised by tab reopening.

### 8. Tab History / Timeline — M7a

- **Current status:** Only live WebKit back/forward and current URL snapshot; app timeline absent. Hibernation discards live navigation list.
- **Reuse:** `WebTab.goBack/goForward`, KVO URL/title, navigation delegate, M3 events and existing hibernation lifecycle.
- **Architecture:** Timeline is per-tab navigation provenance, distinct from global aggregate history. Engine retains bounded opaque live restoration tokens; persisted domain entries expose restoration capability, not platform objects.
- **New components:** Timeline recorder/store/query, timeline model/panel, engine restoration adapter.
- **Data changes:** NavigationEntry with parent/sequence, transition, timestamps, sanitized URL/title, live-token eligibility. Temporary timelines stay memory-only and die with their session.
- **WebKit APIs:** `WKBackForwardList`, `WKBackForwardListItem`, `go(to:)`, `interactionState`; same-document URL observation. Interaction state can transfer state between views; evaluate it for bounded in-memory hibernation restoration, not as a documented Codable archive. [Apple navigation state](https://developer.apple.com/documentation/webkit/wkwebview/interactionstate).
- **macOS APIs:** SwiftUI timeline list/sidebar, contextual menu and keyboard command.
- **Dependencies:** M3 navigation events; M5 context identity; M6 deletion policy.
- **Implementation tasks:** Record chronological entries; distinguish redirects, reloads, traversal and title updates; live-item navigation; bounded interaction-state spike; persisted URL fallback marked “Reload URL”; cap retention and cascade Forget Site.
- **Testing tasks:** A→B→C/back/branch sequences; reload versus duplicate record; hibernate/wake; web process termination; restart; unsupported/sensitive/POST states; deletion.
- **Acceptance criteria:** User can inspect a tab's path and select supported earlier state; live list navigation used when valid; restart offers honest URL-based restore; no hidden form-body capture.
- **Limitations:** Opaque state may consume memory; measure before keeping it for many tabs. POST results, JS heap, expired authentication, scroll/forms and query-stripped routes cannot be universally reconstructed. No private WebKit serialization APIs.

### 9. Split View — M7b

- **Current status:** Absent. `ContentArea` mounts selected tab only; hibernation protects one selected ID.
- **Reuse:** `WebContentView`/NSView host, ContentArea, page-card design, navigation controls, sidebar resize interaction pattern.
- **Architecture:** Window presentation owns visible pane set and active pane. Engine hibernation receives all visible tab IDs. Navigation/autofill/OTP commands resolve explicit active tab, not single global selection.
- **New components:** Pane layout coordinator, split content host, divider controls, active-pane focus adapter.
- **Data changes:** Two-pane layout initially, tab IDs, active pane, orientation, ratio; persist layout per window/Space with reference validation.
- **WebKit APIs:** Two independent WKWebViews via existing bridge; independent back/forward; each retains Container configuration. Never mount one instance twice.
- **macOS APIs:** SwiftUI `HSplitView`/`VSplitView` or AppKit `NSSplitView` if constraints require; first-responder coordination and commands for split/focus/close pane.
- **Dependencies:** M2 ownership, M5 contexts; M8 generalizes to multiple windows.
- **Implementation tasks:** Open selected/another tab beside current; clamp resize ratios/minimum sizes; focus switching; route toolbar/signals to active pane; exclude both visible tabs from hibernation; close-pane versus close-tab distinction; restore layout and Focus Mode interaction.
- **Testing tasks:** Pure layout/selection tests; fake-clock visibility tests; manual independent navigation, keyboard focus, OTP/autofill routing, resize/fullscreen, close/move visible tab.
- **Acceptance criteria:** Both pages stay interactive past hibernation threshold; keyboard navigation affects active pane only; close split retains tabs; ratio/selection survive restart; no cross-pane secret filling.
- **Limitations:** Two visible renderers cost more memory; first version capped at two panes. One tab cannot appear simultaneously in two panes without explicit duplication into another tab.

### 10. Link Preview — M7c

- **Current status:** No product preview coordinator or explicit affordance. WebKit may provide platform-native link preview, but it is not configured/validated as requested workflow.
- **Reuse:** Engine factory, WebContentView bridge, weak teardown, isolated `PageScripts`, transient context from M5.
- **Architecture:** Preview is a transient page role outside workspace tab membership; navigation/credential/history policy knows role. Source Container retained for same-session preview, or user selects isolated ephemeral preview.
- **New components:** Preview coordinator, transient page handle, preview panel, accessible link-target resolver and promotion action.
- **Data changes:** In-memory preview ID/source tab/source Container/URL/role; promotion creates normal TabSnapshot only after user action.
- **WebKit APIs:** `allowsLinkPreview` for native enhancement; custom preview uses configured WKWebView. Isolated-world link-target lookup with frame-aware handling; scoped WKUIDelegate popup policy. SDK declares `allowsLinkPreview` available on macOS.
- **macOS APIs:** Popover/panel, context-menu “Preview Link”, focused-link keyboard command, Escape dismissal and focus restoration. Mouse gesture supplemental, never only access path.
- **Dependencies:** M5 transient context, M6 data policy; M7b pane targeting for “Open beside”.
- **Implementation tasks:** Link discovery; keyboard/mouse invocation; block recursive preview spawning; render loading/error; dismiss; promote into chosen Space/Container; explicit permission UI for page capture; disable automatic credential-save offers; exclude previews from normal history/undo/index.
- **Testing tasks:** Cross-origin iframe/focused-link cases; dismiss during navigation; popup attempts; same-Container/isolated cookies; promotion; repeated open/close memory test; VoiceOver and focus return.
- **Acceptance criteria:** Preview has no permanent tab or normal-history entry; Escape returns source focus and releases WKWebView; promotion creates exactly one tab in chosen context; accessible without hover.
- **Limitations:** Loading a preview makes network requests and can mutate server/cookie state in shared context. Isolated preview may lack authentication. Native Force Click alone cannot guarantee required keyboard workflow; inaccessible frame targets need context-menu fallback.

### 11. Focus Mode — existing; harden M1/M7b

- **Current status:** Implemented: `BrowserModel.isFocusMode`, toggle, ⌘⇧F; shell hides chrome and removes page inset. Password/OTP overlays remain rendered independently.
- **Reuse:** Existing mode, `BrowserWindowView`, `ContentArea`, `PageCard`, `BrowserCommands`; preserve appearance.
- **Architecture:** Keep presentation state per window; independent of session membership and native fullscreen. Command Bar remains reachable while chrome hidden.
- **New components:** No new subsystem. Extract window presentation state when split/multiwindow requires; add contextual affordance only where needed.
- **Data changes:** Move focus flag to window presentation model in M8; optional restoration preference, no page-state mutation.
- **WebKit APIs:** None beyond keeping existing views alive; do not recreate page on toggle.
- **macOS APIs:** Existing SwiftUI command, focus handling/accessibility, AppKit window behavior; native fullscreen stays separate.
- **Dependencies:** None for existing mode; M1 palette integration; M7b visible-pane preservation; M8 per-window scope.
- **Implementation tasks:** Verify keyboard exit from page inputs; define password/OTP prompt behavior while focused; preserve split ratio and selected pane; provide discoverable menu command; ensure transient overlays dismiss predictably.
- **Testing tasks:** Model toggle invariant tests once engine port exists; manual page input/VoiceOver/fullscreen/split/Command Bar entry and exit.
- **Acceptance criteria:** Fast entry/exit without reload, lost selection, or changed Space; ⌘K usable; essential user-triggered security prompts remain accessible; exit restores prior chrome layout.
- **Limitations:** Existing Focus Mode is UI hiding, not a website distraction blocker or native fullscreen replacement. No rewrite warranted.

### 12. Per-Site Privacy Controls — M6

- **Current status:** Global blocker/settings only. No site permission ledger, scoped cookie/data management or Forget Site operation.
- **Reuse:** `ContentBlocker`, `Origin`/`PublicSuffix`, settings UI and persistence adapters; use existing registrable-domain utilities only where site scope is appropriate.
- **Architecture:** Engine privacy port reports actual supported capabilities; policy service keys permissions by exact scheme/host/port + Container. Separate registrable-site deletion scope from security-origin permissions. Use typed partial-failure reporting.
- **New components:** Site privacy model/view, permission policy store, engine site-data adapter, coordinated Forget Site service.
- **Data changes:** Per-origin permission decisions, per-site blocking policy, data-record descriptors, supported/unknown tracking information, deletion scope/result. No invented tracker counts.
- **WebKit APIs:** `WKHTTPCookieStore` get/delete/observe; website-data record enumeration and scoped removal; `WKUIDelegate` media capture permission callback; `WKContentRuleList` rules. Installed macOS 26.4 headers confirm these APIs. Enumerate camera/microphone and other supported controls individually; do not infer Safari-level coverage.
- **macOS APIs:** Camera/microphone TCC permissions remain OS-owned; deep link to System Settings when blocked; native form/confirmation for user-requested deletion. Existing QR camera permission is separate from website permission.
- **Dependencies:** M5 Container scope, M3 history deletion, M2 undo barriers; later timeline/AI consumers subscribe to deletion events.
- **Implementation tasks:** Site panel with Container/scope; cookie inspection/removal; clear website records; permission decisions and active-capture stop behavior; validate blocker compilation/application (current async compiler does not visibly reapply list to already-created views). Forget Site stops affected views, deletes scoped data/history/timeline/cache/index, invalidates undo/session URLs that would resurrect forgotten records, then resumes only by explicit navigation. Bookmarks and saved credentials retained unless user explicitly includes them.
- **Testing tasks:** Two sites/two Containers; exact origin versus subdomain; delayed writes during deletion; active page recreating storage; TCC denied; blocked-rule compile race; partial failure/retry; forgot-site absence from undo/relaunch/search.
- **Acceptance criteria:** User sees supported permissions, cookies and available website data; scoped clear leaves unrelated contexts intact; Forget Site reports exactly what was removed/retained; unsupported tracking metrics show unavailable.
- **Limitations:** WebKit website-data records may be coarser than exact origin; show actual deletion scope, never substring-match record names or promise per-tab deletion. Public WebKit APIs do not expose a complete Safari privacy report or universal permission manager. Irreversible deletion excluded from undo.

### 13. Optional AI Layer — M9

- **Current status:** Absent: no provider port, page extraction, embeddings or AI UI.
- **Reuse:** Command Bar registration, history query/deletion, Space/group actions, isolated script infrastructure, Keychain adapters for provider credentials.
- **Architecture:** Provider-agnostic task and embedding ports in RedentKit; optional adapter target only when first provider needs it. Composition chooses disabled/local/remote implementation. AI yields proposals/results; dispatcher requires user action before structural mutation.
- **New components:** AI task coordinator, bounded page/selection extractor, provider capability registry, result panel with source citations, local semantic index adapter, grouping/Space suggestion provider.
- **Data changes:** Task/request/result/citation/capability DTOs; opt-in configuration; embedding model/version/dimension and source IDs; deletion mapping. Provider keys remain Keychain secrets.
- **WebKit APIs:** Isolated-world `callAsyncJavaScript`/evaluation for explicit selection/readable text extraction, frame-aware and size-limited. No arbitrary page-world script or cookie/credential export.
- **macOS APIs:** Foundation async networking for opted-in remote adapter; chosen local runtime capability checks; SwiftUI result/progress UI. Local execution is optional capability, never a minimum OS/model assumption.
- **Dependencies:** M3 searchable history; M5–M6 exclusion/deletion; M1 commands; M4 suggestions; M7 tab/page scope.
- **Implementation tasks:** Disabled mode first; provider cancellation/errors/capabilities; local provider and separate explicit remote opt-in; summarize page, explain selection, compare chosen tabs, structured extraction; semantic history over retained metadata initially; show grouping/Space proposals with accept/reject; propagate deletions to embeddings/caches.
- **Testing tasks:** Fake providers, offline/disabled flows, streaming cancellation/timeouts, context limits, extraction redaction, malicious page instructions, no remote traffic in local-only mode, unsupported local hardware, embedding-version migration, Forget Site purge.
- **Acceptance criteria:** Every requested AI task available with a capable configured provider; unavailable capabilities clearly labeled; disabled mode leaves complete browser usable; local-only execution never falls back remotely; page text cannot trigger tools/actions; results cite source tab/selection and show uncertainty.
- **Limitations:** Quality, hardware, model context and remote cost vary. Full-page semantic history requires separate explicit capture policy; metadata embeddings alone cannot answer arbitrary past page-body questions. Private/temporary content excluded by default. No model/provider dependency in core browsing.

### 14. Native macOS Experience — continuous, multiwindow M8

- **Current status:** Strong base: SwiftUI/AppKit/WebKit, glass design system, native menu shortcuts, hidden titlebar, window configurator. App-level shared model prevents true independent browser windows; Spotlight-like Command Bar absent; browser notifications absent.
- **Reuse:** `RedentApp`, `RootScene`, `AppDelegate`, `WindowConfigurator`, `BrowserCommands`, `RedentDesign` primitives.
- **Architecture:** Shared app stores/engine context registry; per-window BrowserModel and presentation state. Focused window routes commands. App lifecycle persists all windows; browser tab ownership remains unique.
- **New components:** Window session registry/factory, focused command context, window-restoration coordinator; notification adapter only for a concrete later long-running task needing notification.
- **Data changes:** Window ID/frame/Space/pane selection and closed-window structural record; command context includes window ID.
- **WebKit APIs:** Existing engine bridge; correct parent-window association for JavaScript dialogs and page permissions; process failure recovery.
- **macOS APIs:** SwiftUI `WindowGroup`, `openWindow`, `FocusedValue`/focused scene values, AppKit `NSWindow`/`NSApplicationDelegate`, responder chain, accessibility/VoiceOver, Reduce Motion/Increase Contrast; `UNUserNotificationCenter` only when meaningful user-opted notification exists.
- **Dependencies:** M1 palette; M2 workspace; M7b pane ownership; M8 full window undo. Accessibility/native shortcuts checked at every milestone.
- **Implementation tasks:** Window factory instead of shared single model; New Window/close-window behavior; focused menus; safe restoration onto available displays; last-window/Dock reopening behavior; native fullscreen/minimize/zoom; keyboard shortcut collision audit; accessibility polish and reduced-motion behavior.
- **Testing tasks:** Window state model tests; manual two-window command targeting, dialogs, screen removal, relaunch, close-last-window policy, VoiceOver, input methods, keyboard layouts and reduced motion.
- **Acceptance criteria:** Independent window selection; shortcuts/dialogs affect correct window/pane; closed-window restore preserves eligible tabs; native window controls behave normally; no mandatory notifications; professional UI uses existing design tokens consistently.
- **Limitations:** Current UI minimum macOS 26 retained; supporting older systems is separate scope. Restoration guarantees browser structure, not arbitrary website runtime state. Native appearance alone does not establish accessibility compliance.

## Implementation discipline and release verification

For every milestone: small responsibility-based Swift files (≤150 lines), functions ≤40 lines and ≤5 parameters, explicit typed errors, Swift 6 concurrency, Foundation-only domain, no platform types through ports, existing secrets/isolated-world rules retained. Use configuration/request structs as APIs grow. Existing files already have long parameter lists and responsibility-split extensions; migrate touched APIs without repository-wide cosmetic cleanup.

Verification must include `make verify`: line check, import checks, force-try/cast scan, release build, Swift tests. Current Makefile checks do **not** prove all architecture rules: concrete Engine references in UI pass; general `!`, function length and arbitrary dependency directions are not comprehensively checked. Add targeted checks where useful and retain manual review. Baseline favicon lookup uses the default evaluation overload; migrate it to the existing isolated content world when touching extraction/context handling.

Add pure domain/reducer and view-model tests with Swift Testing; add isolated Engine integration tests using local fixture server and fresh test stores for lifecycle/privacy/navigation. Do not unit-test SwiftUI view bodies. Manual native UI acceptance complements tests. Every behavioral bug fixed during milestones gets regression coverage. Measure awake/hibernated/visible/ephemeral lifecycles for leaks, not just one process's resident size.

Preserve password/OTP/import behavior throughout. New history/workspace models must not move secrets out of Keychain or silently change autofill origin checks. Container-aware credential presentation must remain explicit user-triggered filling and never automatic submission.

No simultaneous implementation of all features. First implementation slice: M0 migration fixture and tab-state port; then M1 Command Bar wired to existing actions. Defer Containers/UI expansion until central workflow has passed M3's product gate.
