// WebKit reports everything the console shows as Console.messageAdded.
// Chrome splits the same stream three ways: console API calls, uncaught
// exceptions, and browser-side entries such as network or security errors.

import type { Session } from "./session";
import { replay } from "./replay";
import { remoteObject, stackTrace, zeroBased } from "./values";

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
      last = translate(s, await withPreviews(s, message));
      if (last) s.emit(last.method, last.params);
    });
  });
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

function apiCall(s: Session, m: any) {
  const type = m.type === "log" || !m.type ? level(m.level) : API_TYPES[m.type] ?? "log";
  const args = m.parameters?.length ? m.parameters.map(remoteObject) : [{ type: "string", value: m.text ?? "" }];
  return {
    type,
    args,
    executionContextId: s.state.mainContextId || 1,
    timestamp: Date.now(),
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
    timestamp: Date.now(),
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
    timestamp: Date.now(),
    url: m.url,
    lineNumber: m.line ? zeroBased(m.line) : undefined,
    stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced),
    networkRequestId: m.networkRequestId,
  };
}
