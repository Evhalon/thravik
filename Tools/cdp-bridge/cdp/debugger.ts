// Debugger: parsed scripts (so console links open in Sources), breakpoints,
// stepping, and pausing. WebKit's debugger locations already count from 0.

import type { Session } from "./session";
import { replay } from "./replay";
import { evaluation, remoteObject, stackTrace } from "./values";

const PAUSE_REASONS: Record<string, string> = {
  exception: "exception", assert: "assert", CSPViolation: "CSPViolation", DOM: "DOM", Listener: "EventListener", URL: "XHR",
};

const SCOPE_TYPES: Record<string, string> = {
  global: "global", with: "with", closure: "closure", catch: "catch", functionName: "closure",
  globalLexicalEnvironment: "script", nestedLexical: "block",
};

export function installDebugger(s: Session) {
  s.handle("Debugger.enable", async () => {
    s.state.debuggerEnabled = true;
    await replay(s, "Debugger");
    return { debuggerId: "redent" };
  });
  s.handle("Debugger.disable", () => ({}));
  s.handle("Debugger.getScriptSource", (p) => s.call("Debugger.getScriptSource", { scriptId: p.scriptId }));
  s.handle("Debugger.setBreakpointByUrl", (p) => s.call("Debugger.setBreakpointByUrl", {
    lineNumber: p.lineNumber, url: p.url, urlRegex: p.urlRegex, columnNumber: p.columnNumber,
    options: p.condition ? { condition: p.condition } : {},
  }));
  s.handle("Debugger.getPossibleBreakpoints", () => ({ locations: [] }));
  s.handle("Debugger.setPauseOnExceptions", (p) => s.call("Debugger.setPauseOnExceptions", {
    state: p.state === "caught" ? "all" : p.state,
  }));
  s.handle("Debugger.evaluateOnCallFrame", async (p) => evaluation(await s.call("Debugger.evaluateOnCallFrame", {
    callFrameId: p.callFrameId, expression: p.expression, objectGroup: p.objectGroup,
    includeCommandLineAPI: p.includeCommandLineAPI, doNotPauseOnExceptionsAndMuteConsole: p.silent,
    returnByValue: p.returnByValue, generatePreview: p.generatePreview,
  })));
  s.handle("Debugger.setAsyncCallStackDepth", (p) => s.call("Debugger.setAsyncStackTraceDepth", { depth: p.maxDepth ?? 0 }));
  for (const method of ["removeBreakpoint", "setBreakpointsActive", "continueToLocation", "pause", "resume", "stepOver", "stepInto", "stepOut"]) {
    s.handle(`Debugger.${method}`, (p) => s.call(`Debugger.${method}`, forwarded(method, p)));
  }
  installEvents(s);
}

function forwarded(method: string, p: any): any {
  if (method === "removeBreakpoint") return { breakpointId: p.breakpointId };
  if (method === "setBreakpointsActive") return { active: !!p.active };
  if (method === "continueToLocation") return { location: p.location };
  return {};
}

function installEvents(s: Session) {
  s.on("Debugger.scriptParsed", (p) => {
    // Redent's own scripts run in isolated worlds; they are not the page's.
    if (p.isContentScript) return;
    const url = p.url || p.sourceURL || "";
    s.state.scripts.set(p.scriptId, url);
    s.emit("Debugger.scriptParsed", {
      scriptId: p.scriptId, url, startLine: p.startLine, startColumn: p.startColumn,
      endLine: p.endLine, endColumn: p.endColumn, executionContextId: s.state.mainContextId || 1,
      hash: "", isModule: !!p.module, sourceMapURL: p.sourceMapURL ?? "", hasSourceURL: !!p.sourceURL,
      scriptLanguage: "JavaScript",
    });
  });
  s.on("Debugger.paused", (p) => s.emit("Debugger.paused", {
    callFrames: (p.callFrames ?? []).map((f: any) => callFrame(s, f)),
    reason: PAUSE_REASONS[p.reason] ?? "other",
    data: p.data,
    ...(p.data?.breakpointId ? { hitBreakpoints: [p.data.breakpointId] } : {}),
    ...(p.asyncStackTrace ? { asyncStackTrace: stackTrace(p.asyncStackTrace) } : {}),
  }));
  s.on("Debugger.resumed", () => s.emit("Debugger.resumed", {}));
  s.on("Debugger.breakpointResolved", (p) => s.emit("Debugger.breakpointResolved", p));
}

function callFrame(s: Session, f: any) {
  let sawLocal = false;
  const scopeChain = (f.scopeChain ?? []).map((scope: any) => {
    let type = SCOPE_TYPES[scope.type] ?? "closure";
    if (type === "closure" && !sawLocal) {
      type = "local";
      sawLocal = true;
    }
    return { type, object: remoteObject(scope.object), ...(scope.name ? { name: scope.name } : {}) };
  });
  return {
    callFrameId: f.callFrameId,
    functionName: f.functionName ?? "",
    location: f.location,
    url: s.state.scripts.get(f.location?.scriptId) ?? "",
    scopeChain,
    this: remoteObject(f.this),
  };
}
