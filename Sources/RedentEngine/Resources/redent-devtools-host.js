// The embedder side of Chrome's DevTools frontend, when Redent shows it
// docked under a page. Chrome's own browser normally provides this object;
// here it hands protocol messages to Redent, which relays them to the tab's
// WebKit inspector, and answers everything else the way a browser with no
// file system, sync or metrics would.
//
// Installed before the frontend loads. The frontend adds its own `events`
// object to it, and installs `InspectorFrontendAPI`, which Redent calls to
// deliver messages back.
(() => {
  const post = (message) => window.webkit.messageHandlers.redentDevToolsHost.postMessage(message);
  const later = (callback, value) => setTimeout(() => callback(value), 0);
  const notImplemented = { error: "Not available in Redent" };
  const noop = () => {};

  // Chrome gives every shadow root its own selection; WebKit keeps one per
  // document and has no `ShadowRoot.getSelection`. Tree rows ask it on every
  // click before toggling, so without it expanding a console object or a
  // network section threw, and only a double click still got through.
  if (typeof ShadowRoot.prototype.getSelection !== "function") {
    ShadowRoot.prototype.getSelection = function () { return this.ownerDocument.getSelection(); };
  }

  // Chrome's frontend defers work — parsing in the Sources editor, queued
  // panel updates — to idle time and background tasks, through APIs WebKit
  // lacks and calls unchecked; each call would throw instead of running.
  if (typeof globalThis.requestIdleCallback !== "function") {
    globalThis.requestIdleCallback = (callback, options) => setTimeout(() => {
      const start = performance.now();
      callback({ didTimeout: false, timeRemaining: () => Math.max(0, 50 - (performance.now() - start)) });
    }, Math.min(options?.timeout ?? 1, 1));
    globalThis.cancelIdleCallback = (id) => clearTimeout(id);
  }
  if (typeof globalThis.scheduler !== "object") {
    const later = (delay) => new Promise((resolve) => setTimeout(resolve, delay ?? 0));
    globalThis.scheduler = {
      postTask: (task, options) => later(options?.delay).then(() => task()),
      yield: () => later(0),
    };
  }

  // Device mode lays the emulated screen out in the rectangle it reports for
  // the page, already shrunk to fit; Redent zooms the page by the same scale
  // so it still lays out at the device's own width. Everything else about the
  // override goes to the page as usual.
  const watchDeviceMode = (message) => {
    if (!message.includes("DeviceMetricsOverride")) return;
    const { method, params } = JSON.parse(message);
    if (method === "Emulation.setDeviceMetricsOverride") post({ kind: "device", scale: params?.scale || 1 });
    if (method === "Emulation.clearDeviceMetricsOverride") post({ kind: "device" });
  };

  const host = {
    platform: () => "mac",
    isHostedMode: () => false,
    sendMessageToBackend: (message) => {
      post({ kind: "protocol", message });
      watchDeviceMode(message);
    },
    connectionReady: noop,
    // Chrome draws these menus natively; Redent lets the frontend draw its own.
    loadCompleted: () => window.InspectorFrontendAPI?.setUseSoftMenu?.(true),
    showContextMenuAtPoint: () => { throw new Error("Soft context menu should be used"); },
    closeWindow: () => post({ kind: "close" }),
    bringToFront: noop,
    // Docked, DevTools fills the tab and leaves a hole for the page; Redent
    // lays the page out over that hole. There is no separate window to undock
    // into, so undocking keeps the last docked layout.
    setIsDocked: (_docked, callback) => later(callback),
    setInspectedPageBounds: (bounds) => post({ kind: "bounds", ...bounds }),
    inspectElementCompleted: noop,
    setInjectedScriptForOrigin: noop,
    inspectedURLChanged: noop,
    copyText: (text) => text != null && post({ kind: "copy", text: String(text) }),
    openInNewTab: (url) => post({ kind: "open", url: String(url) }),
    openSearchResultsInNewTab: noop,
    showItemInFolder: noop,
    // Redent asks where in a save panel, then answers with `savedURL` or
    // `canceledSaveURL`, and `appendedToURL` for each streamed chunk.
    save: (url, content, forceSaveAs, isBase64) => post({
      kind: "save", url: String(url), content: String(content ?? ""), forceSaveAs: !!forceSaveAs, base64: !!isBase64,
    }),
    append: (url, content) => post({ kind: "append", url: String(url), content: String(content ?? "") }),
    close: noop,
    getPreferences: (callback) => {
      const preferences = {};
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key !== null) preferences[key] = localStorage.getItem(key);
      }
      callback(preferences);
    },
    getPreference: (name, callback) => callback(localStorage.getItem(name) ?? undefined),
    setPreference: (name, value) => localStorage.setItem(name, value),
    removePreference: (name) => localStorage.removeItem(name),
    clearPreferences: () => localStorage.clear(),
    registerPreference: noop,
    getSyncInformation: (callback) => callback({ isSyncActive: false, arePreferencesSynced: false }),
    getHostConfig: (callback) => callback({ devToolsFlexibleLayout: { verticalDrawerEnabled: true } }),
    loadNetworkResource: (_url, _headers, _streamId, callback) => later(callback, { statusCode: 404 }),
    requestFileSystems() { this.events?.dispatchEventToListeners("fileSystemsLoaded", []); },
    addFileSystem: noop,
    removeFileSystem: noop,
    isolatedFileSystem: () => null,
    connectAutomaticFileSystem: (_path, _id, _add, callback) => later(callback, { success: false }),
    disconnectAutomaticFileSystem: noop,
    upgradeDraggedFileSystemPermissions: noop,
    indexPath: noop,
    stopIndexing: noop,
    searchInPath: noop,
    zoomFactor: () => 1,
    zoomIn: noop,
    zoomOut: noop,
    resetZoom: noop,
    setWhitelistedShortcuts: noop,
    setEyeDropperActive: noop,
    showCertificateViewer: noop,
    reattach: (callback) => callback?.(),
    readyForTest: noop,
    setOpenNewWindowForPopups: noop,
    setDevicesDiscoveryConfig: noop,
    setDevicesUpdatesEnabled: noop,
    openRemotePage: noop,
    openNodeFrontend: noop,
    setAddExtensionCallback: noop,
    initialTargetId: async () => null,
    showSurvey: (_trigger, callback) => later(callback, { surveyShown: false }),
    canShowSurvey: (_trigger, callback) => later(callback, { canShowSurvey: false }),
    doAidaConversation: (_request, _streamId, callback) => callback(notImplemented),
    registerAidaClientEvent: (_request, callback) => callback(notImplemented),
    aidaCodeComplete: (_request, callback) => callback(notImplemented),
    dispatchHttpRequest: (_request, callback) => callback(notImplemented),
    setChromeFlag: noop,
    requestRestart: noop,
  };

  // Metrics and usage logging: Chrome reports them to Google; Redent keeps none.
  for (const name of [
    "recordCountHistogram", "recordEnumeratedHistogram", "recordPerformanceHistogram",
    "recordPerformanceHistogramMedium", "recordUserMetricsAction", "recordNewBadgeUsage",
    "recordImpression", "recordResize", "recordClick", "recordHover", "recordDrag",
    "recordChange", "recordKeyDown", "recordSettingAccess", "recordFunctionCall",
  ]) host[name] = noop;

  // First run: the Console, in English. Only English ships with Redent, and
  // the Elements panel Chrome would open first has no WebKit counterpart.
  // A response or source ends where its text does, not a panel's height later.
  for (const [name, value] of [
    ["panel-selected-tab", "console"], ["language", "en-US"], ["disable-locale-info-bar", true],
    ["currentDockState", "bottom"], ["allow-scroll-past-eof", false],
  ]) {
    if (localStorage.getItem(name) === null) localStorage.setItem(name, JSON.stringify(value));
  }

  globalThis.InspectorFrontendHost = host;
})();
