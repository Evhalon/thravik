// WebKit reports everything the console shows as Console.messageAdded.
// Chrome splits the same stream three ways: console API calls, uncaught
// exceptions, and browser-side entries such as network or security errors.

import type { Session } from "./session";
import { replay } from "./replay";
import { remoteObject, stackTrace, zeroBased } from "./values";
import { withStack } from "./errors";

const API_TYPES: Record<string, string> = {
  dir: "dir", dirxml: "dirxml", table: "table", trace: "trace", clear: "clear",
  startGroup: "startGroup", startGroupCollapsed: "startGroupCollapsed", endGroup: "endGroup",
  assert: "assert", timing: "timeEnd", profile: "profile", profileEnd: "profileEnd",
};

const LOG_SOURCES = new Set(["xml", "javascript", "network", "storage", "rendering", "security", "other"]);

// WebKit reports an uncaught exception as a plain `javascript` error whose
// text starts with the error's name; other `javascript` errors — a blocked
// fetch, say — are messages, not exceptions.
const EXCEPTION = /^(Unhandled Promise Rejection: )?([A-Z]\w*(Error|Exception)|Error)(: |$)/;
const IN_PROMISE = "Unhandled Promise Rejection: ";

export function installConsole(s: Session) {
  s.handle("Log.enable", () => replay(s, "Console"));
  s.handle("Log.clear", () => s.call("Console.clearMessages"));
  let last: { method: string; params: any } | null = null;
  // Previews are fetched for some messages, so a queue keeps them in order.
  let queue = Promise.resolve();
  s.on("Console.messageAdded", ({ message }) => {
    queue = queue.then(async () => {
      last = await withErrorStacks(s, translate(s, await withPreviews(s, message)));
      if (last) s.emit(last.method, last.params);
    });
  });
  // The command line's `clear()`; `console.clear()` arrives as a message.
  s.on("Console.messagesCleared", ({ reason }) => {
    if (reason !== "console-api") return;
    s.emit("Runtime.consoleAPICalled", {
      type: "clear", args: [{ type: "string", value: "console.clear" }],
      executionContextId: s.state.mainContextId || 1, timestamp: Date.now(),
    });
  });
  s.on("Inspector.inspect", ({ object, hints }) => inspectRequested(s, object, hints ?? {}));
  // Chrome has no repeat count; it folds identical messages on its own.
  s.on("Console.messageRepeatCountUpdated", () => {
    if (last) s.emit(last.method, { ...last.params, timestamp: Date.now() });
  });
}

function translate(s: Session, m: any): { method: string; params: any } | null {
  if (!m) return null;
  if (m.source === "console-api") return { method: "Runtime.consoleAPICalled", params: apiCall(s, m) };
  if (m.source === "javascript" && m.level === "error" && EXCEPTION.test(m.text ?? "")) {
    return { method: "Runtime.exceptionThrown", params: exception(s, m) };
  }
  return { method: "Log.entryAdded", params: { entry: logEntry(s, m) } };
}

// WebKit reports `console.count` as a debug message with no arguments,
// where `console.debug` always has at least one.
function apiType(m: any): string {
  if (m.type === "log" || !m.type) return m.level === "debug" && !m.parameters?.length ? "count" : level(m.level);
  return API_TYPES[m.type] ?? "log";
}

/** WebKit stamps messages in seconds; one without a stamp is new. */
function timestamp(m: any): number {
  return typeof m.timestamp === "number" && m.timestamp > 1e9 ? m.timestamp * 1000 : Date.now();
}

async function withErrorStacks(s: Session, t: { method: string; params: any } | null) {
  if (!t) return t;
  if (t.method === "Runtime.consoleAPICalled") {
    t.params.args = await Promise.all(t.params.args.map((a: any) => withStack(s, a)));
  } else if (t.method === "Runtime.exceptionThrown") {
    t.params.exceptionDetails.exception = await withStack(s, t.params.exceptionDetails.exception);
  }
  return t;
}

function apiCall(s: Session, m: any) {
  const type = apiType(m);
  const args = m.parameters?.length ? m.parameters.map(remoteObject) : [{ type: "string", value: m.text ?? "" }];
  return {
    type,
    args,
    executionContextId: s.state.mainContextId || 1,
    timestamp: timestamp(m),
    stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced),
  };
}

function level(l: string | undefined): string {
  if (l === "warning" || l === "error" || l === "info" || l === "debug") return l;
  return "log";
}

// Messages WebKit replays when a session starts come without the previews
// Chrome draws inline, like `{a: 1, b: {…}}`.
async function withPreviews(s: Session, m: any): Promise<any> {
  if (!m?.parameters?.some((p: any) => p.objectId && !p.preview)) return m;
  const parameters = await Promise.all(m.parameters.map(async (p: any) => {
    if (!p.objectId || p.preview) return p;
    const r = await s.call("Runtime.getPreview", { objectId: p.objectId }).catch(() => ({}));
    return r.preview ? { ...p, preview: r.preview } : p;
  }));
  return { ...m, parameters };
}

function exception(s: Session, m: any) {
  const trace = stackTrace(m.stackTrace, s.state.isAnnounced);
  const top = trace?.callFrames.find((f: any) => f.url !== "[native code]") ?? trace?.callFrames[0];
  const inPromise = (m.text ?? "").startsWith(IN_PROMISE);
  const text: string = inPromise ? m.text.slice(IN_PROMISE.length) : m.text ?? "Error";
  const thrown = m.parameters?.[0]
    ? remoteObject(m.parameters[0])
    : { type: "object", subtype: "error", className: text.split(":")[0] || "Error", description: text };
  return {
    timestamp: timestamp(m),
    exceptionDetails: {
      exceptionId: 1,
      text: inPromise ? "Uncaught (in promise)" : "Uncaught",
      url: m.url ?? top?.url,
      lineNumber: top?.lineNumber ?? zeroBased(m.line),
      columnNumber: top?.columnNumber ?? zeroBased(m.column),
      scriptId: top?.scriptId,
      stackTrace: trace,
      exception: thrown,
      executionContextId: s.state.mainContextId || 1,
    },
  };
}

function logEntry(s: Session, m: any) {
  return {
    source: LOG_SOURCES.has(m.source) ? m.source : m.source === "css" ? "rendering" : "other",
    level: m.level === "debug" ? "verbose" : m.level === "log" ? "info" : m.level,
    text: m.text ?? "",
    timestamp: timestamp(m),
    url: m.url,
    lineNumber: m.line ? zeroBased(m.line) : undefined,
    stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced),
    networkRequestId: m.networkRequestId,
  };
}

// `copy()` and `inspect()` ask the frontend to act on a value. WebKit's own
// hidden Web Inspector hears the same request and releases the value once it
// is done with it, before Chrome has read it — so the value is taken into a
// group of the bridge's own first. The first call goes out before the hidden
// Web Inspector sees the event, and so reaches the page in time.
async function inspectRequested(s: Session, object: any, hints: any) {
  let held = object;
  if (object?.objectId) {
    const stash = s.call("Runtime.callFunctionOn", {
      objectId: object.objectId, functionDeclaration: `function () { globalThis[${JSON.stringify(HELD)}] = this; }`,
    });
    await stash.catch(() => {});
    const r = await s.call("Runtime.evaluate", {
      expression: `(() => { const v = globalThis[${JSON.stringify(HELD)}]; delete globalThis[${JSON.stringify(HELD)}]; return v; })()`,
      objectGroup: "redent-inspected", generatePreview: true, contextId: s.state.mainContextId || undefined,
    }).catch(() => null);
    if (r?.result?.objectId) held = r.result;
  }
  s.emit("Runtime.inspectRequested", { object: remoteObject(held), hints, executionContextId: s.state.mainContextId || 1 });
}

const HELD = "__redentInspected";
