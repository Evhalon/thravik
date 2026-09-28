// Runtime.getProperties: what an object shows when it is expanded.
//
// Chrome lists an object's internals as `[[Name]]` entries — its prototype,
// a promise's state, a collection's entries — where WebKit reports some as
// plain internal properties, the prototype as `__proto__`, and a
// collection's entries through a separate command.

import type { Session } from "./session";
import { internalName, remoteObject } from "./values";

// A collection's entries are listed under a synthetic object id: Chrome
// expands `[[Entries]]` by asking for that id's properties.
const ENTRIES_PREFIX = "redent-entries:";
// A function's closures, likewise, under `[[Scopes]]`.
const SCOPES_PREFIX = "redent-scopes:";

const SCOPE_TITLES: Record<string, string> = {
  global: "Global", with: "With Block", closure: "Closure", catch: "Catch", functionName: "Closure",
  globalLexicalEnvironment: "Script", nestedLexical: "Block",
};

export function installProperties(s: Session) {
  s.handle("Runtime.getProperties", async (p) => {
    if (typeof p.objectId === "string" && p.objectId.startsWith(ENTRIES_PREFIX)) {
      return entries(s, p.objectId.slice(ENTRIES_PREFIX.length));
    }
    if (typeof p.objectId === "string" && p.objectId.startsWith(SCOPES_PREFIX)) {
      return scopes(s, p.objectId.slice(SCOPES_PREFIX.length));
    }
    // Chrome asks for accessors in a second, separate call; the internals
    // belong to the first.
    const internals = !p.accessorPropertiesOnly;
    const [r, preview, fn] = await Promise.all([
      s.call("Runtime.getProperties", {
        objectId: p.objectId, ownProperties: !!p.ownProperties, generatePreview: p.generatePreview,
      }),
      internals ? s.call("Runtime.getPreview", { objectId: p.objectId }).catch(() => ({})) : {},
      internals ? s.call("Debugger.getFunctionDetails", { functionId: p.objectId }).catch(() => ({})) : {},
    ]);
    const out = properties(r, p);
    if (COLLECTIONS.has(preview.preview?.subtype)) {
      out.internalProperties.push(entriesProperty(p.objectId, preview.preview?.size));
    }
    if (fn.details) out.internalProperties.push(...functionInternals(p.objectId, fn.details));
    return out;
  });
}

const COLLECTIONS = new Set(["map", "set", "weakmap", "weakset"]);

function properties(r: any, p: any) {
  const result: any[] = [];
  const internalProperties: any[] = (r.internalProperties ?? []).map(internal);
  const privateProperties: any[] = [];
  for (const d of r.properties ?? []) {
    if (d.name === "__proto__") {
      if (d.value && !p.accessorPropertiesOnly) internalProperties.push({ name: "[[Prototype]]", value: remoteObject(d.value) });
      continue;
    }
    if (p.accessorPropertiesOnly && !d.get && !d.set) continue;
    if (p.nonIndexedPropertiesOnly && /^\d+$/.test(d.name)) continue;
    if (d.isPrivate) {
      privateProperties.push({ name: d.name, value: remoteObject(d.value) });
      continue;
    }
    result.push(descriptor(d));
  }
  return { result, internalProperties, ...(privateProperties.length ? { privateProperties } : {}) };
}

function descriptor(d: any) {
  const out: any = {
    name: d.name,
    configurable: !!d.configurable,
    enumerable: !!d.enumerable,
    isOwn: d.isOwn,
  };
  if (d.value) out.value = remoteObject(d.value);
  if (d.writable !== undefined) out.writable = d.writable;
  if (d.get) out.get = remoteObject(d.get);
  if (d.set) out.set = remoteObject(d.set);
  if (d.symbol) out.symbol = remoteObject(d.symbol);
  if (d.wasThrown) out.wasThrown = true;
  return out;
}

function internal(d: any) {
  const name = internalName(d.name);
  const value = remoteObject(d.value);
  if (d.name === "status" && value?.value === "resolved") value.value = "fulfilled";
  return { name, value };
}

/** The `[[Entries]]` entry for a Map, Set or weak collection. */
function entriesProperty(objectId: string, count: number | undefined) {
  return {
    name: "[[Entries]]",
    value: {
      type: "object",
      subtype: "array",
      className: "Array",
      description: `Array(${count ?? 0})`,
      objectId: ENTRIES_PREFIX + objectId,
    },
  };
}

async function entries(s: Session, objectId: string) {
  const r = await s.call("Runtime.getCollectionEntries", { objectId, objectGroup: "console" });
  const result = (r.entries ?? []).map((e: any, index: number) => ({
    name: String(index),
    configurable: false,
    enumerable: true,
    isOwn: true,
    value: entryObject(e),
  }));
  return { result, internalProperties: [] };
}

// Chrome draws a Map entry as `{key => value}` from an object whose preview
// carries `key` and `value` properties.
function entryObject(e: any) {
  const value = remoteObject(e.value);
  if (!e.key) return value;
  const key = remoteObject(e.key);
  return {
    type: "object",
    className: "Object",
    description: `{${key.description ?? key.value} => ${value.description ?? value.value}}`,
    preview: {
      type: "object",
      description: "Object",
      overflow: false,
      properties: [
        { name: "key", type: key.type, subtype: key.subtype, value: String(key.description ?? key.value) },
        { name: "value", type: value.type, subtype: value.subtype, value: String(value.description ?? value.value) },
      ],
    },
  };
}

/** `[[FunctionLocation]]`, which links a function to its source, and
 *  `[[Scopes]]`, the closures it can see. */
function functionInternals(objectId: string, details: any): any[] {
  const out: any[] = [{
    name: "[[FunctionLocation]]",
    value: { type: "object", subtype: "internal#location", value: details.location, description: "Object" },
  }];
  const count = details.scopeChain?.length ?? 0;
  if (count) {
    out.push({
      name: "[[Scopes]]",
      value: { type: "object", subtype: "internal#scopeList", className: "Array", description: `Scopes[${count}]`, objectId: SCOPES_PREFIX + objectId },
    });
  }
  return out;
}

async function scopes(s: Session, functionId: string) {
  const details = (await s.call("Debugger.getFunctionDetails", { functionId })).details;
  const result = (details?.scopeChain ?? []).map((scope: any, index: number) => {
    const title = SCOPE_TITLES[scope.type] ?? "Closure";
    const name = scope.name ?? (scope.type === "closure" ? details.displayName || details.name : "");
    return {
      name: String(index), configurable: false, enumerable: true, isOwn: true,
      value: {
        type: "object", subtype: "internal#scope", className: "Object",
        description: name ? `${title} (${name})` : title, objectId: scope.object?.objectId,
      },
    };
  });
  return { result, internalProperties: [] };
}
