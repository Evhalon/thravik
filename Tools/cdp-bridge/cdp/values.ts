// Shapes both protocols share with small differences: remote objects, their
// previews, and stack traces. WebKit counts script lines and columns from 1
// in console stack traces; the Chrome DevTools Protocol counts from 0.

const SUBTYPES = new Set([
  "array", "null", "node", "regexp", "date", "map", "set", "weakmap", "weakset",
  "iterator", "generator", "error", "proxy", "promise", "typedarray", "arraybuffer", "dataview",
]);

// Kinds WebKit leaves to the class name, which Chrome marks as a subtype.
const SUBTYPES_BY_CLASS: Record<string, string> = {
  Promise: "promise", ArrayBuffer: "arraybuffer", SharedArrayBuffer: "arraybuffer", DataView: "dataview",
  Generator: "generator", AsyncGenerator: "generator",
};
const TYPED_ARRAY = /^(Big)?(Int|Uint|Float)(8|16|32|64)(Clamped)?Array$/;

function subtype(o: any): string | undefined {
  if (o.subtype && SUBTYPES.has(o.subtype)) return o.subtype;
  if (o.type !== "object" || !o.className) return undefined;
  return SUBTYPES_BY_CLASS[o.className] ?? (TYPED_ARRAY.test(o.className) ? "typedarray" : undefined);
}

/** WebKit Runtime.RemoteObject → CDP Runtime.RemoteObject. */
export function remoteObject(o: any): any {
  if (!o || typeof o !== "object") return o;
  const out: any = { ...o };
  delete out.subtype;
  const kind = subtype(o);
  if (kind) out.subtype = kind;
  // WebKit reports a class as a function subtype; CDP has no such subtype.
  if (o.subtype === "class") out.className = o.className ?? "Function";
  if (o.type === "number" && o.value === undefined && o.description) {
    out.unserializableValue = o.description;
  }
  if (o.type === "bigint") {
    out.unserializableValue = o.description;
    delete out.value;
  }
  if (o.preview) out.preview = preview(o.preview);
  delete out.size;
  delete out.classPrototype;
  return out;
}

/** WebKit Runtime.ObjectPreview → CDP Runtime.ObjectPreview. */
export function preview(p: any): any {
  if (!p) return p;
  const out: any = {
    type: p.type,
    description: p.description,
    overflow: !!p.overflow,
    properties: (p.properties ?? []).map((q: any) => (q.internal ? internalPreview(q) : propertyPreview(q))).filter(Boolean),
  };
  if (p.subtype && SUBTYPES.has(p.subtype)) out.subtype = p.subtype;
  if (p.entries) out.entries = p.entries.map((e: any) => ({
    ...(e.key ? { key: preview(e.key) } : {}),
    value: preview(e.value),
  }));
  return out;
}

/** WebKit's internal slots, as the `[[Name]]` Chrome shows them under. */
export const INTERNAL_NAMES: Record<string, string> = {
  status: "[[PromiseState]]",
  result: "[[PromiseResult]]",
  targetFunction: "[[TargetFunction]]",
  boundThis: "[[BoundThis]]",
  boundArgs: "[[BoundArgs]]",
  target: "[[Target]]",
  handler: "[[Handler]]",
  iteratedObject: "[[IteratorTarget]]",
  iterationKind: "[[IteratorKind]]",
};

export function internalName(name: string): string {
  return INTERNAL_NAMES[name] ?? `[[${name.charAt(0).toUpperCase()}${name.slice(1)}]]`;
}

function internalPreview(q: any): any {
  const out = propertyPreview(q);
  out.name = internalName(q.name);
  if (q.name === "status" && out.value === "resolved") out.value = "fulfilled";
  return out;
}

function propertyPreview(q: any): any {
  const out: any = { name: q.name, type: q.type, value: q.value ?? nestedValue(q) };
  if (q.subtype && SUBTYPES.has(q.subtype)) out.subtype = q.subtype;
  if (q.valuePreview) out.valuePreview = preview(q.valuePreview);
  return out;
}

// WebKit leaves a nested object's value out of a preview; Chrome draws it
// from the value text, as V8 writes it: `Object`, `Array(3)`.
function nestedValue(q: any): string | undefined {
  const p = q.valuePreview;
  if (q.type !== "object" || !p) return undefined;
  if (p.subtype === "array") return `Array(${p.size ?? p.properties?.length ?? 0})`;
  return p.description;
}

/** WebKit Console.StackTrace (or a bare frame list) → CDP Runtime.StackTrace.
 *  Chrome links a frame by script id when it has one, and shows an id it has
 *  not been told about as an anonymous VM script — so ids Chrome does not
 *  know yet are left out, and the frame is linked by URL instead. */
export function stackTrace(st: any, isKnown: (scriptId: string) => boolean = () => true): any | undefined {
  const frames: any[] = Array.isArray(st) ? st : st?.callFrames ?? [];
  if (!frames.length) return undefined;
  const out: any = {
    callFrames: frames.map(callFrame).map((f) => (isKnown(f.scriptId) ? f : { ...f, scriptId: "" })),
  };
  if (st?.parentStackTrace) {
    const parent = stackTrace(st.parentStackTrace, isKnown);
    if (parent) out.parent = { ...parent, description: st.parentStackTrace.description ?? "async" };
  }
  return out;
}

export function callFrame(f: any): any {
  return {
    // Chrome names top-level code `(anonymous)`, which an empty name draws.
    functionName: f.functionName === "global code" || f.functionName === "eval code" ? "" : f.functionName ?? "",
    scriptId: String(f.scriptId ?? "0"),
    url: f.url ?? "",
    lineNumber: zeroBased(f.lineNumber),
    columnNumber: zeroBased(f.columnNumber),
  };
}

export function zeroBased(n: unknown): number {
  const v = Number(n ?? 0);
  return v > 0 ? v - 1 : 0;
}

/** WebKit's `{result, wasThrown}` → CDP's `{result, exceptionDetails?}`. */
export function evaluation(r: any): any {
  const result = remoteObject(r?.result ?? { type: "undefined" });
  if (!r?.wasThrown) return { result };
  return {
    result,
    exceptionDetails: {
      exceptionId: 1,
      text: "Uncaught",
      lineNumber: 0,
      columnNumber: 0,
      exception: result,
    },
  };
}
