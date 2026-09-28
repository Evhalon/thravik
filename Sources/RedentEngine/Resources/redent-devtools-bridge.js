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
      properties: (p.properties ?? []).filter((q) => !q.internal).map(propertyPreview)
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
      functionName: f.functionName ?? "",
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
        last = translate(s, await withPreviews(s, message));
        if (last)
          s.emit(last.method, last.params);
      });
    });
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
  function apiCall(s, m) {
    const type = m.type === "log" || !m.type ? level(m.level) : API_TYPES[m.type] ?? "log";
    const args = m.parameters?.length ? m.parameters.map(remoteObject) : [{ type: "string", value: m.text ?? "" }];
    return {
      type,
      args,
      executionContextId: s.state.mainContextId || 1,
      timestamp: Date.now(),
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
        executionContextId: s.state.mainContextId || 1
      }
    };
  }
  function logEntry(s, m) {
    return {
      source: LOG_SOURCES.has(m.source) ? m.source : m.source === "css" ? "rendering" : "other",
      level: m.level === "debug" ? "verbose" : m.level === "log" ? "info" : m.level,
      text: m.text ?? "",
      timestamp: Date.now(),
      url: m.url,
      lineNumber: m.line ? zeroBased(m.line) : undefined,
      stackTrace: stackTrace(m.stackTrace, s.state.isAnnounced),
      networkRequestId: m.networkRequestId
    };
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
    installEvents(s);
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
  function installEvents(s) {
    s.on("Debugger.scriptParsed", (p) => {
      if (p.isContentScript)
        return;
      const url = p.url || p.sourceURL || "";
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
    const origin = f.securityOrigin ?? "";
    s.state.setOrigin(f.id, origin);
    if (!f.parentId) {
      s.state.mainFrameId = f.id;
      s.state.mainFrameURL = f.url;
    }
    let host = "";
    try {
      host = new URL(f.url).hostname;
    } catch {}
    const secure = origin.startsWith("https:") || host === "localhost" || host === "127.0.0.1";
    return {
      id: f.id,
      ...f.parentId ? { parentId: f.parentId } : {},
      loaderId: f.loaderId,
      name: f.name,
      url: f.url,
      domainAndRegistry: host.split(".").slice(-2).join("."),
      securityOrigin: origin,
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
    const timestamp = Math.max(p.timestamp, tracked?.lastTimestamp ?? 0);
    if (metrics && tracked?.response) {
      const newPriority = priority(metrics.priority);
      if (newPriority)
        s.emit("Network.resourceChangedPriority", { requestId: p.requestId, newPriority, timestamp });
      s.emit("Network.responseReceived", {
        requestId: p.requestId,
        loaderId: tracked.loaderId ?? "",
        timestamp,
        type: tracked.type,
        response: enrich(tracked.response, metrics),
        hasExtraInfo: false,
        frameId: tracked.frameId
      });
    }
    s.emit("Network.loadingFinished", { requestId: p.requestId, timestamp, encodedDataLength: encodedLength(metrics) });
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

  // cdp/properties.ts
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
  var ENTRIES_PREFIX = "redent-entries:";
  function installProperties(s) {
    s.handle("Runtime.getProperties", async (p) => {
      if (typeof p.objectId === "string" && p.objectId.startsWith(ENTRIES_PREFIX)) {
        return entries(s, p.objectId.slice(ENTRIES_PREFIX.length));
      }
      const [r, preview2] = await Promise.all([
        s.call("Runtime.getProperties", {
          objectId: p.objectId,
          ownProperties: !!p.ownProperties,
          generatePreview: p.generatePreview
        }),
        p.ownProperties ? s.call("Runtime.getPreview", { objectId: p.objectId }).catch(() => ({})) : {}
      ]);
      const out = properties(r, p);
      if (COLLECTIONS.has(preview2.preview?.subtype)) {
        out.internalProperties.push(entriesProperty(p.objectId, preview2.preview?.size));
      }
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
    const name = INTERNAL_NAMES[d.name] ?? `[[${d.name.charAt(0).toUpperCase()}${d.name.slice(1)}]]`;
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

  // cdp/runtime.ts
  var SIDE_EFFECT = {
    result: { type: "object", subtype: "error", className: "EvalError", description: "EvalError: Possible side-effect in debug-evaluate" },
    exceptionDetails: { exceptionId: 1, text: "Uncaught", lineNumber: 0, columnNumber: 0 }
  };
  function installRuntime(s) {
    s.handle("Runtime.enable", async () => {
      await replay(s, "Runtime");
      await replay(s, "Console");
    });
    s.handle("Runtime.evaluate", (p) => evaluate(s, p));
    s.handle("Runtime.awaitPromise", async (p) => evaluation(await s.call("Runtime.awaitPromise", {
      promiseObjectId: p.promiseObjectId,
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview
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
  function contextId(p) {
    if (p.uniqueContextId)
      return Number(p.uniqueContextId);
    return p.contextId ?? p.executionContextId;
  }
  async function evaluate(s, p) {
    if (p.throwOnSideEffect)
      return SIDE_EFFECT;
    const params = {
      objectGroup: p.objectGroup,
      includeCommandLineAPI: p.includeCommandLineAPI,
      doNotPauseOnExceptionsAndMuteConsole: p.silent,
      contextId: contextId(p),
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
    if (!awaits || r.wasThrown || r.result?.className !== "Promise" || !r.result.objectId)
      return evaluation(r);
    return evaluation(await s.call("Runtime.awaitPromise", {
      promiseObjectId: r.result.objectId,
      returnByValue: p.returnByValue,
      generatePreview: p.generatePreview
    }));
  }
  async function callFunctionOn(s, p) {
    if (p.throwOnSideEffect)
      return SIDE_EFFECT;
    const args = (p.arguments ?? []).map((a) => a.objectId ? { objectId: a.objectId } : { value: a.value });
    if (!p.objectId) {
      const values = args.map((a) => JSON.stringify(a.value ?? null)).join(", ");
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
      awaitPromise: p.awaitPromise
    }));
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
    return !isSessionID(inner.id);
  }
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
  function attach() {
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
    installFallback(session);
  }
  if (!window.__redentDevTools) {
    DISPATCHERS.forEach(tap);
    window.__redentDevTools = {
      attach,
      detach: () => {
        session = null;
      },
      fromTools: (raw) => session?.fromTools(raw)
    };
  }
})();
