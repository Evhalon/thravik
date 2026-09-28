// Page: the frame tree Chrome names execution contexts and resources after,
// plus navigation — which is also when a frame's execution contexts die.
// WebKit never says so itself, so the bridge tells Chrome.

import type { Session } from "./session";

const RESOURCE_TYPES: Record<string, string> = { StyleSheet: "Stylesheet", Beacon: "Ping" };

export function resourceType(t: string | undefined): string {
  if (!t) return "Other";
  return RESOURCE_TYPES[t] ?? t;
}

/** Turns a domain on; the hidden Web Inspector usually already did. */
export function enable(s: Session, domain: string) {
  return s.call(`${domain}.enable`).catch(() => ({}));
}

export function installPage(s: Session) {
  s.handle("Page.enable", () => enable(s, "Page"));
  s.handle("Page.getResourceTree", async () => ({ frameTree: tree(s, (await s.call("Page.getResourceTree")).frameTree, true) }));
  s.handle("Page.getFrameTree", async () => ({ frameTree: tree(s, (await s.call("Page.getResourceTree")).frameTree, false) }));
  s.handle("Page.getResourceContent", (p) => s.call("Page.getResourceContent", { frameId: p.frameId, url: p.url }));
  s.handle("Page.reload", (p) => s.call("Page.reload", { ignoreCache: !!p.ignoreCache }));
  s.handle("Page.navigate", async (p) => {
    await s.call("Runtime.evaluate", { expression: `location.href = ${JSON.stringify(p.url)}`, contextId: s.state.mainContextId || undefined });
    return { frameId: s.state.mainFrameId };
  });
  s.handle("Page.getNavigationHistory", () => ({
    currentIndex: 0,
    entries: [{ id: 0, url: s.state.mainFrameURL, userTypedURL: s.state.mainFrameURL, title: "", transitionType: "typed" }],
  }));
  s.handle("Page.addScriptToEvaluateOnNewDocument", () => ({ identifier: "0" }));
  installPageEvents(s);
}

function installPageEvents(s: Session) {
  s.on("Page.frameNavigated", ({ frame }) => {
    if (!frame) return;
    const translated = remember(s, frame);
    if (!frame.parentId) {
      s.state.resetContexts();
      s.emit("Runtime.executionContextsCleared", {});
    } else {
      destroyContexts(s, frame.id);
    }
    s.emit("Page.frameNavigated", { frame: translated, type: "Navigation" });
  });
  s.on("Page.frameDetached", ({ frameId }) => {
    destroyContexts(s, frameId);
    s.emit("Page.frameDetached", { frameId, reason: "remove" });
  });
  for (const event of ["Page.domContentEventFired", "Page.loadEventFired", "Page.frameStartedLoading", "Page.frameStoppedLoading"]) {
    s.on(event, (p) => s.emit(event, p));
  }
}

function destroyContexts(s: Session, frameId: string) {
  for (const id of s.state.dropContexts(frameId)) {
    s.emit("Runtime.executionContextDestroyed", { executionContextId: id, executionContextUniqueId: String(id) });
  }
}

function tree(s: Session, node: any, withResources: boolean): any {
  const out: any = { frame: remember(s, node.frame) };
  if (node.childFrames?.length) out.childFrames = node.childFrames.map((c: any) => tree(s, c, withResources));
  if (withResources) {
    out.resources = (node.resources ?? []).map((r: any) => ({
      url: r.url, type: resourceType(r.type), mimeType: r.mimeType ?? "", failed: r.failed, canceled: r.canceled,
    }));
  }
  return out;
}

/** WebKit Page.Frame → CDP Page.Frame, noting the main frame and origins. */
function remember(s: Session, f: any): any {
  const origin = f.securityOrigin ?? "";
  s.state.setOrigin(f.id, origin);
  if (!f.parentId) {
    s.state.mainFrameId = f.id;
    s.state.mainFrameURL = f.url;
  }
  let host = "";
  try {
    host = new URL(f.url).hostname;
  } catch {
    // An opaque URL such as about:blank has no host to show.
  }
  const secure = origin.startsWith("https:") || host === "localhost" || host === "127.0.0.1";
  return {
    id: f.id,
    ...(f.parentId ? { parentId: f.parentId } : {}),
    loaderId: f.loaderId,
    name: f.name,
    url: f.url,
    domainAndRegistry: host.split(".").slice(-2).join("."),
    securityOrigin: origin,
    mimeType: f.mimeType ?? "text/html",
    secureContextType: secure ? "Secure" : "InsecureScheme",
    crossOriginIsolatedContextType: "NotIsolated",
    gatedAPIFeatures: [],
  };
}
