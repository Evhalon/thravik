// The Console's command-line helpers WebKit lacks — `$_`, `monitor` and
// `unmonitor` — and the top-level `let`/`const` names Chrome completes from.
//
// Helpers WebKit has already (`$`, `$$`, `$x`, `$0`, `copy`, `inspect`,
// `keys`, `values`, `dir`, `table`, `queryObjects`, `getEventListeners`,
// `monitorEvents`, `debug` …) are left to it.

import type { Session } from "./session";

const MONITOR_PRELUDE = `(() => {
  if (typeof globalThis.monitor === "function") return;
  const queue = [];
  const define = (name, value) => Object.defineProperty(globalThis, name, { value, configurable: true, writable: true });
  define("__redentMonitorQueue", queue);
  define("monitor", (fn) => { if (typeof fn === "function") queue.push([true, fn]); });
  define("unmonitor", (fn) => { if (typeof fn === "function") queue.push([false, fn]); });
})()`;

const USES_MONITOR = /\b(un)?monitor\s*\(/;
const RESERVED = new Set([
  "await", "yield", "let", "static", "enum", "implements", "interface", "package", "private", "protected", "public",
  "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "export",
  "extends", "false", "finally", "for", "function", "if", "import", "in", "instanceof", "new", "null", "return",
  "super", "switch", "this", "throw", "true", "try", "typeof", "var", "void", "while", "with",
]);
const LEXICAL = /(?:^|[;\n{}]\s*)(?:let|const|class)\s+([A-Za-z_$][\w$]*)/g;

export class ConsoleHelpers {
  private monitors = new Map<string, string>();
  private typedNames = new Set<string>();

  constructor(private s: Session) {}

  /** Before a console command runs: defines what it needs from here. */
  async prepare(expression: string, contextId: number | undefined) {
    for (const match of expression.matchAll(LEXICAL)) this.typedNames.add(match[1]);
    if (!USES_MONITOR.test(expression)) return;
    await this.s.call("Runtime.evaluate", { expression: MONITOR_PRELUDE, contextId, doNotPauseOnExceptionsAndMuteConsole: true });
  }

  /** After a console command ran: remembers its value as `$_`, and turns
   *  queued `monitor` calls into logging breakpoints. */
  async finish(result: any, contextId: number | undefined) {
    await this.s.call("Runtime.callFunctionOn", {
      objectId: await this.globalObject(contextId),
      functionDeclaration: "function (value) { Object.defineProperty(this, '$_', { value, configurable: true, writable: true }); }",
      arguments: [result?.objectId ? { objectId: result.objectId } : { value: result?.value }],
    }).catch(() => {});
    await this.applyMonitors(contextId).catch(() => {});
    this.release();
  }

  private async globalObject(contextId: number | undefined): Promise<string> {
    const r = await this.s.call("Runtime.evaluate", { expression: "globalThis", contextId, objectGroup: "redent-console" });
    return r.result?.objectId;
  }

  /** Lets go of the objects this helper looked at. */
  release() {
    this.s.call("Runtime.releaseObjectGroup", { objectGroup: "redent-console" }).catch(() => {});
  }

  private async applyMonitors(contextId: number | undefined) {
    const r = await this.s.call("Runtime.evaluate", {
      expression: "globalThis.__redentMonitorQueue ? globalThis.__redentMonitorQueue.splice(0) : []",
      contextId, objectGroup: "redent-console",
    });
    const list = await this.s.call("Runtime.getProperties", { objectId: r.result?.objectId, ownProperties: true });
    for (const entry of list.properties ?? []) {
      if (!/^\d+$/.test(entry.name) || !entry.value?.objectId) continue;
      const pair = await this.s.call("Runtime.getProperties", { objectId: entry.value.objectId, ownProperties: true });
      const on = pair.properties?.find((p: any) => p.name === "0")?.value?.value;
      const fn = pair.properties?.find((p: any) => p.name === "1")?.value;
      if (fn?.objectId) await this.monitor(fn.objectId, !!on);
    }
  }

  private async monitor(functionId: string, on: boolean) {
    const details = (await this.s.call("Debugger.getFunctionDetails", { functionId })).details;
    const key = `${details.location.scriptId}:${details.location.lineNumber}:${details.location.columnNumber}`;
    const existing = this.monitors.get(key);
    if (existing) {
      await this.s.call("Debugger.removeBreakpoint", { breakpointId: existing });
      this.monitors.delete(key);
    }
    if (!on) return;
    const name = details.displayName || details.name || "(anonymous)";
    const shape = await this.shape(details.location);
    // A breakpoint action runs where `arguments` is out of reach, so the
    // parameters are read by name.
    const values = shape.params.length ? ` + " with arguments: " + [${shape.params.join(", ")}].join(", ")` : "";
    const log = `console.log(${JSON.stringify(`function ${name} called`)}${values})`;
    const r = await this.s.call("Debugger.setBreakpoint", {
      location: shape.body, options: { autoContinue: true, actions: [{ type: "evaluate", data: log }] },
    });
    this.monitors.set(key, r.breakpointId);
  }

  /** WebKit places a function at its name, which is a statement of the
   *  code around it; the breakpoint belongs just inside the body. */
  private async shape(location: any): Promise<{ body: any; params: string[] }> {
    const fetch = (id: string) => this.s.call("Debugger.getScriptSource", { scriptId: id });
    const source = await this.s.state.scriptSource(location.scriptId, fetch);
    const lines = source.split("\n");
    const from = lines.slice(0, location.lineNumber).reduce((n, line) => n + line.length + 1, 0) + (location.columnNumber ?? 0);
    const shape = functionShape(source, from);
    if (!shape) return { body: location, params: [] };
    const before = source.slice(0, shape.body).split("\n");
    return {
      body: { scriptId: location.scriptId, lineNumber: before.length - 1, columnNumber: before[before.length - 1].length },
      params: shape.params,
    };
  }

  /** Top-level `let`, `const` and `class` names, from the page's scripts
   *  and the console's own commands, that the global scope really holds. */
  async lexicalNames(contextId: number | undefined): Promise<string[]> {
    const candidates = new Set(this.typedNames);
    for (const scriptId of this.s.state.scripts.keys()) {
      const source = await this.s.state.scriptSource(scriptId, (id) => this.s.call("Debugger.getScriptSource", { scriptId: id }));
      for (const match of source.matchAll(LEXICAL)) candidates.add(match[1]);
    }
    const names = [...candidates].filter((n) => !RESERVED.has(n));
    if (!names.length) return [];
    // Each name is read directly: a name that is not declared throws, and a
    // page's content security policy would refuse `eval`.
    const checks = names.map((n) => `(() => { try { ${n}; return ${JSON.stringify(n)}; } catch { return null; } })()`);
    const r = await this.s.call("Runtime.evaluate", {
      expression: `[${checks.join(",")}].filter((n) => n && !(n in globalThis))`,
      contextId, returnByValue: true, doNotPauseOnExceptionsAndMuteConsole: true,
    });
    return Array.isArray(r.result?.value) ? r.result.value : [];
  }
}

/** Where a function's body begins, from where its declaration does — past
 *  its parameter list, and past `{` or `=>` — and its plain parameter names.
 *  Null when the source says otherwise. */
export function functionShape(source: string, from: number): { body: number; params: string[] } | null {
  const arrow = source.indexOf("=>", from);
  const paren = source.indexOf("(", from);
  if (paren < 0 && arrow < 0) return null;
  let i: number;
  let list: string;
  if (paren >= 0 && (arrow < 0 || paren < arrow)) {
    let depth = 0;
    for (i = paren; i < source.length; i++) {
      if (source[i] === "(") depth++;
      else if (source[i] === ")" && --depth === 0) break;
    }
    list = source.slice(paren + 1, i);
    i++;
  } else {
    list = source.slice(from, arrow);
    i = arrow;
  }
  while (/\s/.test(source[i] ?? "")) i++;
  if (source.startsWith("=>", i)) {
    i += 2;
    while (/\s/.test(source[i] ?? "")) i++;
  }
  if (i >= source.length) return null;
  const names = list.split(",").map((p) => p.trim().replace(/^\.\.\./, "").split("=")[0].trim());
  const params = names.every((n) => /^[A-Za-z_$][\w$]*$/.test(n)) ? names : [];
  return { body: source[i] === "{" ? i + 1 : i, params };
}
