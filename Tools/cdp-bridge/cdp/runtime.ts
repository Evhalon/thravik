// Runtime: execution contexts, evaluation, and object inspection — what the
// Console panel is built on.

import type { Session } from "./session";
import { evaluation } from "./values";
import { installProperties } from "./properties";
import { replay } from "./replay";

// Chrome's eager evaluation asks for side-effect-free runs while the user
// types. WebKit cannot promise that, so the answer is the error V8 gives for
// an expression with side effects, and nothing runs.
const SIDE_EFFECT = {
  result: { type: "object", subtype: "error", className: "EvalError", description: "EvalError: Possible side-effect in debug-evaluate" },
  exceptionDetails: { exceptionId: 1, text: "Uncaught", lineNumber: 0, columnNumber: 0 },
};

export function installRuntime(s: Session) {
  s.handle("Runtime.enable", async () => {
    await replay(s, "Runtime");
    await replay(s, "Console");
  });
  s.handle("Runtime.evaluate", (p) => evaluate(s, p));
  s.handle("Runtime.awaitPromise", async (p) => evaluation(await s.call("Runtime.awaitPromise", {
    promiseObjectId: p.promiseObjectId, returnByValue: p.returnByValue, generatePreview: p.generatePreview,
  })));
  s.handle("Runtime.callFunctionOn", (p) => callFunctionOn(s, p));
  s.handle("Runtime.releaseObject", (p) => s.call("Runtime.releaseObject", { objectId: p.objectId }));
  s.handle("Runtime.releaseObjectGroup", (p) => s.call("Runtime.releaseObjectGroup", { objectGroup: p.objectGroup }));
  s.handle("Runtime.compileScript", (p) => compile(s, p.expression));
  s.handle("Runtime.globalLexicalScopeNames", () => ({ names: [] }));
  s.handle("Runtime.getIsolateId", () => ({ id: "redent" }));
  s.handle("Runtime.getHeapUsage", () => ({ usedSize: 0, totalSize: 0 }));
  s.handle("Runtime.discardConsoleEntries", () => s.call("Console.clearMessages"));
  s.handle("Runtime.setAsyncCallStackDepth", (p) => s.call("Debugger.setAsyncStackTraceDepth", { depth: p.maxDepth ?? 0 }));
  installProperties(s);
  installContexts(s);
}

function contextId(p: any): number | undefined {
  if (p.uniqueContextId) return Number(p.uniqueContextId);
  return p.contextId ?? p.executionContextId;
}

async function evaluate(s: Session, p: any) {
  if (p.throwOnSideEffect) return SIDE_EFFECT;
  const params = {
    objectGroup: p.objectGroup,
    includeCommandLineAPI: p.includeCommandLineAPI,
    doNotPauseOnExceptionsAndMuteConsole: p.silent,
    contextId: contextId(p),
    returnByValue: p.returnByValue,
    generatePreview: p.generatePreview,
    emulateUserGesture: p.userGesture,
  };
  let r = await s.call("Runtime.evaluate", { ...params, expression: p.expression });
  let awaits = !!p.awaitPromise;
  // Chrome's console runs top-level `await`; WebKit only inside an async
  // function, so a failed parse is retried as one — first as an expression
  // whose value is the result, then as statements.
  if (p.replMode && r.wasThrown && /\bawait\b/.test(p.expression) && r.result?.className === "SyntaxError") {
    for (const body of [`return (${p.expression}\n);`, `${p.expression}\n`]) {
      r = await s.call("Runtime.evaluate", { ...params, expression: `(async () => { ${body} })()` });
      awaits = true;
      if (!(r.wasThrown && r.result?.className === "SyntaxError")) break;
    }
  }
  if (!awaits || r.wasThrown || r.result?.className !== "Promise" || !r.result.objectId) return evaluation(r);
  return evaluation(await s.call("Runtime.awaitPromise", {
    promiseObjectId: r.result.objectId, returnByValue: p.returnByValue, generatePreview: p.generatePreview,
  }));
}

async function callFunctionOn(s: Session, p: any) {
  if (p.throwOnSideEffect) return SIDE_EFFECT;
  const args = (p.arguments ?? []).map((a: any) => (a.objectId ? { objectId: a.objectId } : { value: a.value }));
  if (!p.objectId) {
    const values = args.map((a: any) => JSON.stringify(a.value ?? null)).join(", ");
    return evaluate(s, { ...p, expression: `(${p.functionDeclaration})(${values})`, contextId: p.executionContextId });
  }
  return evaluation(await s.call("Runtime.callFunctionOn", {
    objectId: p.objectId,
    functionDeclaration: p.functionDeclaration,
    arguments: args,
    doNotPauseOnExceptionsAndMuteConsole: p.silent,
    returnByValue: p.returnByValue,
    generatePreview: p.generatePreview,
    emulateUserGesture: p.userGesture,
    awaitPromise: p.awaitPromise,
  }));
}

// Chrome's console asks whether the input is complete before running it on
// Enter; V8's messages for unfinished input are what it looks for.
async function compile(s: Session, source: string) {
  const r = await s.call("Runtime.parse", { source });
  if (r.result === "none") return {};
  const description = r.result === "recoverable" ? "SyntaxError: Unexpected end of input"
    : r.result === "unterminated-literal" ? "SyntaxError: Unterminated template literal"
    : `SyntaxError: ${r.message ?? "Invalid syntax"}`;
  const exception = { type: "object", subtype: "error", className: "SyntaxError", description };
  return {
    exceptionDetails: {
      exceptionId: 1, text: "Uncaught", exception,
      lineNumber: 0, columnNumber: 0,
    },
  };
}

function installContexts(s: Session) {
  s.on("Runtime.executionContextCreated", ({ context }) => {
    // Redent's own isolated worlds and WebKit's internal ones stay private.
    if (!context || context.type !== "normal") return;
    s.state.addContext(context.id, context.frameId);
    s.emit("Runtime.executionContextCreated", {
      context: {
        id: context.id,
        uniqueId: String(context.id),
        name: context.name ?? "",
        origin: s.state.origin(context.frameId),
        auxData: { isDefault: true, type: "default", frameId: context.frameId },
      },
    });
  });
}
