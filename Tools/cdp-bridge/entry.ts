// Runs inside the hidden Web Inspector frontend WebKit loads for a tab
// (inspector-resource:///Main.html), never inside a web page.
//
// The frontend already holds the only protocol connection WebKit offers to
// that tab. This taps it: the session's requests go out through
// InspectorFrontendHost, answers addressed to the session come back through
// InspectorFrontendAPI and are withheld from the frontend, and events reach
// both. Redent relays the session to Chrome over a local WebSocket.

import { Session, isSessionID, type Message } from "./cdp/session";
import { installConsole } from "./cdp/console";
import { installCSS } from "./cdp/css";
import { installDebugger } from "./cdp/debugger";
import { installDOM } from "./cdp/dom";
import { installEmulation } from "./cdp/emulation";
import { installFallback } from "./cdp/fallback";
import { installNetwork } from "./cdp/network";
import { installOverlay } from "./cdp/overlay";
import { installPage } from "./cdp/page";
import { installRuntime } from "./cdp/runtime";

declare const InspectorFrontendHost: { sendMessageToBackend(raw: string): void };
declare const InspectorFrontendAPI: Record<string, (message: unknown) => void>;
declare const WI: { pageTarget?: { identifier?: string } | null };

const HANDLER_NAME = "redentDevTools";
const DISPATCHERS = ["dispatchMessageAsync", "dispatchMessage"];

let session: Session | null = null;

function toNative(raw: string) {
  (window as any).webkit.messageHandlers[HANDLER_NAME].postMessage(raw);
}

function parse(message: unknown): Message | null {
  try {
    return typeof message === "string" ? JSON.parse(message) : JSON.parse(JSON.stringify(message));
  } catch {
    return null;
  }
}

/** Hands the session its share of one backend message; false withholds it
 *  from the frontend because the session asked for it. */
function route(active: Session, message: unknown): boolean {
  const outer = parse(message);
  if (!outer) return true;
  if (outer.method !== "Target.dispatchMessageFromTarget") {
    active.fromOuter(outer);
    return !isSessionID(outer.id);
  }
  if (!active.isPageTarget(outer.params?.targetId)) return true;
  const inner = parse(outer.params?.message);
  if (!inner) return true;
  active.fromBackend(inner);
  if (WITHHELD.has(inner.method ?? "")) return false;
  return !isSessionID(inner.id);
}

// Events the hidden Web Inspector answers by bringing its window to the
// front — a pause, a picked element, `inspect()`. Chrome's DevTools is the one
// showing them, so the hidden one never hears of them.
const WITHHELD = new Set(["Debugger.paused", "Debugger.resumed", "DOM.inspect", "Inspector.inspect"]);

function tap(name: string) {
  const original = InspectorFrontendAPI[name];
  if (typeof original !== "function") return;
  InspectorFrontendAPI[name] = function (this: unknown, message: unknown) {
    if (session && !route(session, message)) return;
    return original.call(this, message);
  };
}

let bringToFront: (() => void) | null = null;

/** Keeps the hidden Web Inspector hidden whatever else asks it to show. */
function holdWindowBack() {
  const host = InspectorFrontendHost as any;
  if (bringToFront || typeof host.bringToFront !== "function") return;
  bringToFront = host.bringToFront;
  try {
    host.bringToFront = () => {};
  } catch {
    bringToFront = null;
  }
}

function releaseWindow() {
  if (!bringToFront) return;
  try {
    (InspectorFrontendHost as any).bringToFront = bringToFront;
  } catch {
    // Left in place: the tab's Web Inspector is closed with the tap anyway.
  }
  bringToFront = null;
}

function attach() {
  holdWindowBack();
  const transport = {
    toBackend: (raw: string) => InspectorFrontendHost.sendMessageToBackend(raw),
    toTools: toNative,
  };
  session = new Session(transport, WI.pageTarget?.identifier ?? null);
  installRuntime(session);
  installConsole(session);
  installPage(session);
  installNetwork(session);
  installDebugger(session);
  installEmulation(session);
  installDOM(session);
  installOverlay(session);
  installCSS(session);
  installFallback(session);
}

if (!(window as any).__redentDevTools) {
  DISPATCHERS.forEach(tap);
  (window as any).__redentDevTools = {
    attach,
    detach: () => {
      session = null;
      releaseWindow();
    },
    fromTools: (raw: string) => session?.fromTools(raw),
  };
}
