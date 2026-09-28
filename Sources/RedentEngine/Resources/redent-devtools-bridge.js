(() => {
  // cdp/state.ts
  var REQUEST_LIMIT = 2000;

  class SessionState {
    mainContextId = 0;
    mainFrameId = "";
    mainFrameURL = "";
    requests = new Map;
    scripts = new Map;
    debuggerEnabled = false;
    replayed = new Set;
    nodes = new Map;
    sources = new Map;
    contextsByFrame = new Map;
    originsByFrame = new Map;
    addContext(id, frameId) {
      this.contextsByFrame.set(frameId, [...this.contextsByFrame.get(frameId) ?? [], id]);
      if (this.mainFrameId ? frameId === this.mainFrameId : !this.mainContextId)
        this.mainContextId = id;
    }
    dropContexts(frameId) {
      const ids = this.contextsByFrame.get(frameId) ?? [];
      this.contextsByFrame.delete(frameId);
      if (ids.includes(this.mainContextId))
        this.mainContextId = 0;
      return ids;
    }
    resetContexts() {
      this.contextsByFrame.clear();
      this.mainContextId = 0;
    }
    setOrigin(frameId, origin) {
      this.originsByFrame.set(frameId, origin);
    }
    origin(frameId) {
      return this.originsByFrame.get(frameId) ?? "";
    }
    async scriptSource(scriptId, fetch) {
      const known = this.sources.get(scriptId);
      if (known !== undefined)
        return known;
      const text = await fetch(scriptId).then((r) => String(r.scriptSource ?? "")).catch(() => "");
      const kept = text.length > 2000000 ? "" : text;
      this.sources.set(scriptId, kept);
      return kept;
    }
    isAnnounced = (scriptId) => this.debuggerEnabled && this.scripts.has(scriptId);
    track(id, request) {
      if (this.requests.size >= REQUEST_LIMIT) {
        const oldest = this.requests.keys().next().value;
        if (oldest !== undefined)
          this.requests.delete(oldest);
      }
      this.requests.set(id, request);
    }
  }

  // cdp/session.ts
  class ProtocolError extends Error {
  }
  function isSessionID(id) {
    return typeof id === "number" && id < 0;
  }
  function domainOf(method) {
    return method?.split(".")[0] ?? "";
  }

  class Session {
    transport;
    state = new SessionState;
    handlers = new Map;
    eventHandlers = new Map;
    pending = new Map;
    lastId = 0;
    enabledDomains = new Set;
    innerTargetId;
    queued = [];
    pageTargetIds = new Set;
    wrappedIds = new Set;
    constructor(transport, pageTargetId) {
      this.transport = transport;
      this.innerTargetId = pageTargetId;
      if (pageTargetId)
        this.pageTargetIds.add(pageTargetId);
    }
    handle(method, handler) {
      this.handlers.set(method, handler);
    }
    on(event, handler) {
      this.eventHandlers.set(event, handler);
    }
    call(method, params = {}) {
      return new Promise((resolve, reject) => {
        const id = --this.lastId;
        this.pending.set(id, { resolve, reject });
        this.send({ id, method, params });
      });
    }
    emit(method, params) {
      if (!this.enabledDomains.has(domainOf(method)))
        return;
      this.transport.toTools(JSON.stringify({ method, params }));
    }
    isPageTarget(id) {
      return typeof id === "string" && this.pageTargetIds.has(id);
    }
    async fromTools(raw) {
      let msg;
      try {
        msg = JSON.parse(raw);
      } catch {
        return;
      }
      const method = msg.method ?? "";
      if (method.endsWith(".enable"))
        this.enabledDomains.add(domainOf(method));
      const handler = this.handlers.get(method) ?? this.handlers.get("*");
      try {
        const result = handler ? await handler(msg.params ?? {}, method) : {};
        if (method.endsWith(".disable"))
          this.enabledDomains.delete(domainOf(method));
        this.reply({ id: msg.id, result: result ?? {} });
      } catch (e) {
        this.reply({ id: msg.id, error: { code: -32000, message: e?.message ?? String(e) } });
      }
    }
    fromBackend(msg) {
      if (typeof msg.id !== "number")
        return this.dispatchEvent(msg);
      this.settle(msg);
    }
    fromOuter(msg) {
      if (typeof msg.id !== "number")
        return this.onTargetDomain(msg);
      if (this.wrappedIds.delete(msg.id) && msg.error)
        this.settle(msg);
    }
    settle(msg) {
      const id = msg.id ?? 0;
      const pending = this.pending.get(id);
      if (!pending)
        return;
      this.pending.delete(id);
      if (msg.error)
        pending.reject(new ProtocolError(msg.error.message ?? "WebKit error"));
      else
        pending.resolve(msg.result ?? {});
    }
    dispatchEvent(msg) {
      try {
        this.eventHandlers.get(msg.method ?? "")?.(msg.params ?? {});
      } catch {}
    }
    onTargetDomain(msg) {
      const info = msg.params?.targetInfo;
      if (msg.method === "Target.targetCreated" && info?.type === "page") {
        this.pageTargetIds.add(info.targetId);
        if (!this.innerTargetId)
          this.retarget(info.targetId);
      }
      if (msg.method === "Target.targetDestroyed")
        this.pageTargetIds.delete(msg.params?.targetId);
      if (msg.method === "Target.didCommitProvisionalTarget" && typeof msg.params?.newTargetId === "string") {
        this.retarget(msg.params.newTargetId);
      }
    }
    retarget(id) {
      this.innerTargetId = id;
      const queued = this.queued;
      this.queued = [];
      queued.forEach((m) => this.send(m));
    }
    send(m) {
      if (!this.innerTargetId) {
        this.queued.push(m);
        return;
      }
      if (typeof m.id === "number")
        this.wrappedIds.add(m.id);
      this.transport.toBackend(JSON.stringify({
        id: m.id,
        method: "Target.sendMessageToTarget",
        params: { message: JSON.stringify(m), targetId: this.innerTargetId }
      }));
    }
    reply(m) {
      if (typeof m.id === "number")
        this.transport.toTools(JSON.stringify(m));
    }
  }

  // cdp/replay.ts
  async function replay(s, domain) {
    if (s.state.replayed.has(domain))
      return;
    s.state.replayed.add(domain);
    await s.call(`${domain}.disable`).catch(() => {});
    await s.call(`${domain}.enable`);
  }

  // cdp/values.ts
  var SUBTYPES = new Set([
    "array",
    "null",
    "node",
    "regexp",
    "date",
    "map",
    "set",
    "weakmap",
    "weakset",
    "iterator",
    "generator",
    "error",
    "proxy",
    "promise",
    "typedarray",
    "arraybuffer",
    "dataview"
  ]);
  var SUBTYPES_BY_CLASS = {
    Promise: "promise",
    ArrayBuffer: "arraybuffer",
    SharedArrayBuffer: "arraybuffer",
    DataView: "dataview",
    Generator: "generator",
    AsyncGenerator: "generator"
  };
  var TYPED_ARRAY = /^(Big)?(Int|Uint|Float)(8|16|32|64)(Clamped)?Array$/;
  function subtype(o) {
    if (o.subtype && SUBTYPES.has(o.subtype))
      return o.subtype;
    if (o.type !== "object" || !o.className)
      return;
    return SUBTYPES_BY_CLASS[o.className] ?? (TYPED_ARRAY.test(o.className) ? "typedarray" : undefined);
  }
  function remoteObject(o) {
    if (!o || typeof o !== "object")
      return o;
    const out = { ...o };
    delete out.subtype;
    const kind = subtype(o);
    if (kind)
      out.subtype = kind;
    if (o.subtype === "class")
      out.className = o.className ?? "Function";
    if (o.type === "number" && o.value === undefined && o.description) {
      out.unserializableValue = o.description;
    }
    if (o.type === "bigint") {
      out.unserializableValue = o.description;
      delete out.value;
    }
    if (o.preview)
      out.preview = preview(o.preview);
    delete out.size;
    delete out.classPrototype;
    return out;
  }
  function preview(p) {
    if (!p)
      return p;
    const out = {
      type: p.type,
      description: p.description,
      overflow: !!p.overflow,
      properties: (p.properties ?? []).map((q) => q.internal ? internalPreview(q) : propertyPreview(q)).filter(Boolean)
    };
    if (p.subtype && SUBTYPES.has(p.subtype))
      out.subtype = p.subtype;
    if (p.entries)
      out.entries = p.entries.map((e) => ({
        ...e.key ? { key: preview(e.key) } : {},
        value: preview(e.value)
      }));
    return out;
  }
  var INTERNAL_NAMES = {
    status: "[[PromiseState]]",
    result: "[[PromiseResult]]",
    targetFunction: "[[TargetFunction]]",
    boundThis: "[[BoundThis]]",
    boundArgs: "[[BoundArgs]]",
    target: "[[Target]]",
    handler: "[[Handler]]",
    iteratedObject: "[[IteratorTarget]]",
    iterationKind: "[[IteratorKind]]"
  };
  function internalName(name) {
    return INTERNAL_NAMES[name] ?? `[[${name.charAt(0).toUpperCase()}${name.slice(1)}]]`;
  }
  function internalPreview(q) {
    const out = propertyPreview(q);
    out.name = internalName(q.name);
    if (q.name === "status" && out.value === "resolved")
      out.value = "fulfilled";
    return out;
  }
  function propertyPreview(q) {
    const out = { name: q.name, type: q.type, value: q.value ?? nestedValue(q) };
    if (q.subtype && SUBTYPES.has(q.subtype))
      out.subtype = q.subtype;
    if (q.valuePreview)
      out.valuePreview = preview(q.valuePreview);
    return out;
  }
  function nestedValue(q) {
    const p = q.valuePreview;
    if (q.type !== "object" || !p)
      return;
    if (p.subtype === "array")
      return `Array(${p.size ?? p.properties?.length ?? 0})`;
    return p.description;
  }
  function stackTrace(st, isKnown = () => true) {
    const frames = Array.isArray(st) ? st : st?.callFrames ?? [];
    if (!frames.length)
      return;
    const out = {
      callFrames: frames.map(callFrame).map((f) => isKnown(f.scriptId) ? f : { ...f, scriptId: "" })
    };
    if (st?.parentStackTrace) {
      const parent = stackTrace(st.parentStackTrace, isKnown);
      if (parent)
        out.parent = { ...parent, description: st.parentStackTrace.description ?? "async" };
    }
    return out;
  }
  function callFrame(f) {
    return {
      functionName: f.functionName === "global code" || f.functionName === "eval code" ? "" : f.functionName ?? "",
      scriptId: String(f.scriptId ?? "0"),
      url: f.url ?? "",
      lineNumber: zeroBased(f.lineNumber),
      columnNumber: zeroBased(f.columnNumber)
    };
  }
  function zeroBased(n) {
    const v = Number(n ?? 0);
    return v > 0 ? v - 1 : 0;
  }
  function evaluation(r) {
    const result = remoteObject(r?.result ?? { type: "undefined" });
    if (!r?.wasThrown)
      return { result };
    return {
      result,
      exceptionDetails: {
        exceptionId: 1,
        text: "Uncaught",
        lineNumber: 0,
        columnNumber: 0,
        exception: result
      }
    };
  }

  // cdp/errors.ts
  var READ_ERROR = `function () {
  return { text: String(this), stack: typeof this.stack === "string" ? this.stack : "",
    line: this.line, column: this.column, url: this.sourceURL };
}`;
  function parseStack(stack) {
    const frames = [];
    for (const line of stack.split(`
`)) {
      if (!line.trim())
        continue;
      const at = line.lastIndexOf("@");
      const name = at >= 0 ? line.slice(0, at) : "";
      const location = at >= 0 ? line.slice(at + 1) : line;
      const match = /^(.*):(\d+):(\d+)$/.exec(location);
      if (!match) {
        if (location === "[native code]")
          frames.push({ functionName: name, url: "native", lineNumber: 0, columnNumber: 0 });
        continue;
      }
      frames.push({ functionName: name, url: match[1], lineNumber: Number(match[2]), columnNumber: Number(match[3]) });
    }
    return frames;
  }
  function v8Line(f) {
    const name = f.functionName === "global code" || f.functionName === "eval code" ? "" : f.functionName;
    const where = f.url === "native" ? "native" : `${f.url || "<anonymous>"}:${f.lineNumber}:${f.columnNumber}`;
    return name ? `    at ${name} (${where})` : `    at ${where}`;
  }
  async function readError(s, objectId) {
    const r = await s.call("Runtime.callFunctionOn", { objectId, functionDeclaration: READ_ERROR, returnByValue: true });
    return r.wasThrown ? null : r.result?.value;
  }
  async function withStack(s, o) {
    if (o?.subtype !== "error" || !o.objectId)
      return o;
    const e = await readError(s, o.objectId).catch(() => null);
    if (!e)
      return o;
    const frames = parseStack(e.stack);
    const head = o.description ?? e.text;
    return frames.length ? { ...o, description: [head, ...frames.map(v8Line)].join(`
`) } : o;
  }
  function installErrors(s) {
    s.handle("Runtime.getExceptionDetails", async (p) => {
      const e = await readError(s, p.errorObjectId);
      if (!e)
        throw new ProtocolError("Could not read the error");
      const frames = parseStack(e.stack);
      return {
        exceptionDetails: {
          exceptionId: 1,
          text: e.text,
          lineNumber: Math.max(0, (e.line ?? 1) - 1),
          columnNumber: Math.max(0, (e.column ?? 1) - 1),
          ...e.url ? { url: e.url } : {},
          ...frames.length ? {
            stackTrace: {
              callFrames: frames.filter((f) => f.url !== "native").map((f) => ({
                functionName: f.functionName === "global code" ? "" : f.functionName,
                scriptId: "",
                url: f.url,
                lineNumber: f.lineNumber - 1,
                columnNumber: f.columnNumber - 1
              }))
            }
          } : {}
        }
      };
    });
  }

  // cdp/console.ts
  var API_TYPES = {
    dir: "dir",
    dirxml: "dirxml",
    table: "table",
    trace: "trace",
    clear: "clear",
    startGroup: "startGroup",
    startGroupCollapsed: "startGroupCollapsed",
    endGroup: "endGroup",
    assert: "assert",
    timing: "timeEnd",
    profile: "profile",
    profileEnd: "profileEnd"
  };
  var LOG_SOURCES = new Set(["xml", "javascript", "network", "storage", "rendering", "security", "other"]);
  var EXCEPTION = /^(Unhandled Promise Rejection: )?([A-Z]\w*(Error|Exception)|Error)(: |$)/;
  var IN_PROMISE = "Unhandled Promise Rejection: ";
  function installConsole(s) {
    s.handle("Log.enable", () => replay(s, "Console"));
    s.handle("Log.clear", () => s.call("Console.clearMessages"));
    let last = null;
    let queue = Promise.resolve();
    s.on("Console.messageAdded", ({ message }) => {
      queue = queue.then(async () => {
        last = await withErrorStacks(s, translate(s, await withPreviews(s, message)));
        if (last)
          s.emit(last.method, last.params);
      });
    });
    s.on("Console.messagesCleared", ({ reason }) => {
      if (reason !== "console-api")
        return;
      s.emit("Runtime.consoleAPICalled", {
        type: "clear",
        args: [{ type: "string", value: "console.clear" }],
        executionContextId: s.state.mainContextId || 1,
        timestamp: Date.now()
      });
    });
    s.on("Inspector.inspect", ({ object, hints }) => inspectRequested(s, object, hints ?? {}));
    s.on("Console.messageRepeatCountUpdated", () => {
      if (last)
        s.emit(last.method, { ...last.params, timestamp: Date.now() });
    });
  }
  function translate(s, m) {
    if (!m)
      return null;
    if (m.source === "console-api")
      return { method: "Runtime.consoleAPICalled", params: apiCall(s, m) };
    if (m.source === "javascript" && m.level === "error" && EXCEPTION.test(m.text ?? "")) {
      return { method: "Runtime.exceptionThrown", params: exception(s, m) };
    }
    return { method: "Log.entryAdded", params: { entry: logEntry(s, m) } };
  }
  function apiType(m) {
    if (m.type === "log" || !m.type)
      return m.level === "debug" && !m.parameters?.length ? "count" : level(m.level);
    return API_TYPES[m.type] ?? "log";
  }
  function timestamp(m) {
    return typeof m.timestamp === "number" && m.timestamp > 1e9 ? m.timestamp * 1000 : Date.now();
  }
  async function withErrorStacks(s, t) {
    if (!t)
      return t;
    if (t.method === "Runtime.consoleAPICalled") {
      t.params.args = await Promise.all(t.params.args.map((a) => withStack(s, a)));
    } else if (t.method === "Runtime.exceptionThrown") {
      t.params.exceptionDetails.exception = await withStack(s, t.params.exceptionDetails.exception);
    }
    return t;
  }
  function apiCall(s, m) {
    const type = apiType(m);
    const args = m.parameters?.length ? m.parameters.map(remoteObject) : [{ type: "string", value: m.text ?? "" }];
    return {
      type,
      args,
      executionContextId: s.state.mainContextId || 1,
      timestamp: timestamp(m),
      stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced)
    };
  }
  function level(l) {
    if (l === "warning" || l === "error" || l === "info" || l === "debug")
      return l;
    return "log";
  }
  async function withPreviews(s, m) {
    if (!m?.parameters?.some((p) => p.objectId && !p.preview))
      return m;
    const parameters = await Promise.all(m.parameters.map(async (p) => {
      if (!p.objectId || p.preview)
        return p;
      const r = await s.call("Runtime.getPreview", { objectId: p.objectId }).catch(() => ({}));
      return r.preview ? { ...p, preview: r.preview } : p;
    }));
    return { ...m, parameters };
  }
  function exception(s, m) {
    const trace = stackTrace(m.stackTrace, s.state.isAnnounced);
    const top = trace?.callFrames.find((f) => f.url !== "[native code]") ?? trace?.callFrames[0];
    const inPromise = (m.text ?? "").startsWith(IN_PROMISE);
    const text = inPromise ? m.text.slice(IN_PROMISE.length) : m.text ?? "Error";
    const thrown = m.parameters?.[0] ? remoteObject(m.parameters[0]) : { type: "object", subtype: "error", className: text.split(":")[0] || "Error", description: text };
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
        executionContextId: s.state.mainContextId || 1
      }
    };
  }
  function logEntry(s, m) {
    return {
      source: LOG_SOURCES.has(m.source) ? m.source : m.source === "css" ? "rendering" : "other",
      level: m.level === "debug" ? "verbose" : m.level === "log" ? "info" : m.level,
      text: m.text ?? "",
      timestamp: timestamp(m),
      url: m.url,
      lineNumber: m.line ? zeroBased(m.line) : undefined,
      stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced),
      networkRequestId: m.networkRequestId
    };
  }
  async function inspectRequested(s, object, hints) {
    let held = object;
    if (object?.objectId) {
      const stash = s.call("Runtime.callFunctionOn", {
        objectId: object.objectId,
        functionDeclaration: `function () { globalThis[${JSON.stringify(HELD)}] = this; }`
      });
      await stash.catch(() => {});
      const r = await s.call("Runtime.evaluate", {
        expression: `(() => { const v = globalThis[${JSON.stringify(HELD)}]; delete globalThis[${JSON.stringify(HELD)}]; return v; })()`,
        objectGroup: "redent-inspected",
        generatePreview: true,
        contextId: s.state.mainContextId || undefined
      }).catch(() => null);
      if (r?.result?.objectId)
        held = r.result;
    }
    s.emit("Runtime.inspectRequested", { object: remoteObject(held), hints, executionContextId: s.state.mainContextId || 1 });
  }
  var HELD = "__redentInspected";

  // cdp/dom.ts
  function domNode(s, n) {
    if (!n)
      return n;
    const out = {
      nodeId: n.nodeId,
      backendNodeId: n.nodeId,
      nodeType: n.nodeType,
      nodeName: n.nodeName,
      localName: n.localName ?? "",
      nodeValue: n.nodeValue ?? ""
    };
    for (const key of ["childNodeCount", "attributes", "documentURL", "baseURL", "publicId", "systemId", "xmlVersion", "frameId", "pseudoType", "shadowRootType"]) {
      if (n[key] !== undefined)
        out[key] = n[key];
    }
    if (n.children)
      out.children = n.children.map((c) => domNode(s, c));
    if (n.contentDocument)
      out.contentDocument = domNode(s, n.contentDocument);
    if (n.templateContent)
      out.templateContent = domNode(s, n.templateContent);
    if (n.shadowRoots)
      out.shadowRoots = n.shadowRoots.map((c) => domNode(s, c));
    if (n.pseudoElements)
      out.pseudoElements = n.pseudoElements.map((c) => domNode(s, c));
    if (n.localName === "svg" || n.attributes?.includes("http://www.w3.org/2000/svg"))
      out.isSVG = true;
    const { children, contentDocument, templateContent, shadowRoots, pseudoElements, ...shallow } = out;
    s.state.nodes.set(n.nodeId, shallow);
    return out;
  }
  async function nodeIdOf(s, p) {
    const id = p.nodeId || p.backendNodeId;
    if (id)
      return id;
    if (p.objectId)
      return (await s.call("DOM.requestNode", { objectId: p.objectId })).nodeId;
    throw new ProtocolError("No node with given id found");
  }
  async function onNode(s, p, fn, args = []) {
    const objectId = p.objectId ?? (await s.call("DOM.resolveNode", { nodeId: await nodeIdOf(s, p), objectGroup: "redent-dom" })).object?.objectId;
    const r = await s.call("Runtime.callFunctionOn", {
      objectId,
      functionDeclaration: fn,
      arguments: args.map((value) => ({ value })),
      returnByValue: true
    });
    if (!p.objectId)
      s.call("Runtime.releaseObjectGroup", { objectGroup: "redent-dom" }).catch(() => {});
    if (r.wasThrown)
      throw new ProtocolError(r.result?.description ?? "Could not compute");
    return r.result?.value;
  }
  var FORWARDED = [
    "setNodeName",
    "setNodeValue",
    "removeNode",
    "setAttributeValue",
    "setAttributesAsText",
    "removeAttribute",
    "setOuterHTML",
    "moveTo",
    "undo",
    "redo",
    "markUndoableState",
    "focus",
    "setInspectedNode",
    "getAttributes",
    "querySelector",
    "querySelectorAll",
    "getSearchResults",
    "discardSearchResults",
    "requestNode",
    "pushNodeByPathToFrontend"
  ];
  function installDOM(s) {
    s.handle("DOM.enable", () => ({}));
    s.handle("DOM.disable", () => ({}));
    s.handle("DOM.getDocument", async () => {
      s.state.nodes.clear();
      return { root: domNode(s, (await s.call("DOM.getDocument")).root) };
    });
    s.handle("DOM.requestChildNodes", (p) => s.call("DOM.requestChildNodes", { nodeId: p.nodeId, depth: p.depth }));
    for (const method of FORWARDED) {
      s.handle(`DOM.${method}`, async (p) => {
        const params = { ...p };
        if (params.backendNodeId && !params.nodeId)
          params.nodeId = params.backendNodeId;
        delete params.backendNodeId;
        return s.call(`DOM.${method}`, params);
      });
    }
    s.handle("DOM.getOuterHTML", async (p) => s.call("DOM.getOuterHTML", { nodeId: await nodeIdOf(s, p) }));
    s.handle("DOM.performSearch", (p) => s.call("DOM.performSearch", { query: p.query }));
    s.handle("DOM.resolveNode", async (p) => {
      const r = await s.call("DOM.resolveNode", { nodeId: await nodeIdOf(s, p), objectGroup: p.objectGroup });
      return { object: remoteObject(r.object) };
    });
    s.handle("DOM.describeNode", async (p) => {
      const id = await nodeIdOf(s, p);
      const node = s.state.nodes.get(id);
      if (!node)
        throw new ProtocolError("No node with given id found");
      return { node };
    });
    s.handle("DOM.pushNodesByBackendIdsToFrontend", (p) => ({
      nodeIds: (p.backendNodeIds ?? []).map((id) => s.state.nodes.has(id) ? id : 0)
    }));
    s.handle("DOM.getTopLayerElements", () => ({ nodeIds: [] }));
    s.handle("DOM.getQueryingDescendantsForContainer", () => ({ nodeIds: [] }));
    installGeometry(s);
    installEvents(s);
  }
  var BOX_MODEL = `function () {
  const r = this.getBoundingClientRect(), st = getComputedStyle(this), px = (v) => parseFloat(v) || 0;
  const quad = (l, t, rt, b) => [l, t, rt, t, rt, b, l, b];
  const side = (p) => [px(st[p + "Left"] ?? st[p + "LeftWidth"]), px(st[p + "Top"] ?? st[p + "TopWidth"]),
    px(st[p + "Right"] ?? st[p + "RightWidth"]), px(st[p + "Bottom"] ?? st[p + "BottomWidth"])];
  const [ml, mt, mr, mb] = side("margin"), [bl, bt, br, bb] = [px(st.borderLeftWidth), px(st.borderTopWidth), px(st.borderRightWidth), px(st.borderBottomWidth)];
  const [pl, pt, pr, pb] = side("padding");
  const border = quad(r.left, r.top, r.right, r.bottom);
  const padding = quad(r.left + bl, r.top + bt, r.right - br, r.bottom - bb);
  const content = quad(r.left + bl + pl, r.top + bt + pt, r.right - br - pr, r.bottom - bb - pb);
  const margin = quad(r.left - ml, r.top - mt, r.right + mr, r.bottom + mb);
  return { content, padding, border, margin, width: Math.round(r.width), height: Math.round(r.height) };
}`;
  function installGeometry(s) {
    s.handle("DOM.getBoxModel", async (p) => ({ model: await onNode(s, p, BOX_MODEL) }));
    s.handle("DOM.getContentQuads", async (p) => ({ quads: [(await onNode(s, p, BOX_MODEL)).border] }));
    s.handle("DOM.scrollIntoViewIfNeeded", async (p) => {
      await onNode(s, p, "function () { this.scrollIntoViewIfNeeded ? this.scrollIntoViewIfNeeded(true) : this.scrollIntoView({ block: 'center' }); }");
      return {};
    });
    s.handle("DOM.collectClassNamesFromSubtree", async (p) => ({
      classNames: await onNode(s, p, `function () {
      const names = new Set();
      for (const el of [this, ...this.querySelectorAll("[class]")]) for (const c of el.classList ?? []) names.add(c);
      return [...names];
    }`)
    }));
    s.handle("DOM.getNodeForLocation", async (p) => {
      const r = await s.call("Runtime.evaluate", {
        expression: `document.elementFromPoint(${Number(p.x)}, ${Number(p.y)})`,
        objectGroup: "redent-dom",
        contextId: s.state.mainContextId || undefined
      });
      if (!r.result?.objectId)
        throw new ProtocolError("No node found at given location");
      const nodeId = (await s.call("DOM.requestNode", { objectId: r.result.objectId })).nodeId;
      return { nodeId, backendNodeId: nodeId, frameId: s.state.mainFrameId };
    });
    s.handle("DOM.copyTo", async (p) => {
      const target = await s.call("DOM.resolveNode", { nodeId: p.targetNodeId, objectGroup: "redent-dom" });
      const before = p.insertBeforeNodeId ? await s.call("DOM.resolveNode", { nodeId: p.insertBeforeNodeId, objectGroup: "redent-dom" }) : null;
      const source = await s.call("DOM.resolveNode", { nodeId: p.nodeId, objectGroup: "redent-dom" });
      const r = await s.call("Runtime.callFunctionOn", {
        objectId: source.object.objectId,
        functionDeclaration: "function (parent, before) { return parent.insertBefore(this.cloneNode(true), before ?? null); }",
        arguments: [{ objectId: target.object.objectId }, before ? { objectId: before.object.objectId } : { value: null }]
      });
      return { nodeId: (await s.call("DOM.requestNode", { objectId: r.result.objectId })).nodeId };
    });
  }
  function installEvents(s) {
    s.on("DOM.documentUpdated", () => {
      s.state.nodes.clear();
      s.emit("DOM.documentUpdated", {});
    });
    s.on("DOM.setChildNodes", (p) => s.emit("DOM.setChildNodes", { parentId: p.parentId, nodes: (p.nodes ?? []).map((n) => domNode(s, n)) }));
    s.on("DOM.childNodeInserted", (p) => s.emit("DOM.childNodeInserted", { ...p, node: domNode(s, p.node) }));
    s.on("DOM.shadowRootPushed", (p) => s.emit("DOM.shadowRootPushed", { hostId: p.hostId, root: domNode(s, p.root) }));
    s.on("DOM.pseudoElementAdded", (p) => s.emit("DOM.pseudoElementAdded", { parentId: p.parentId, pseudoElement: domNode(s, p.pseudoElement) }));
    s.on("DOM.childNodeRemoved", (p) => {
      s.state.nodes.delete(p.nodeId);
      s.emit("DOM.childNodeRemoved", p);
    });
    s.on("DOM.attributeModified", (p) => {
      const node = s.state.nodes.get(p.nodeId);
      if (node?.attributes)
        node.attributes = withAttribute(node.attributes, p.name, p.value);
      s.emit("DOM.attributeModified", p);
    });
    s.on("DOM.attributeRemoved", (p) => {
      const node = s.state.nodes.get(p.nodeId);
      if (node?.attributes)
        node.attributes = withAttribute(node.attributes, p.name, null);
      s.emit("DOM.attributeRemoved", p);
    });
    for (const event of ["characterDataModified", "childNodeCountUpdated", "shadowRootPopped", "pseudoElementRemoved", "inlineStyleInvalidated"]) {
      s.on(`DOM.${event}`, (p) => s.emit(`DOM.${event}`, p));
    }
    s.on("DOM.inspect", (p) => s.emit("Overlay.inspectNodeRequested", { backendNodeId: p.nodeId }));
  }
  function withAttribute(attributes, name, value) {
    const out = [];
    let found = false;
    for (let i = 0;i < attributes.length; i += 2) {
      if (attributes[i] !== name) {
        out.push(attributes[i], attributes[i + 1]);
      } else {
        found = true;
        if (value !== null)
          out.push(name, value);
      }
    }
    if (!found && value !== null)
      out.push(name, value);
    return out;
  }

  // cdp/css-values.ts
  function rangeKey(styleSheetId, range) {
    return `${styleSheetId}|${range?.startLine}|${range?.startColumn}`;
  }
  var ORIGINS = { "user-agent": "user-agent", inspector: "inspector", user: "regular", author: "regular" };
  function origin(o) {
    return ORIGINS[o ?? ""] ?? "regular";
  }
  function style(ids, st) {
    if (!st)
      return st;
    const sheet = st.styleId?.styleSheetId;
    const out = {
      cssProperties: (st.cssProperties ?? []).map((p) => ({
        name: p.name,
        value: p.value,
        important: p.priority === "important",
        implicit: !!p.implicit,
        ...p.text !== undefined ? { text: p.text } : {},
        parsedOk: p.parsedOk ?? true,
        disabled: p.status === "disabled",
        ...p.range ? { range: p.range } : {}
      })),
      shorthandEntries: (st.shorthandEntries ?? []).map((e) => ({ name: e.name, value: e.value, important: e.priority === "important" }))
    };
    if (sheet && st.range) {
      out.styleSheetId = sheet;
      out.range = st.range;
      ids.styles.set(rangeKey(sheet, st.range), st.styleId);
    }
    if (st.cssText !== undefined)
      out.cssText = st.cssText;
    return out;
  }
  function rule(ids, r) {
    const sheet = r.ruleId?.styleSheetId;
    const out = {
      selectorList: selectorList(r.selectorList),
      origin: origin(r.origin),
      style: style(ids, r.style)
    };
    if (sheet) {
      out.styleSheetId = sheet;
      if (r.selectorList?.range)
        ids.rules.set(rangeKey(sheet, r.selectorList.range), r.ruleId);
    }
    Object.assign(out, groupings(ids, r.groupings ?? [], sheet));
    return out;
  }
  function ruleMatch(ids, m) {
    return { rule: rule(ids, m.rule), matchingSelectors: m.matchingSelectors ?? [] };
  }
  function selectorList(list) {
    const selectors = (list?.selectors ?? []).map((sel) => ({
      text: sel.text,
      ...Array.isArray(sel.specificity) ? { specificity: { a: sel.specificity[0], b: sel.specificity[1], c: sel.specificity[2] } } : {}
    }));
    const range = list?.range;
    if (range && range.startLine === range.endLine && typeof list.text === "string") {
      let column = range.startColumn;
      const parts = list.text.split(",");
      parts.forEach((part, index) => {
        const lead = part.length - part.trimStart().length;
        const text = part.trim();
        if (selectors[index] && selectors[index].text === text) {
          selectors[index].range = { startLine: range.startLine, startColumn: column + lead, endLine: range.startLine, endColumn: column + lead + text.length };
        }
        column += part.length + 1;
      });
    }
    return { selectors, text: list?.text ?? selectors.map((sel) => sel.text).join(", ") };
  }
  var MEDIA_SOURCES = {
    "media-rule": "mediaRule",
    "media-import-rule": "importRule",
    "media-link-node": "linkedSheet",
    "media-style-node": "inlineSheet"
  };
  function groupings(ids, list, sheet) {
    const out = {};
    const push = (key, value) => {
      (out[key] ??= []).push(value);
    };
    for (const g of list) {
      const located = { text: g.text ?? "" };
      if (g.range && sheet) {
        located.range = g.range;
        located.styleSheetId = sheet;
        if (g.ruleId)
          ids.groupings.set(rangeKey(sheet, g.range), g.ruleId);
      }
      if (MEDIA_SOURCES[g.type])
        push("media", { ...located, source: MEDIA_SOURCES[g.type], ...g.sourceURL ? { sourceURL: g.sourceURL } : {} });
      else if (g.type === "supports-rule")
        push("supports", { ...located, active: true });
      else if (g.type === "container-rule")
        push("containerQueries", located);
      else if (g.type === "layer-rule" || g.type === "layer-import-rule")
        push("layers", located);
      else if (g.type === "scope-rule")
        push("scopes", located);
      else if (g.type === "starting-style-rule")
        push("startingStyles", located);
      else if (g.type === "style-rule")
        push("nestingSelectors", g.text ?? "");
    }
    return out;
  }
  function header(h) {
    return {
      styleSheetId: h.styleSheetId,
      frameId: h.frameId,
      sourceURL: h.sourceURL ?? "",
      origin: origin(h.origin),
      title: h.title ?? "",
      disabled: !!h.disabled,
      isInline: !!h.isInline,
      isMutable: h.origin === "inspector",
      isConstructed: false,
      startLine: h.startLine ?? 0,
      startColumn: h.startColumn ?? 0,
      length: 0,
      endLine: h.startLine ?? 0,
      endColumn: h.startColumn ?? 0
    };
  }

  // cdp/css.ts
  function installCSS(s) {
    const ids = { styles: new Map, rules: new Map, groupings: new Map };
    s.handle("CSS.enable", () => replay(s, "CSS"));
    s.handle("CSS.disable", () => ({}));
    s.handle("CSS.getMatchedStylesForNode", async (p) => {
      const [matched, inline] = await Promise.all([
        s.call("CSS.getMatchedStylesForNode", { nodeId: p.nodeId, includePseudo: true, includeInherited: true }),
        s.call("CSS.getInlineStylesForNode", { nodeId: p.nodeId })
      ]);
      return {
        ...inline.inlineStyle ? { inlineStyle: style(ids, inline.inlineStyle) } : {},
        ...inline.attributesStyle ? { attributesStyle: style(ids, inline.attributesStyle) } : {},
        matchedCSSRules: (matched.matchedCSSRules ?? []).map((m) => ruleMatch(ids, m)),
        pseudoElements: (matched.pseudoElements ?? []).map((e) => ({
          pseudoType: e.pseudoId,
          matches: (e.matches ?? []).map((m) => ruleMatch(ids, m))
        })),
        inherited: (matched.inherited ?? []).map((e) => ({
          ...e.inlineStyle ? { inlineStyle: style(ids, e.inlineStyle) } : {},
          matchedCSSRules: (e.matchedCSSRules ?? []).map((m) => ruleMatch(ids, m))
        }))
      };
    });
    s.handle("CSS.getInlineStylesForNode", async (p) => {
      const r = await s.call("CSS.getInlineStylesForNode", { nodeId: p.nodeId });
      return {
        ...r.inlineStyle ? { inlineStyle: style(ids, r.inlineStyle) } : {},
        ...r.attributesStyle ? { attributesStyle: style(ids, r.attributesStyle) } : {}
      };
    });
    s.handle("CSS.getComputedStyleForNode", async (p) => ({
      computedStyle: ((await s.call("CSS.getComputedStyleForNode", { nodeId: p.nodeId })).computedStyle ?? []).map((c) => ({ name: c.name, value: c.value }))
    }));
    s.handle("CSS.getPlatformFontsForNode", async (p) => {
      const font = (await s.call("CSS.getFontDataForNode", { nodeId: p.nodeId })).primaryFont;
      return { fonts: font ? [{ familyName: font.displayName ?? font.name ?? "", postScriptName: "", isCustomFont: false, glyphCount: 0 }] : [] };
    });
    s.handle("CSS.getBackgroundColors", async (p) => onNode(s, p, `function () {
    const colors = [];
    for (let el = this; el && el.nodeType === 1; el = el.parentElement) {
      const bg = getComputedStyle(el).backgroundColor;
      if (bg && bg !== "rgba(0, 0, 0, 0)" && bg !== "transparent") { colors.push(bg); break; }
    }
    const st = getComputedStyle(this);
    return { backgroundColors: colors.length ? colors : ["rgb(255, 255, 255)"], computedFontSize: st.fontSize, computedFontWeight: st.fontWeight };
  }`));
    s.handle("CSS.trackComputedStyleUpdates", () => ({}));
    s.handle("CSS.trackComputedStyleUpdatesForNode", () => ({}));
    s.handle("CSS.takeComputedStyleUpdates", () => ({ nodeIds: [] }));
    s.handle("CSS.getMediaQueries", () => ({ medias: [] }));
    s.handle("CSS.getAnimatedStylesForNode", () => ({}));
    s.handle("CSS.getEnvironmentVariables", () => ({ environmentVariables: {} }));
    s.handle("CSS.getLayersForNode", () => ({ rootLayer: { name: "implicit outer layer", order: 0, subLayers: [] } }));
    s.handle("CSS.forcePseudoState", (p) => s.call("CSS.forcePseudoState", { nodeId: p.nodeId, forcedPseudoClasses: p.forcedPseudoClasses ?? [] }));
    s.handle("CSS.getStyleSheetText", (p) => s.call("CSS.getStyleSheetText", { styleSheetId: p.styleSheetId }));
    s.handle("CSS.setStyleSheetText", async (p) => {
      await s.call("CSS.setStyleSheetText", { styleSheetId: p.styleSheetId, text: p.text });
      return {};
    });
    s.handle("CSS.createStyleSheet", (p) => s.call("CSS.createStyleSheet", { frameId: p.frameId }));
    installEditing(s, ids);
    installEvents2(s);
  }
  function installEditing(s, ids) {
    const find = (map, sheet, range, what) => {
      const id = map.get(rangeKey(sheet, range));
      if (!id)
        throw new ProtocolError(`This ${what} can no longer be edited; select the element again`);
      return id;
    };
    s.handle("CSS.setStyleTexts", async (p) => {
      const styles = [];
      for (const edit of p.edits ?? []) {
        const styleId = find(ids.styles, edit.styleSheetId, edit.range, "style");
        const r = await s.call("CSS.setStyleText", { styleId, text: edit.text });
        styles.push(style(ids, r.style));
      }
      return { styles };
    });
    s.handle("CSS.setRuleSelector", async (p) => {
      const r = await s.call("CSS.setRuleSelector", { ruleId: find(ids.rules, p.styleSheetId, p.range, "rule"), selector: p.selector });
      return { selectorList: selectorList(r.rule?.selectorList) };
    });
    for (const [method, key] of [["setMediaText", "media"], ["setContainerQueryText", "containerQuery"], ["setSupportsText", "supports"], ["setScopeText", "scope"]]) {
      s.handle(`CSS.${method}`, async (p) => {
        const ruleId = find(ids.groupings, p.styleSheetId, p.range, "rule");
        const r = await s.call("CSS.setGroupingHeaderText", { ruleId, headerText: p.text });
        return { [key]: { text: r.grouping?.text ?? p.text, range: r.grouping?.range, styleSheetId: p.styleSheetId } };
      });
    }
    s.handle("CSS.addRule", async (p) => {
      const selector = String(p.ruleText ?? "").split("{")[0].trim();
      const r = await s.call("CSS.addRule", { styleSheetId: p.styleSheetId, selector });
      return { rule: ruleMatch(ids, { rule: r.rule }).rule };
    });
  }
  function installEvents2(s) {
    s.on("CSS.styleSheetAdded", (p) => s.emit("CSS.styleSheetAdded", { header: header(p.header) }));
    s.on("CSS.styleSheetRemoved", (p) => s.emit("CSS.styleSheetRemoved", { styleSheetId: p.styleSheetId }));
    s.on("CSS.styleSheetChanged", (p) => s.emit("CSS.styleSheetChanged", { styleSheetId: p.styleSheetId }));
    s.on("CSS.mediaQueryResultChanged", () => s.emit("CSS.mediaQueryResultChanged", {}));
  }

  // cdp/debugger.ts
  var PAUSE_REASONS = {
    exception: "exception",
    assert: "assert",
    CSPViolation: "CSPViolation",
    DOM: "DOM",
    Listener: "EventListener",
    URL: "XHR"
  };
  var SCOPE_TYPES = {
    global: "global",
    with: "with",
    closure: "closure",
    catch: "catch",
    functionName: "closure",
    globalLexicalEnvironment: "script",
    nestedLexical: "block"
  };
  function installDebugger(s) {
    s.handle("Debugger.enable", async () => {
      s.state.debuggerEnabled = true;
      await replay(s, "Debugger");
      await s.call("Debugger.setBreakpointsActive", { active: true });
      return { debuggerId: "redent" };
    });
    s.handle("Debugger.disable", () => ({}));
    s.handle("Debugger.getScriptSource", (p) => s.call("Debugger.getScriptSource", { scriptId: p.scriptId }));
    s.handle("Debugger.setBreakpointByUrl", (p) => s.call("Debugger.setBreakpointByUrl", {
      lineNumber: p.lineNumber,
      url: p.url,
      urlRegex: p.urlRegex,
      columnNumber: p.columnNumber,
      options: p.condition ? { condition: p.condition } : {}
    }));
    s.handle("Debugger.getPossibleBreakpoints", () => ({ locations: [] }));
    s.handle("Debugger.setPauseOnExceptions", (p) => s.call("Debugger.setPauseOnExceptions", {
      state: p.state === "caught" ? "all" : p.state
    }));
    s.handle("Debugger.evaluateOnCallFrame", async (p) => evaluation(await s.call("Debugger.evaluateOnCallFrame", {
      callFrameId: p.callFrameId,
      expression: p.expression,
      objectGroup: p.objectGroup,
      includeCommandLineAPI: p.includeCommandLineAPI,
      doNotPauseOnExceptionsAndMuteConsole: p.silent,
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview
    })));
    s.handle("Debugger.setAsyncCallStackDepth", (p) => s.call("Debugger.setAsyncStackTraceDepth", { depth: p.maxDepth ?? 0 }));
    for (const method of ["removeBreakpoint", "setBreakpointsActive", "continueToLocation", "pause", "resume", "stepOver", "stepInto", "stepOut"]) {
      s.handle(`Debugger.${method}`, (p) => s.call(`Debugger.${method}`, forwarded(method, p)));
    }
    installEvents3(s);
  }
  function forwarded(method, p) {
    if (method === "removeBreakpoint")
      return { breakpointId: p.breakpointId };
    if (method === "setBreakpointsActive")
      return { active: !!p.active };
    if (method === "continueToLocation")
      return { location: p.location };
    return {};
  }
  function installEvents3(s) {
    s.on("Debugger.scriptParsed", (p) => {
      if (p.isContentScript)
        return;
      const url = p.sourceURL || p.url || "";
      s.state.scripts.set(p.scriptId, url);
      s.emit("Debugger.scriptParsed", {
        scriptId: p.scriptId,
        url,
        startLine: p.startLine,
        startColumn: p.startColumn,
        endLine: p.endLine,
        endColumn: p.endColumn,
        executionContextId: s.state.mainContextId || 1,
        hash: "",
        isModule: !!p.module,
        sourceMapURL: p.sourceMapURL ?? "",
        hasSourceURL: !!p.sourceURL,
        scriptLanguage: "JavaScript"
      });
    });
    s.on("Debugger.paused", (p) => s.emit("Debugger.paused", {
      callFrames: (p.callFrames ?? []).map((f) => callFrame2(s, f)),
      reason: PAUSE_REASONS[p.reason] ?? "other",
      data: p.data,
      ...p.data?.breakpointId ? { hitBreakpoints: [p.data.breakpointId] } : {},
      ...p.asyncStackTrace ? { asyncStackTrace: stackTrace(p.asyncStackTrace) } : {}
    }));
    s.on("Debugger.resumed", () => s.emit("Debugger.resumed", {}));
    s.on("Debugger.breakpointResolved", (p) => s.emit("Debugger.breakpointResolved", p));
  }
  function callFrame2(s, f) {
    let sawLocal = false;
    const scopeChain = (f.scopeChain ?? []).map((scope) => {
      let type = SCOPE_TYPES[scope.type] ?? "closure";
      if (type === "closure" && !sawLocal) {
        type = "local";
        sawLocal = true;
      }
      return { type, object: remoteObject(scope.object), ...scope.name ? { name: scope.name } : {} };
    });
    return {
      callFrameId: f.callFrameId,
      functionName: f.functionName ?? "",
      location: f.location,
      url: s.state.scripts.get(f.location?.scriptId) ?? "",
      scopeChain,
      this: remoteObject(f.this)
    };
  }

  // cdp/emulation.ts
  var PREFERENCES = {
    "prefers-color-scheme": { name: "PrefersColorScheme", values: { dark: "Dark", light: "Light" } },
    "prefers-reduced-motion": { name: "PrefersReducedMotion", values: { reduce: "Reduce", "no-preference": "NoPreference" } },
    "prefers-contrast": { name: "PrefersContrast", values: { more: "More", "no-preference": "NoPreference" } }
  };
  function installEmulation(s) {
    s.handle("Emulation.setUserAgentOverride", (p) => s.call("Page.overrideUserAgent", p.userAgent ? { value: p.userAgent } : {}));
    s.handle("Emulation.setEmulatedMedia", async (p) => {
      await s.call("Page.setEmulatedMedia", { media: p.media ?? "" });
      const features = p.features ?? [];
      for (const [feature, preference] of Object.entries(PREFERENCES)) {
        const value = features.find((f) => f.name === feature)?.value;
        const mapped = value ? preference.values[value] : undefined;
        await s.call("Page.overrideUserPreference", mapped ? { name: preference.name, value: mapped } : { name: preference.name });
      }
    });
  }

  // cdp/fallback.ts
  var QUERY = /^(get|query|search|take|capture|resolve|request|describe|compile|evaluate|call|collect|load|print)/;
  function installFallback(s) {
    s.handle("*", (_params, method) => {
      if (QUERY.test(method.split(".")[1] ?? ""))
        throw new ProtocolError(`'${method}' is not available in WebKit`);
      return {};
    });
  }

  // cdp/page.ts
  var RESOURCE_TYPES = { StyleSheet: "Stylesheet", Beacon: "Ping" };
  function resourceType(t) {
    if (!t)
      return "Other";
    return RESOURCE_TYPES[t] ?? t;
  }
  function enable(s, domain) {
    return s.call(`${domain}.enable`).catch(() => ({}));
  }
  function installPage(s) {
    s.handle("Page.enable", () => enable(s, "Page"));
    s.handle("Page.getResourceTree", async () => ({ frameTree: tree(s, (await s.call("Page.getResourceTree")).frameTree, true) }));
    s.handle("Page.getFrameTree", async () => ({ frameTree: tree(s, (await s.call("Page.getResourceTree")).frameTree, false) }));
    s.handle("Page.getResourceContent", (p) => s.call("Page.getResourceContent", { frameId: p.frameId, url: p.url }));
    s.handle("Page.reload", (p) => s.call("Page.reload", { ignoreCache: !!p.ignoreCache }));
    s.handle("Page.navigate", async (p) => {
      await s.call("Runtime.evaluate", { expression: `location.href = ${JSON.stringify(p.url)}`, contextId: s.state.mainContextId || undefined });
      return { frameId: s.state.mainFrameId };
    });
    s.handle("Page.getNavigationHistory", () => ({
      currentIndex: 0,
      entries: [{ id: 0, url: s.state.mainFrameURL, userTypedURL: s.state.mainFrameURL, title: "", transitionType: "typed" }]
    }));
    s.handle("Page.addScriptToEvaluateOnNewDocument", () => ({ identifier: "0" }));
    installPageEvents(s);
  }
  function installPageEvents(s) {
    s.on("Page.frameNavigated", ({ frame }) => {
      if (!frame)
        return;
      const translated = remember(s, frame);
      if (!frame.parentId) {
        s.state.resetContexts();
        s.emit("Runtime.executionContextsCleared", {});
      } else {
        destroyContexts(s, frame.id);
      }
      s.emit("Page.frameNavigated", { frame: translated, type: "Navigation" });
    });
    s.on("Page.frameDetached", ({ frameId }) => {
      destroyContexts(s, frameId);
      s.emit("Page.frameDetached", { frameId, reason: "remove" });
    });
    for (const event of ["Page.domContentEventFired", "Page.loadEventFired", "Page.frameStartedLoading", "Page.frameStoppedLoading"]) {
      s.on(event, (p) => s.emit(event, p));
    }
  }
  function destroyContexts(s, frameId) {
    for (const id of s.state.dropContexts(frameId)) {
      s.emit("Runtime.executionContextDestroyed", { executionContextId: id, executionContextUniqueId: String(id) });
    }
  }
  function tree(s, node, withResources) {
    const out = { frame: remember(s, node.frame) };
    if (node.childFrames?.length)
      out.childFrames = node.childFrames.map((c) => tree(s, c, withResources));
    if (withResources) {
      out.resources = (node.resources ?? []).map((r) => ({
        url: r.url,
        type: resourceType(r.type),
        mimeType: r.mimeType ?? "",
        failed: r.failed,
        canceled: r.canceled
      }));
    }
    return out;
  }
  function remember(s, f) {
    const origin2 = f.securityOrigin ?? "";
    s.state.setOrigin(f.id, origin2);
    if (!f.parentId) {
      s.state.mainFrameId = f.id;
      s.state.mainFrameURL = f.url;
    }
    let host = "";
    try {
      host = new URL(f.url).hostname;
    } catch {}
    const secure = origin2.startsWith("https:") || host === "localhost" || host === "127.0.0.1";
    return {
      id: f.id,
      ...f.parentId ? { parentId: f.parentId } : {},
      loaderId: f.loaderId,
      name: f.name,
      url: f.url,
      domainAndRegistry: host.split(".").slice(-2).join("."),
      securityOrigin: origin2,
      mimeType: f.mimeType ?? "text/html",
      secureContextType: secure ? "Secure" : "InsecureScheme",
      crossOriginIsolatedContextType: "NotIsolated",
      gatedAPIFeatures: []
    };
  }

  // cdp/network-values.ts
  var REFERRER_POLICIES = new Set([
    "no-referrer",
    "no-referrer-when-downgrade",
    "same-origin",
    "origin",
    "strict-origin",
    "origin-when-cross-origin",
    "strict-origin-when-cross-origin",
    "unsafe-url"
  ]);
  function request(r, priority = "Medium") {
    return {
      url: r.url,
      method: r.method,
      headers: r.headers ?? {},
      ...r.postData != null ? { postData: r.postData, hasPostData: true } : {},
      initialPriority: priority,
      referrerPolicy: REFERRER_POLICIES.has(r.referrerPolicy) ? r.referrerPolicy : "strict-origin-when-cross-origin",
      mixedContentType: "none"
    };
  }
  function initiator(i, isKnown) {
    if (!i)
      return { type: "other" };
    const out = { type: i.type ?? "other" };
    const stack = stackTrace(i.stackTrace, isKnown);
    if (stack)
      out.stack = stack;
    if (i.url)
      out.url = i.url;
    if (i.lineNumber != null)
      out.lineNumber = zeroBased(i.lineNumber);
    return out;
  }
  function response(r) {
    const url = r.url ?? "";
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
      ...r.timing ? { timing: timing(r.timing) } : {},
      ...r.requestHeaders ? { requestHeaders: r.requestHeaders } : {}
    };
  }
  function timing(t) {
    const at = (v) => typeof v === "number" && v >= 0 ? v : -1;
    const phase = (start, end) => at(start) >= 0 && at(end) > at(start) ? [at(start), at(end)] : [-1, -1];
    const [dnsStart, dnsEnd] = phase(t.domainLookupStart, t.domainLookupEnd);
    const [connectStart, connectEnd] = phase(t.connectStart, t.connectEnd);
    const [sslStart, sslEnd] = phase(t.secureConnectionStart, t.connectEnd);
    return {
      requestTime: t.startTime,
      proxyStart: -1,
      proxyEnd: -1,
      dnsStart,
      dnsEnd,
      connectStart,
      connectEnd,
      sslStart,
      sslEnd,
      workerStart: -1,
      workerReady: -1,
      workerFetchStart: -1,
      workerRespondWithSettled: -1,
      sendStart: at(t.requestStart),
      sendEnd: at(t.requestStart),
      pushStart: 0,
      pushEnd: 0,
      receiveHeadersStart: at(t.responseStart),
      receiveHeadersEnd: at(t.responseStart)
    };
  }
  function enrich(res, metrics) {
    const out = { ...res };
    if (metrics.protocol)
      out.protocol = metrics.protocol;
    if (metrics.requestHeaders)
      out.requestHeaders = metrics.requestHeaders;
    const address = /^\[?([^\]]+?)\]?:(\d+)$/.exec(metrics.remoteAddress ?? "");
    if (address) {
      out.remoteIPAddress = address[1];
      out.remotePort = Number(address[2]);
    }
    if (metrics.connectionIdentifier)
      out.connectionId = hash(metrics.connectionIdentifier);
    out.encodedDataLength = encodedLength(metrics);
    return out;
  }
  function encodedLength(metrics) {
    return (metrics?.responseHeaderBytesReceived ?? 0) + (metrics?.responseBodyBytesReceived ?? 0);
  }
  function priority(p) {
    return p ? p.charAt(0).toUpperCase() + p.slice(1) : undefined;
  }
  function hash(s) {
    let h = 0;
    for (let i = 0;i < s.length; i++)
      h = h * 31 + s.charCodeAt(i) >>> 0;
    return h;
  }
  function cookie(c) {
    const expires = typeof c.expires === "number" && !c.session ? c.expires > 100000000000 ? c.expires / 1000 : c.expires : -1;
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
      ...c.sameSite && c.sameSite !== "None" ? { sameSite: c.sameSite } : {},
      priority: "Medium",
      sameParty: false,
      sourceScheme: c.secure ? "Secure" : "NonSecure",
      sourcePort: c.secure ? 443 : 80
    };
  }

  // cdp/network.ts
  function installNetwork(s) {
    s.handle("Network.enable", () => enable(s, "Network"));
    s.handle("Network.disable", () => ({}));
    s.handle("Network.getResponseBody", (p) => s.call("Network.getResponseBody", { requestId: p.requestId }));
    s.handle("Network.getRequestPostData", (p) => {
      const postData = s.state.requests.get(p.requestId)?.postData;
      if (postData == null)
        throw new ProtocolError("No post data available for the request");
      return { postData };
    });
    s.handle("Network.setCacheDisabled", (p) => s.call("Network.setResourceCachingDisabled", { disabled: !!p.cacheDisabled }));
    s.handle("Network.emulateNetworkConditionsByRule", () => ({ ruleIds: [] }));
    s.handle("Network.setExtraHTTPHeaders", (p) => s.call("Network.setExtraHTTPHeaders", { headers: p.headers ?? {} }));
    s.handle("Network.setUserAgentOverride", (p) => s.call("Page.overrideUserAgent", p.userAgent ? { value: p.userAgent } : {}));
    s.handle("Network.getCookies", (p) => cookies(s, p.urls));
    s.handle("Network.getAllCookies", () => cookies(s));
    s.handle("Network.deleteCookies", (p) => s.call("Page.deleteCookie", {
      cookieName: p.name,
      url: p.url ?? `https://${(p.domain ?? "").replace(/^\./, "")}${p.path ?? "/"}`
    }));
    s.handle("Network.setCookie", async (p) => {
      await s.call("Page.setCookie", { cookie: {
        name: p.name,
        value: p.value,
        domain: p.domain ?? new URL(p.url).hostname,
        path: p.path ?? "/",
        expires: p.expires ? p.expires * 1000 : 0,
        session: !p.expires,
        httpOnly: !!p.httpOnly,
        secure: !!p.secure,
        sameSite: p.sameSite ?? "None"
      } });
      return { success: true };
    });
    installLifecycle(s);
    installWebSockets(s);
  }
  async function cookies(s, urls) {
    const all = ((await s.call("Page.getCookies")).cookies ?? []).map(cookie);
    if (!urls?.length)
      return { cookies: all };
    const hosts = urls.map((u) => {
      try {
        return new URL(u).hostname;
      } catch {
        return "";
      }
    });
    const matches = (domain) => hosts.some((h) => h === domain.replace(/^\./, "") || h.endsWith(domain.startsWith(".") ? domain : `.${domain}`));
    return { cookies: all.filter((c) => matches(c.domain)) };
  }
  function installLifecycle(s) {
    s.on("Network.requestWillBeSent", (p) => {
      const type = resourceType(p.type);
      s.state.track(p.requestId, { type, frameId: p.frameId, loaderId: p.loaderId, postData: p.request?.postData });
      s.emit("Network.requestWillBeSent", {
        requestId: p.requestId,
        loaderId: p.loaderId ?? "",
        documentURL: p.documentURL ?? "",
        request: request(p.request, type === "Document" ? "VeryHigh" : "Medium"),
        timestamp: p.timestamp,
        wallTime: p.walltime,
        initiator: initiator(p.initiator, s.state.isAnnounced),
        redirectHasExtraInfo: false,
        ...p.redirectResponse ? { redirectResponse: response(p.redirectResponse) } : {},
        type,
        frameId: p.frameId,
        hasUserGesture: false
      });
    });
    s.on("Network.responseReceived", (p) => {
      const tracked = s.state.requests.get(p.requestId);
      const res = response(p.response);
      if (tracked) {
        tracked.response = res;
        tracked.lastTimestamp = p.timestamp;
      }
      if (p.response?.source === "memory-cache")
        s.emit("Network.requestServedFromCache", { requestId: p.requestId });
      s.emit("Network.responseReceived", {
        requestId: p.requestId,
        loaderId: p.loaderId ?? "",
        timestamp: p.timestamp,
        type: tracked?.type ?? resourceType(p.type),
        response: res,
        hasExtraInfo: false,
        frameId: p.frameId
      });
    });
    s.on("Network.dataReceived", (p) => {
      const tracked = s.state.requests.get(p.requestId);
      if (tracked)
        tracked.lastTimestamp = p.timestamp;
      s.emit("Network.dataReceived", p);
    });
    s.on("Network.loadingFinished", (p) => finish(s, p));
    s.on("Network.loadingFailed", (p) => s.emit("Network.loadingFailed", {
      requestId: p.requestId,
      timestamp: p.timestamp,
      type: s.state.requests.get(p.requestId)?.type ?? "Other",
      errorText: p.errorText ?? "",
      canceled: !!p.canceled
    }));
    s.on("Network.requestServedFromMemoryCache", (p) => fromMemoryCache(s, p));
  }
  function finish(s, p) {
    const tracked = s.state.requests.get(p.requestId);
    const metrics = p.metrics;
    const timestamp2 = Math.max(p.timestamp, tracked?.lastTimestamp ?? 0);
    if (metrics && tracked?.response) {
      const newPriority = priority(metrics.priority);
      if (newPriority)
        s.emit("Network.resourceChangedPriority", { requestId: p.requestId, newPriority, timestamp: timestamp2 });
      s.emit("Network.responseReceived", {
        requestId: p.requestId,
        loaderId: tracked.loaderId ?? "",
        timestamp: timestamp2,
        type: tracked.type,
        response: enrich(tracked.response, metrics),
        hasExtraInfo: false,
        frameId: tracked.frameId
      });
    }
    s.emit("Network.loadingFinished", { requestId: p.requestId, timestamp: timestamp2, encodedDataLength: encodedLength(metrics) });
  }
  function fromMemoryCache(s, p) {
    const resource = p.resource ?? {};
    const type = resourceType(resource.type);
    const base = { requestId: p.requestId, loaderId: p.loaderId ?? "", timestamp: p.timestamp };
    s.state.track(p.requestId, { type, frameId: p.frameId, loaderId: p.loaderId });
    s.emit("Network.requestWillBeSent", {
      ...base,
      documentURL: p.documentURL ?? "",
      request: request({ url: resource.url, method: "GET" }),
      wallTime: Date.now() / 1000,
      initiator: initiator(p.initiator, s.state.isAnnounced),
      redirectHasExtraInfo: false,
      type,
      frameId: p.frameId,
      hasUserGesture: false
    });
    s.emit("Network.requestServedFromCache", { requestId: p.requestId });
    s.emit("Network.responseReceived", {
      ...base,
      type,
      frameId: p.frameId,
      hasExtraInfo: false,
      response: response(resource.response ?? { url: resource.url, status: 200 })
    });
    s.emit("Network.dataReceived", { requestId: p.requestId, timestamp: p.timestamp, dataLength: resource.bodySize ?? 0, encodedDataLength: 0 });
    s.emit("Network.loadingFinished", { requestId: p.requestId, timestamp: p.timestamp, encodedDataLength: 0 });
  }
  function installWebSockets(s) {
    s.on("Network.webSocketCreated", (p) => s.emit("Network.webSocketCreated", { requestId: p.requestId, url: p.url }));
    s.on("Network.webSocketWillSendHandshakeRequest", (p) => s.emit("Network.webSocketWillSendHandshakeRequest", {
      requestId: p.requestId,
      timestamp: p.timestamp,
      wallTime: p.walltime,
      request: { headers: p.request?.headers ?? {} }
    }));
    s.on("Network.webSocketHandshakeResponseReceived", (p) => s.emit("Network.webSocketHandshakeResponseReceived", {
      requestId: p.requestId,
      timestamp: p.timestamp,
      response: { status: p.response?.status, statusText: p.response?.statusText ?? "", headers: p.response?.headers ?? {} }
    }));
    for (const event of ["Network.webSocketFrameReceived", "Network.webSocketFrameSent"]) {
      s.on(event, (p) => s.emit(event, {
        requestId: p.requestId,
        timestamp: p.timestamp,
        response: { opcode: p.response?.opcode, mask: !!p.response?.mask, payloadData: p.response?.payloadData ?? "" }
      }));
    }
    s.on("Network.webSocketFrameError", (p) => s.emit("Network.webSocketFrameError", p));
    s.on("Network.webSocketClosed", (p) => s.emit("Network.webSocketClosed", p));
  }

  // cdp/overlay.ts
  function highlight(c = {}) {
    const out = { showInfo: !!c.showInfo };
    for (const key of ["contentColor", "paddingColor", "borderColor", "marginColor"]) {
      if (c[key])
        out[key] = c[key];
    }
    return out;
  }
  function grid(c = {}) {
    return {
      gridColor: c.gridBorderColor ?? c.cellBorderColor ?? c.rowLineColor ?? { r: 147, g: 112, b: 219, a: 1 },
      showLineNames: !!c.showLineNames,
      showLineNumbers: !!(c.showPositiveLineNumbers || c.showNegativeLineNumbers),
      showExtendedGridLines: !!c.showGridExtensionLines,
      showTrackSizes: !!c.showTrackSizes,
      showAreaNames: !!c.showAreaNames
    };
  }
  function flex(c = {}) {
    return {
      flexColor: c.containerBorder?.color ?? c.lineSeparator?.color ?? { r: 147, g: 112, b: 219, a: 1 },
      showOrderNumbers: false
    };
  }
  function installOverlay(s) {
    s.handle("Overlay.enable", () => ({}));
    s.handle("Overlay.disable", () => s.call("DOM.hideHighlight").catch(() => ({})));
    s.handle("Overlay.setInspectMode", (p) => s.call("DOM.setInspectModeEnabled", {
      enabled: p.mode !== "none" && p.mode !== undefined,
      highlightConfig: highlight(p.highlightConfig),
      showRulers: !!p.highlightConfig?.showRulers
    }));
    s.handle("Overlay.highlightNode", async (p) => {
      const config = highlight(p.highlightConfig);
      if (p.selector)
        return s.call("DOM.highlightSelector", { selectorString: p.selector, highlightConfig: config });
      if (p.objectId)
        return s.call("DOM.highlightNode", { objectId: p.objectId, highlightConfig: config });
      return s.call("DOM.highlightNode", { nodeId: await nodeIdOf(s, p), highlightConfig: config });
    });
    s.handle("Overlay.hideHighlight", () => s.call("DOM.hideHighlight"));
    s.handle("Overlay.highlightRect", (p) => s.call("DOM.highlightRect", {
      x: p.x,
      y: p.y,
      width: p.width,
      height: p.height,
      color: p.color,
      outlineColor: p.outlineColor
    }));
    s.handle("Overlay.highlightQuad", (p) => s.call("DOM.highlightQuad", { quad: p.quad, color: p.color, outlineColor: p.outlineColor }));
    s.handle("Overlay.highlightFrame", (p) => s.call("DOM.highlightFrame", {
      frameId: p.frameId,
      contentColor: p.contentColor,
      contentOutlineColor: p.contentOutlineColor
    }));
    s.handle("Overlay.setShowPaintRects", (p) => s.call("Page.setShowPaintRects", { result: !!p.result }));
    installLayoutOverlays(s);
  }
  function installLayoutOverlays(s) {
    const shown = { grid: new Set, flex: new Set };
    const sync = async (kind, configs) => {
      const wanted = new Map(configs.map((c) => [c.nodeId, c]));
      const [show, hide] = kind === "grid" ? ["DOM.showGridOverlay", "DOM.hideGridOverlay"] : ["DOM.showFlexOverlay", "DOM.hideFlexOverlay"];
      for (const id of shown[kind]) {
        if (!wanted.has(id))
          await s.call(hide, { nodeId: id }).catch(() => {});
      }
      shown[kind] = new Set(wanted.keys());
      for (const [nodeId, c] of wanted) {
        const params = kind === "grid" ? { nodeId, gridOverlayConfig: grid(c.gridHighlightConfig) } : { nodeId, flexOverlayConfig: flex(c.flexContainerHighlightConfig) };
        await s.call(show, params).catch(() => {});
      }
      return {};
    };
    s.handle("Overlay.setShowGridOverlays", (p) => sync("grid", p.gridNodeHighlightConfigs ?? []));
    s.handle("Overlay.setShowFlexOverlays", (p) => sync("flex", p.flexNodeHighlightConfigs ?? []));
  }

  // cdp/properties.ts
  var ENTRIES_PREFIX = "redent-entries:";
  var SCOPES_PREFIX = "redent-scopes:";
  var SCOPE_TITLES = {
    global: "Global",
    with: "With Block",
    closure: "Closure",
    catch: "Catch",
    functionName: "Closure",
    globalLexicalEnvironment: "Script",
    nestedLexical: "Block"
  };
  function installProperties(s) {
    s.handle("Runtime.getProperties", async (p) => {
      if (typeof p.objectId === "string" && p.objectId.startsWith(ENTRIES_PREFIX)) {
        return entries(s, p.objectId.slice(ENTRIES_PREFIX.length));
      }
      if (typeof p.objectId === "string" && p.objectId.startsWith(SCOPES_PREFIX)) {
        return scopes(s, p.objectId.slice(SCOPES_PREFIX.length));
      }
      const internals = !p.accessorPropertiesOnly;
      const [r, preview2, fn] = await Promise.all([
        s.call("Runtime.getProperties", {
          objectId: p.objectId,
          ownProperties: !!p.ownProperties,
          generatePreview: p.generatePreview
        }),
        internals ? s.call("Runtime.getPreview", { objectId: p.objectId }).catch(() => ({})) : {},
        internals ? s.call("Debugger.getFunctionDetails", { functionId: p.objectId }).catch(() => ({})) : {}
      ]);
      const out = properties(r, p);
      if (COLLECTIONS.has(preview2.preview?.subtype)) {
        out.internalProperties.push(entriesProperty(p.objectId, preview2.preview?.size));
      }
      if (fn.details)
        out.internalProperties.push(...functionInternals(p.objectId, fn.details));
      return out;
    });
  }
  var COLLECTIONS = new Set(["map", "set", "weakmap", "weakset"]);
  function properties(r, p) {
    const result = [];
    const internalProperties = (r.internalProperties ?? []).map(internal);
    const privateProperties = [];
    for (const d of r.properties ?? []) {
      if (d.name === "__proto__") {
        if (d.value && !p.accessorPropertiesOnly)
          internalProperties.push({ name: "[[Prototype]]", value: remoteObject(d.value) });
        continue;
      }
      if (p.accessorPropertiesOnly && !d.get && !d.set)
        continue;
      if (p.nonIndexedPropertiesOnly && /^\d+$/.test(d.name))
        continue;
      if (d.isPrivate) {
        privateProperties.push({ name: d.name, value: remoteObject(d.value) });
        continue;
      }
      result.push(descriptor(d));
    }
    return { result, internalProperties, ...privateProperties.length ? { privateProperties } : {} };
  }
  function descriptor(d) {
    const out = {
      name: d.name,
      configurable: !!d.configurable,
      enumerable: !!d.enumerable,
      isOwn: d.isOwn
    };
    if (d.value)
      out.value = remoteObject(d.value);
    if (d.writable !== undefined)
      out.writable = d.writable;
    if (d.get)
      out.get = remoteObject(d.get);
    if (d.set)
      out.set = remoteObject(d.set);
    if (d.symbol)
      out.symbol = remoteObject(d.symbol);
    if (d.wasThrown)
      out.wasThrown = true;
    return out;
  }
  function internal(d) {
    const name = internalName(d.name);
    const value = remoteObject(d.value);
    if (d.name === "status" && value?.value === "resolved")
      value.value = "fulfilled";
    return { name, value };
  }
  function entriesProperty(objectId, count) {
    return {
      name: "[[Entries]]",
      value: {
        type: "object",
        subtype: "array",
        className: "Array",
        description: `Array(${count ?? 0})`,
        objectId: ENTRIES_PREFIX + objectId
      }
    };
  }
  async function entries(s, objectId) {
    const r = await s.call("Runtime.getCollectionEntries", { objectId, objectGroup: "console" });
    const result = (r.entries ?? []).map((e, index) => ({
      name: String(index),
      configurable: false,
      enumerable: true,
      isOwn: true,
      value: entryObject(e)
    }));
    return { result, internalProperties: [] };
  }
  function entryObject(e) {
    const value = remoteObject(e.value);
    if (!e.key)
      return value;
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
          { name: "value", type: value.type, subtype: value.subtype, value: String(value.description ?? value.value) }
        ]
      }
    };
  }
  function functionInternals(objectId, details) {
    const out = [{
      name: "[[FunctionLocation]]",
      value: { type: "object", subtype: "internal#location", value: details.location, description: "Object" }
    }];
    const count = details.scopeChain?.length ?? 0;
    if (count) {
      out.push({
        name: "[[Scopes]]",
        value: { type: "object", subtype: "internal#scopeList", className: "Array", description: `Scopes[${count}]`, objectId: SCOPES_PREFIX + objectId }
      });
    }
    return out;
  }
  async function scopes(s, functionId) {
    const details = (await s.call("Debugger.getFunctionDetails", { functionId })).details;
    const result = (details?.scopeChain ?? []).map((scope, index) => {
      const title = SCOPE_TITLES[scope.type] ?? "Closure";
      const name = scope.name ?? (scope.type === "closure" ? details.displayName || details.name : "");
      return {
        name: String(index),
        configurable: false,
        enumerable: true,
        isOwn: true,
        value: {
          type: "object",
          subtype: "internal#scope",
          className: "Object",
          description: name ? `${title} (${name})` : title,
          objectId: scope.object?.objectId
        }
      };
    });
    return { result, internalProperties: [] };
  }

  // cdp/side-effects.ts
  var FORBIDDEN_WORDS = new Set([
    "new",
    "delete",
    "await",
    "yield",
    "function",
    "class",
    "import",
    "async",
    "var",
    "let",
    "const",
    "for",
    "while",
    "do",
    "if",
    "else",
    "switch",
    "try",
    "catch",
    "throw",
    "return",
    "with",
    "debugger",
    "super",
    "eval"
  ]);
  var OPERATOR_WORDS = new Set(["typeof", "void", "in", "instanceof", "of", "case"]);
  function isSideEffectFree(expression) {
    const tokens = tokenize(expression);
    if (!tokens)
      return false;
    let previous = "";
    for (const token of tokens) {
      if (FORBIDDEN_WORDS.has(token))
        return false;
      if (token === "=" || token === "++" || token === "--" || token === "=>")
        return false;
      if (/^[-+*/%&|^]=$|^(\*\*|<<|>>|>>>|&&|\|\||\?\?)=$/.test(token))
        return false;
      if (token === "(" && isCallee(previous))
        return false;
      if (token === "`")
        return false;
      previous = token;
    }
    return true;
  }
  function isCallee(previous) {
    if (!previous)
      return false;
    if (previous === ")" || previous === "]" || previous === "}" || previous === '"' || previous === "?.")
      return true;
    return /^[\w$]+$/.test(previous) && !OPERATOR_WORDS.has(previous);
  }
  function tokenize(source) {
    const tokens = [];
    let i = 0;
    while (i < source.length) {
      const c = source[i];
      if (/\s/.test(c)) {
        i++;
        continue;
      }
      if (c === "/" && (source[i + 1] === "/" || source[i + 1] === "*"))
        return null;
      if (c === "'" || c === '"') {
        const end = closingQuote(source, i);
        if (end < 0)
          return null;
        tokens.push('"');
        i = end + 1;
        continue;
      }
      if (c === "`") {
        tokens.push("`");
        i++;
        continue;
      }
      const word = /^[\w$]+/.exec(source.slice(i));
      if (word) {
        tokens.push(word[0]);
        i += word[0].length;
        continue;
      }
      const operator = /^(>>>=|\*\*=|<<=|>>=|&&=|\|\|=|\?\?=|===|!==|>>>|\.\.\.|=>|==|!=|<=|>=|&&|\|\||\?\?|\?\.|\+\+|--|\*\*|<<|>>|[-+*/%&|^]=)/.exec(source.slice(i));
      if (operator) {
        tokens.push(operator[0]);
        i += operator[0].length;
        continue;
      }
      tokens.push(c);
      i++;
    }
    return tokens;
  }
  function closingQuote(source, start) {
    const quote = source[start];
    for (let i = start + 1;i < source.length; i++) {
      if (source[i] === "\\") {
        i++;
        continue;
      }
      if (source[i] === quote)
        return i;
      if (source[i] === `
`)
        return -1;
    }
    return -1;
  }

  // cdp/console-api.ts
  var MONITOR_PRELUDE = `(() => {
  if (typeof globalThis.monitor === "function") return;
  const queue = [];
  const define = (name, value) => Object.defineProperty(globalThis, name, { value, configurable: true, writable: true });
  define("__redentMonitorQueue", queue);
  define("monitor", (fn) => { if (typeof fn === "function") queue.push([true, fn]); });
  define("unmonitor", (fn) => { if (typeof fn === "function") queue.push([false, fn]); });
})()`;
  var USES_MONITOR = /\b(un)?monitor\s*\(/;
  var RESERVED = new Set([
    "await",
    "yield",
    "let",
    "static",
    "enum",
    "implements",
    "interface",
    "package",
    "private",
    "protected",
    "public",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "debugger",
    "default",
    "delete",
    "do",
    "else",
    "export",
    "extends",
    "false",
    "finally",
    "for",
    "function",
    "if",
    "import",
    "in",
    "instanceof",
    "new",
    "null",
    "return",
    "super",
    "switch",
    "this",
    "throw",
    "true",
    "try",
    "typeof",
    "var",
    "void",
    "while",
    "with"
  ]);
  var LEXICAL = /(?:^|[;\n{}]\s*)(?:let|const|class)\s+([A-Za-z_$][\w$]*)/g;

  class ConsoleHelpers {
    s;
    monitors = new Map;
    typedNames = new Set;
    constructor(s) {
      this.s = s;
    }
    async prepare(expression, contextId) {
      for (const match of expression.matchAll(LEXICAL))
        this.typedNames.add(match[1]);
      if (!USES_MONITOR.test(expression))
        return;
      await this.s.call("Runtime.evaluate", { expression: MONITOR_PRELUDE, contextId, doNotPauseOnExceptionsAndMuteConsole: true });
    }
    async finish(result, contextId) {
      await this.s.call("Runtime.callFunctionOn", {
        objectId: await this.globalObject(contextId),
        functionDeclaration: "function (value) { Object.defineProperty(this, '$_', { value, configurable: true, writable: true }); }",
        arguments: [result?.objectId ? { objectId: result.objectId } : { value: result?.value }]
      }).catch(() => {});
      await this.applyMonitors(contextId).catch(() => {});
      this.release();
    }
    async globalObject(contextId) {
      const r = await this.s.call("Runtime.evaluate", { expression: "globalThis", contextId, objectGroup: "redent-console" });
      return r.result?.objectId;
    }
    release() {
      this.s.call("Runtime.releaseObjectGroup", { objectGroup: "redent-console" }).catch(() => {});
    }
    async applyMonitors(contextId) {
      const r = await this.s.call("Runtime.evaluate", {
        expression: "globalThis.__redentMonitorQueue ? globalThis.__redentMonitorQueue.splice(0) : []",
        contextId,
        objectGroup: "redent-console"
      });
      const list = await this.s.call("Runtime.getProperties", { objectId: r.result?.objectId, ownProperties: true });
      for (const entry of list.properties ?? []) {
        if (!/^\d+$/.test(entry.name) || !entry.value?.objectId)
          continue;
        const pair = await this.s.call("Runtime.getProperties", { objectId: entry.value.objectId, ownProperties: true });
        const on = pair.properties?.find((p) => p.name === "0")?.value?.value;
        const fn = pair.properties?.find((p) => p.name === "1")?.value;
        if (fn?.objectId)
          await this.monitor(fn.objectId, !!on);
      }
    }
    async monitor(functionId, on) {
      const details = (await this.s.call("Debugger.getFunctionDetails", { functionId })).details;
      const key = `${details.location.scriptId}:${details.location.lineNumber}:${details.location.columnNumber}`;
      const existing = this.monitors.get(key);
      if (existing) {
        await this.s.call("Debugger.removeBreakpoint", { breakpointId: existing });
        this.monitors.delete(key);
      }
      if (!on)
        return;
      const name = details.displayName || details.name || "(anonymous)";
      const shape = await this.shape(details.location);
      const values = shape.params.length ? ` + " with arguments: " + [${shape.params.join(", ")}].join(", ")` : "";
      const log = `console.log(${JSON.stringify(`function ${name} called`)}${values})`;
      const r = await this.s.call("Debugger.setBreakpoint", {
        location: shape.body,
        options: { autoContinue: true, actions: [{ type: "evaluate", data: log }] }
      });
      this.monitors.set(key, r.breakpointId);
    }
    async shape(location) {
      const fetch = (id) => this.s.call("Debugger.getScriptSource", { scriptId: id });
      const source = await this.s.state.scriptSource(location.scriptId, fetch);
      const lines = source.split(`
`);
      const from = lines.slice(0, location.lineNumber).reduce((n, line) => n + line.length + 1, 0) + (location.columnNumber ?? 0);
      const shape = functionShape(source, from);
      if (!shape)
        return { body: location, params: [] };
      const before = source.slice(0, shape.body).split(`
`);
      return {
        body: { scriptId: location.scriptId, lineNumber: before.length - 1, columnNumber: before[before.length - 1].length },
        params: shape.params
      };
    }
    async lexicalNames(contextId) {
      const candidates = new Set(this.typedNames);
      for (const scriptId of this.s.state.scripts.keys()) {
        const source = await this.s.state.scriptSource(scriptId, (id) => this.s.call("Debugger.getScriptSource", { scriptId: id }));
        for (const match of source.matchAll(LEXICAL))
          candidates.add(match[1]);
      }
      const names = [...candidates].filter((n) => !RESERVED.has(n));
      if (!names.length)
        return [];
      const checks = names.map((n) => `(() => { try { ${n}; return ${JSON.stringify(n)}; } catch { return null; } })()`);
      const r = await this.s.call("Runtime.evaluate", {
        expression: `[${checks.join(",")}].filter((n) => n && !(n in globalThis))`,
        contextId,
        returnByValue: true,
        doNotPauseOnExceptionsAndMuteConsole: true
      });
      return Array.isArray(r.result?.value) ? r.result.value : [];
    }
  }
  function functionShape(source, from) {
    const arrow = source.indexOf("=>", from);
    const paren = source.indexOf("(", from);
    if (paren < 0 && arrow < 0)
      return null;
    let i;
    let list;
    if (paren >= 0 && (arrow < 0 || paren < arrow)) {
      let depth = 0;
      for (i = paren;i < source.length; i++) {
        if (source[i] === "(")
          depth++;
        else if (source[i] === ")" && --depth === 0)
          break;
      }
      list = source.slice(paren + 1, i);
      i++;
    } else {
      list = source.slice(from, arrow);
      i = arrow;
    }
    while (/\s/.test(source[i] ?? ""))
      i++;
    if (source.startsWith("=>", i)) {
      i += 2;
      while (/\s/.test(source[i] ?? ""))
        i++;
    }
    if (i >= source.length)
      return null;
    const names = list.split(",").map((p) => p.trim().replace(/^\.\.\./, "").split("=")[0].trim());
    const params = names.every((n) => /^[A-Za-z_$][\w$]*$/.test(n)) ? names : [];
    return { body: source[i] === "{" ? i + 1 : i, params };
  }

  // cdp/runtime.ts
  var SIDE_EFFECT = {
    result: { type: "object", subtype: "error", className: "EvalError", description: "EvalError: Possible side-effect in debug-evaluate" },
    exceptionDetails: { exceptionId: 1, text: "Uncaught", lineNumber: 0, columnNumber: 0 }
  };
  function installRuntime(s) {
    const helpers = new ConsoleHelpers(s);
    s.handle("Runtime.enable", async () => {
      await replay(s, "Runtime");
      await replay(s, "Console");
    });
    s.handle("Runtime.evaluate", (p) => consoleEvaluate(s, helpers, p));
    s.handle("Runtime.awaitPromise", async (p) => evaluation(await s.call("Runtime.awaitPromise", {
      promiseObjectId: p.promiseObjectId,
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview
    })));
    s.handle("Runtime.callFunctionOn", (p) => callFunctionOn(s, p));
    s.handle("Runtime.releaseObject", (p) => s.call("Runtime.releaseObject", { objectId: p.objectId }));
    s.handle("Runtime.releaseObjectGroup", (p) => s.call("Runtime.releaseObjectGroup", { objectGroup: p.objectGroup }));
    s.handle("Runtime.compileScript", (p) => compile(s, p.expression));
    s.handle("Runtime.globalLexicalScopeNames", async (p) => ({ names: await helpers.lexicalNames(p.executionContextId) }));
    s.handle("Runtime.getIsolateId", () => ({ id: "redent" }));
    s.handle("Runtime.getHeapUsage", () => ({ usedSize: 0, totalSize: 0 }));
    s.handle("Runtime.discardConsoleEntries", () => s.call("Console.clearMessages"));
    s.handle("Runtime.setAsyncCallStackDepth", (p) => s.call("Debugger.setAsyncStackTraceDepth", { depth: p.maxDepth ?? 0 }));
    installProperties(s);
    installErrors(s);
    installContexts(s);
  }
  function contextIdOf(p) {
    if (p.uniqueContextId)
      return Number(p.uniqueContextId);
    return p.contextId ?? p.executionContextId;
  }
  async function consoleEvaluate(s, helpers, p) {
    if (!p.replMode || p.throwOnSideEffect)
      return evaluate(s, p);
    const contextId = contextIdOf(p);
    await helpers.prepare(p.expression ?? "", contextId).catch(() => {});
    const r = await evaluate(s, p);
    if (!r.exceptionDetails)
      await helpers.finish(r.result, contextId);
    return r;
  }
  async function evaluate(s, p) {
    if (p.throwOnSideEffect && !isSideEffectFree(p.expression ?? ""))
      return SIDE_EFFECT;
    const params = {
      objectGroup: p.objectGroup,
      includeCommandLineAPI: p.includeCommandLineAPI,
      doNotPauseOnExceptionsAndMuteConsole: p.silent || p.throwOnSideEffect,
      contextId: contextIdOf(p),
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview,
      emulateUserGesture: p.userGesture
    };
    let r = await s.call("Runtime.evaluate", { ...params, expression: p.expression });
    let awaits = !!p.awaitPromise;
    if (p.replMode && r.wasThrown && /\bawait\b/.test(p.expression) && r.result?.className === "SyntaxError") {
      for (const body of [`return (${p.expression}
);`, `${p.expression}
`]) {
        r = await s.call("Runtime.evaluate", { ...params, expression: `(async () => { ${body} })()` });
        awaits = true;
        if (!(r.wasThrown && r.result?.className === "SyntaxError"))
          break;
      }
    }
    if (awaits && !r.wasThrown && r.result?.className === "Promise" && r.result.objectId) {
      r = await s.call("Runtime.awaitPromise", {
        promiseObjectId: r.result.objectId,
        returnByValue: p.returnByValue,
        generatePreview: p.generatePreview
      });
    }
    return withThrownStack(s, evaluation(r));
  }
  async function withThrownStack(s, r) {
    if (!r.exceptionDetails)
      return r;
    const exception2 = await withStack(s, r.exceptionDetails.exception);
    return { result: exception2, exceptionDetails: { ...r.exceptionDetails, exception: exception2 } };
  }
  async function callFunctionOn(s, p) {
    const args = (p.arguments ?? []).map((a) => a.objectId ? { objectId: a.objectId } : { value: a.value });
    if (!p.objectId) {
      const values = args.map((a) => JSON.stringify(a.value ?? null)).join(", ");
      return evaluate(s, { ...p, throwOnSideEffect: false, expression: `(${p.functionDeclaration})(${values})`, contextId: p.executionContextId });
    }
    return withThrownStack(s, evaluation(await s.call("Runtime.callFunctionOn", {
      objectId: p.objectId,
      functionDeclaration: p.functionDeclaration,
      arguments: args,
      doNotPauseOnExceptionsAndMuteConsole: p.silent,
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview,
      emulateUserGesture: p.userGesture,
      awaitPromise: p.awaitPromise
    })));
  }
  async function compile(s, source) {
    const r = await s.call("Runtime.parse", { source });
    if (r.result === "none")
      return {};
    const description = r.result === "recoverable" ? "SyntaxError: Unexpected end of input" : r.result === "unterminated-literal" ? "SyntaxError: Unterminated template literal" : `SyntaxError: ${r.message ?? "Invalid syntax"}`;
    const exception2 = { type: "object", subtype: "error", className: "SyntaxError", description };
    return {
      exceptionDetails: {
        exceptionId: 1,
        text: "Uncaught",
        exception: exception2,
        lineNumber: 0,
        columnNumber: 0
      }
    };
  }
  function installContexts(s) {
    s.on("Runtime.executionContextCreated", ({ context }) => {
      if (!context || context.type !== "normal")
        return;
      s.state.addContext(context.id, context.frameId);
      s.emit("Runtime.executionContextCreated", {
        context: {
          id: context.id,
          uniqueId: String(context.id),
          name: context.name ?? "",
          origin: s.state.origin(context.frameId),
          auxData: { isDefault: true, type: "default", frameId: context.frameId }
        }
      });
    });
  }

  // entry.ts
  var HANDLER_NAME = "redentDevTools";
  var DISPATCHERS = ["dispatchMessageAsync", "dispatchMessage"];
  var session = null;
  function toNative(raw) {
    window.webkit.messageHandlers[HANDLER_NAME].postMessage(raw);
  }
  function parse(message) {
    try {
      return typeof message === "string" ? JSON.parse(message) : JSON.parse(JSON.stringify(message));
    } catch {
      return null;
    }
  }
  function route(active, message) {
    const outer = parse(message);
    if (!outer)
      return true;
    if (outer.method !== "Target.dispatchMessageFromTarget") {
      active.fromOuter(outer);
      return !isSessionID(outer.id);
    }
    if (!active.isPageTarget(outer.params?.targetId))
      return true;
    const inner = parse(outer.params?.message);
    if (!inner)
      return true;
    active.fromBackend(inner);
    if (WITHHELD.has(inner.method ?? ""))
      return false;
    return !isSessionID(inner.id);
  }
  var WITHHELD = new Set(["Debugger.paused", "Debugger.resumed", "DOM.inspect", "Inspector.inspect"]);
  function tap(name) {
    const original = InspectorFrontendAPI[name];
    if (typeof original !== "function")
      return;
    InspectorFrontendAPI[name] = function(message) {
      if (session && !route(session, message))
        return;
      return original.call(this, message);
    };
  }
  var bringToFront = null;
  function holdWindowBack() {
    const host = InspectorFrontendHost;
    if (bringToFront || typeof host.bringToFront !== "function")
      return;
    bringToFront = host.bringToFront;
    try {
      host.bringToFront = () => {};
    } catch {
      bringToFront = null;
    }
  }
  function releaseWindow() {
    if (!bringToFront)
      return;
    try {
      InspectorFrontendHost.bringToFront = bringToFront;
    } catch {}
    bringToFront = null;
  }
  function attach() {
    holdWindowBack();
    const transport = {
      toBackend: (raw) => InspectorFrontendHost.sendMessageToBackend(raw),
      toTools: toNative
    };
    session = new Session(transport, WI.pageTarget?.identifier ?? null);
    installRuntime(session);
    installConsole(session);
    installPage(session);
    installNetwork(session);
    installDebugger(session);
    installEmulation(session);
    installDOM(session);
    installOverlay(session);
    installCSS(session);
    installFallback(session);
  }
  if (!window.__redentDevTools) {
    DISPATCHERS.forEach(tap);
    window.__redentDevTools = {
      attach,
      detach: () => {
        session = null;
        releaseWindow();
      },
      fromTools: (raw) => session?.fromTools(raw)
    };
  }
})();
