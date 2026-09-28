// WebKit's network records reshaped into the ones Chrome's Network panel
// reads. WebKit only knows a request's protocol, remote address, priority,
// sizes and the headers it really sent once loading finishes; they arrive
// in `metrics`, and `enrich` folds them in.

import { stackTrace, zeroBased } from "./values";

const REFERRER_POLICIES = new Set([
  "no-referrer", "no-referrer-when-downgrade", "same-origin", "origin", "strict-origin",
  "origin-when-cross-origin", "strict-origin-when-cross-origin", "unsafe-url",
]);

export function request(r: any, priority = "Medium"): any {
  return {
    url: r.url,
    method: r.method,
    headers: r.headers ?? {},
    ...(r.postData != null ? { postData: r.postData, hasPostData: true } : {}),
    initialPriority: priority,
    referrerPolicy: REFERRER_POLICIES.has(r.referrerPolicy) ? r.referrerPolicy : "strict-origin-when-cross-origin",
    mixedContentType: "none",
  };
}

export function initiator(i: any, isKnown: (scriptId: string) => boolean): any {
  if (!i) return { type: "other" };
  const out: any = { type: i.type ?? "other" };
  const stack = stackTrace(i.stackTrace, isKnown);
  if (stack) out.stack = stack;
  if (i.url) out.url = i.url;
  if (i.lineNumber != null) out.lineNumber = zeroBased(i.lineNumber);
  return out;
}

export function response(r: any): any {
  const url: string = r.url ?? "";
  return {
    url,
    status: r.status,
    statusText: r.statusText ?? "",
    headers: r.headers ?? {},
    mimeType: r.mimeType ?? "",
    charset: "",
    connectionReused: false,
    connectionId: 0,
    encodedDataLength: 0,
    fromDiskCache: r.source === "disk-cache",
    fromServiceWorker: r.source === "service-worker",
    securityState: /^(https|wss):/.test(url) ? "secure" : /^(http|ws):/.test(url) ? "insecure" : "neutral",
    ...(r.timing ? { timing: timing(r.timing) } : {}),
    ...(r.requestHeaders ? { requestHeaders: r.requestHeaders } : {}),
  };
}

// WebKit: a start time in seconds and millisecond offsets from it, with -1
// for a phase that did not happen. Chrome's shape is the same idea.
function timing(t: any): any {
  const at = (v: unknown) => (typeof v === "number" && v >= 0 ? v : -1);
  // A reused connection reports its lookup and connect phases as 0 to 0.
  const phase = (start: unknown, end: unknown) => (at(start) >= 0 && at(end) > at(start) ? [at(start), at(end)] : [-1, -1]);
  const [dnsStart, dnsEnd] = phase(t.domainLookupStart, t.domainLookupEnd);
  const [connectStart, connectEnd] = phase(t.connectStart, t.connectEnd);
  const [sslStart, sslEnd] = phase(t.secureConnectionStart, t.connectEnd);
  return {
    requestTime: t.startTime,
    proxyStart: -1, proxyEnd: -1,
    dnsStart, dnsEnd, connectStart, connectEnd, sslStart, sslEnd,
    workerStart: -1, workerReady: -1, workerFetchStart: -1, workerRespondWithSettled: -1,
    sendStart: at(t.requestStart), sendEnd: at(t.requestStart),
    pushStart: 0, pushEnd: 0,
    receiveHeadersStart: at(t.responseStart), receiveHeadersEnd: at(t.responseStart),
  };
}

/** The response once `metrics` are known. */
export function enrich(res: any, metrics: any): any {
  const out = { ...res };
  if (metrics.protocol) out.protocol = metrics.protocol;
  if (metrics.requestHeaders) out.requestHeaders = metrics.requestHeaders;
  const address = /^\[?([^\]]+?)\]?:(\d+)$/.exec(metrics.remoteAddress ?? "");
  if (address) {
    out.remoteIPAddress = address[1];
    out.remotePort = Number(address[2]);
  }
  if (metrics.connectionIdentifier) out.connectionId = hash(metrics.connectionIdentifier);
  out.encodedDataLength = encodedLength(metrics);
  return out;
}

export function encodedLength(metrics: any): number {
  return (metrics?.responseHeaderBytesReceived ?? 0) + (metrics?.responseBodyBytesReceived ?? 0);
}

export function priority(p: string | undefined): string | undefined {
  return p ? p.charAt(0).toUpperCase() + p.slice(1) : undefined;
}

// Chrome groups requests by a numeric connection id; WebKit's is a UUID.
function hash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return h;
}

/** WebKit Page.Cookie → CDP Network.Cookie. */
export function cookie(c: any): any {
  const expires = typeof c.expires === "number" && !c.session ? (c.expires > 1e11 ? c.expires / 1000 : c.expires) : -1;
  return {
    name: c.name,
    value: c.value,
    domain: c.domain,
    path: c.path,
    expires,
    size: (c.name?.length ?? 0) + (c.value?.length ?? 0),
    httpOnly: !!c.httpOnly,
    secure: !!c.secure,
    session: !!c.session,
    ...(c.sameSite && c.sameSite !== "None" ? { sameSite: c.sameSite } : {}),
    priority: "Medium",
    sameParty: false,
    sourceScheme: c.secure ? "Secure" : "NonSecure",
    sourcePort: c.secure ? 443 : 80,
  };
}
