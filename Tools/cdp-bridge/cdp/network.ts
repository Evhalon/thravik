// Network: the request lifecycle, bodies, cookies and the cache switch.

import type { Session } from "./session";
import { ProtocolError } from "./session";
import { enable, resourceType } from "./page";
import { cookie, encodedLength, enrich, initiator, priority, request, response } from "./network-values";

export function installNetwork(s: Session) {
  s.handle("Network.enable", () => enable(s, "Network"));
  // The hidden Web Inspector still listens; Chrome just stops hearing.
  s.handle("Network.disable", () => ({}));
  s.handle("Network.getResponseBody", (p) => s.call("Network.getResponseBody", { requestId: p.requestId }));
  s.handle("Network.getRequestPostData", (p) => {
    const postData = s.state.requests.get(p.requestId)?.postData;
    if (postData == null) throw new ProtocolError("No post data available for the request");
    return { postData };
  });
  s.handle("Network.setCacheDisabled", (p) => s.call("Network.setResourceCachingDisabled", { disabled: !!p.cacheDisabled }));
  // Throttling is not something WebKit offers here; Chrome still expects the
  // rule list it asked for back.
  s.handle("Network.emulateNetworkConditionsByRule", () => ({ ruleIds: [] }));
  s.handle("Network.setExtraHTTPHeaders", (p) => s.call("Network.setExtraHTTPHeaders", { headers: p.headers ?? {} }));
  s.handle("Network.setUserAgentOverride", (p) => s.call("Page.overrideUserAgent", p.userAgent ? { value: p.userAgent } : {}));
  s.handle("Network.getCookies", (p) => cookies(s, p.urls));
  s.handle("Network.getAllCookies", () => cookies(s));
  s.handle("Network.deleteCookies", (p) => s.call("Page.deleteCookie", {
    cookieName: p.name, url: p.url ?? `https://${(p.domain ?? "").replace(/^\./, "")}${p.path ?? "/"}`,
  }));
  s.handle("Network.setCookie", async (p) => {
    await s.call("Page.setCookie", { cookie: {
      name: p.name, value: p.value, domain: p.domain ?? new URL(p.url).hostname, path: p.path ?? "/",
      expires: p.expires ? p.expires * 1000 : 0, session: !p.expires, httpOnly: !!p.httpOnly,
      secure: !!p.secure, sameSite: p.sameSite ?? "None",
    } });
    return { success: true };
  });
  installLifecycle(s);
  installWebSockets(s);
}

async function cookies(s: Session, urls?: string[]) {
  const all = ((await s.call("Page.getCookies")).cookies ?? []).map(cookie);
  if (!urls?.length) return { cookies: all };
  const hosts = urls.map((u) => { try { return new URL(u).hostname; } catch { return ""; } });
  const matches = (domain: string) => hosts.some((h) => h === domain.replace(/^\./, "") || h.endsWith(domain.startsWith(".") ? domain : `.${domain}`));
  return { cookies: all.filter((c: any) => matches(c.domain)) };
}

function installLifecycle(s: Session) {
  s.on("Network.requestWillBeSent", (p) => {
    const type = resourceType(p.type);
    s.state.track(p.requestId, { type, frameId: p.frameId, loaderId: p.loaderId, postData: p.request?.postData });
    s.emit("Network.requestWillBeSent", {
      requestId: p.requestId, loaderId: p.loaderId ?? "", documentURL: p.documentURL ?? "",
      request: request(p.request, type === "Document" ? "VeryHigh" : "Medium"),
      timestamp: p.timestamp, wallTime: p.walltime, initiator: initiator(p.initiator, s.state.isAnnounced),
      redirectHasExtraInfo: false, ...(p.redirectResponse ? { redirectResponse: response(p.redirectResponse) } : {}),
      type, frameId: p.frameId, hasUserGesture: false,
    });
  });
  s.on("Network.responseReceived", (p) => {
    const tracked = s.state.requests.get(p.requestId);
    const res = response(p.response);
    if (tracked) {
      tracked.response = res;
      tracked.lastTimestamp = p.timestamp;
    }
    if (p.response?.source === "memory-cache") s.emit("Network.requestServedFromCache", { requestId: p.requestId });
    s.emit("Network.responseReceived", {
      requestId: p.requestId, loaderId: p.loaderId ?? "", timestamp: p.timestamp,
      type: tracked?.type ?? resourceType(p.type), response: res, hasExtraInfo: false, frameId: p.frameId,
    });
  });
  s.on("Network.dataReceived", (p) => {
    const tracked = s.state.requests.get(p.requestId);
    if (tracked) tracked.lastTimestamp = p.timestamp;
    s.emit("Network.dataReceived", p);
  });
  s.on("Network.loadingFinished", (p) => finish(s, p));
  s.on("Network.loadingFailed", (p) => s.emit("Network.loadingFailed", {
    requestId: p.requestId, timestamp: p.timestamp, type: s.state.requests.get(p.requestId)?.type ?? "Other",
    errorText: p.errorText ?? "", canceled: !!p.canceled,
  }));
  s.on("Network.requestServedFromMemoryCache", (p) => fromMemoryCache(s, p));
}

// Chrome takes a response's details only while the request is in flight, so
// the details that come with `metrics` are sent as a second response just
// before the request finishes.
function finish(s: Session, p: any) {
  const tracked = s.state.requests.get(p.requestId);
  const metrics = p.metrics;
  // WebKit can stamp the finish a little before the last data it reported.
  const timestamp = Math.max(p.timestamp, tracked?.lastTimestamp ?? 0);
  if (metrics && tracked?.response) {
    const newPriority = priority(metrics.priority);
    if (newPriority) s.emit("Network.resourceChangedPriority", { requestId: p.requestId, newPriority, timestamp });
    s.emit("Network.responseReceived", {
      requestId: p.requestId, loaderId: tracked.loaderId ?? "", timestamp, type: tracked.type,
      response: enrich(tracked.response, metrics), hasExtraInfo: false, frameId: tracked.frameId,
    });
  }
  s.emit("Network.loadingFinished", { requestId: p.requestId, timestamp, encodedDataLength: encodedLength(metrics) });
}

// WebKit reports a memory-cache hit as one event; Chrome expects the whole
// lifecycle, marked as served from cache.
function fromMemoryCache(s: Session, p: any) {
  const resource = p.resource ?? {};
  const type = resourceType(resource.type);
  const base = { requestId: p.requestId, loaderId: p.loaderId ?? "", timestamp: p.timestamp };
  s.state.track(p.requestId, { type, frameId: p.frameId, loaderId: p.loaderId });
  s.emit("Network.requestWillBeSent", {
    ...base, documentURL: p.documentURL ?? "", request: request({ url: resource.url, method: "GET" }),
    wallTime: Date.now() / 1000, initiator: initiator(p.initiator, s.state.isAnnounced), redirectHasExtraInfo: false,
    type, frameId: p.frameId, hasUserGesture: false,
  });
  s.emit("Network.requestServedFromCache", { requestId: p.requestId });
  s.emit("Network.responseReceived", {
    ...base, type, frameId: p.frameId, hasExtraInfo: false, response: response(resource.response ?? { url: resource.url, status: 200 }),
  });
  s.emit("Network.dataReceived", { requestId: p.requestId, timestamp: p.timestamp, dataLength: resource.bodySize ?? 0, encodedDataLength: 0 });
  s.emit("Network.loadingFinished", { requestId: p.requestId, timestamp: p.timestamp, encodedDataLength: 0 });
}

function installWebSockets(s: Session) {
  s.on("Network.webSocketCreated", (p) => s.emit("Network.webSocketCreated", { requestId: p.requestId, url: p.url }));
  s.on("Network.webSocketWillSendHandshakeRequest", (p) => s.emit("Network.webSocketWillSendHandshakeRequest", {
    requestId: p.requestId, timestamp: p.timestamp, wallTime: p.walltime, request: { headers: p.request?.headers ?? {} },
  }));
  s.on("Network.webSocketHandshakeResponseReceived", (p) => s.emit("Network.webSocketHandshakeResponseReceived", {
    requestId: p.requestId, timestamp: p.timestamp,
    response: { status: p.response?.status, statusText: p.response?.statusText ?? "", headers: p.response?.headers ?? {} },
  }));
  for (const event of ["Network.webSocketFrameReceived", "Network.webSocketFrameSent"]) {
    s.on(event, (p) => s.emit(event, {
      requestId: p.requestId, timestamp: p.timestamp,
      response: { opcode: p.response?.opcode, mask: !!p.response?.mask, payloadData: p.response?.payloadData ?? "" },
    }));
  }
  s.on("Network.webSocketFrameError", (p) => s.emit("Network.webSocketFrameError", p));
  s.on("Network.webSocketClosed", (p) => s.emit("Network.webSocketClosed", p));
}
