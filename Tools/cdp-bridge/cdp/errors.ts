// Errors, drawn the way Chrome draws them. Chrome reads an error's stack out
// of its description, written as V8 writes it — `Error: boom\n    at f
// (url:1:2)`. WebKit's description is the first line alone and its stack
// uses Safari's `f@url:1:2`, so the bridge fetches the stack and rewrites it.

import type { Session } from "./session";
import { ProtocolError } from "./session";

const READ_ERROR = `function () {
  return { text: String(this), stack: typeof this.stack === "string" ? this.stack : "",
    line: this.line, column: this.column, url: this.sourceURL };
}`;

type Frame = { functionName: string; url: string; lineNumber: number; columnNumber: number };

/** Safari's `name@url:line:column` stack lines, one-based. */
export function parseStack(stack: string): Frame[] {
  const frames: Frame[] = [];
  for (const line of stack.split("\n")) {
    if (!line.trim()) continue;
    const at = line.lastIndexOf("@");
    const name = at >= 0 ? line.slice(0, at) : "";
    const location = at >= 0 ? line.slice(at + 1) : line;
    const match = /^(.*):(\d+):(\d+)$/.exec(location);
    if (!match) {
      if (location === "[native code]") frames.push({ functionName: name, url: "native", lineNumber: 0, columnNumber: 0 });
      continue;
    }
    frames.push({ functionName: name, url: match[1], lineNumber: Number(match[2]), columnNumber: Number(match[3]) });
  }
  return frames;
}

function v8Line(f: Frame): string {
  const name = f.functionName === "global code" || f.functionName === "eval code" ? "" : f.functionName;
  const where = f.url === "native" ? "native" : `${f.url || "<anonymous>"}:${f.lineNumber}:${f.columnNumber}`;
  return name ? `    at ${name} (${where})` : `    at ${where}`;
}

async function readError(s: Session, objectId: string): Promise<any> {
  const r = await s.call("Runtime.callFunctionOn", { objectId, functionDeclaration: READ_ERROR, returnByValue: true });
  return r.wasThrown ? null : r.result?.value;
}

/** A CDP remote error object with its stack written into its description. */
export async function withStack(s: Session, o: any): Promise<any> {
  if (o?.subtype !== "error" || !o.objectId) return o;
  const e = await readError(s, o.objectId).catch(() => null);
  if (!e) return o;
  const frames = parseStack(e.stack);
  const head = o.description ?? e.text;
  return frames.length ? { ...o, description: [head, ...frames.map(v8Line)].join("\n") } : o;
}

export function installErrors(s: Session) {
  s.handle("Runtime.getExceptionDetails", async (p) => {
    const e = await readError(s, p.errorObjectId);
    if (!e) throw new ProtocolError("Could not read the error");
    const frames = parseStack(e.stack);
    return {
      exceptionDetails: {
        exceptionId: 1,
        text: e.text,
        lineNumber: Math.max(0, (e.line ?? 1) - 1),
        columnNumber: Math.max(0, (e.column ?? 1) - 1),
        ...(e.url ? { url: e.url } : {}),
        ...(frames.length ? {
          stackTrace: {
            callFrames: frames.filter((f) => f.url !== "native").map((f) => ({
              functionName: f.functionName === "global code" ? "" : f.functionName,
              scriptId: "", url: f.url, lineNumber: f.lineNumber - 1, columnNumber: f.columnNumber - 1,
            })),
          },
        } : {}),
      },
    };
  });
}
