// Overlay: the element picker, the highlight over a hovered node, and the
// grid and flex badges. WebKit draws the same things from its DOM domain.

import type { Session } from "./session";
import { nodeIdOf } from "./dom";

/** Chrome's highlight colours → the four boxes WebKit draws. */
function highlight(c: any = {}): any {
  const out: any = { showInfo: !!c.showInfo };
  for (const key of ["contentColor", "paddingColor", "borderColor", "marginColor"]) {
    if (c[key]) out[key] = c[key];
  }
  return out;
}

function grid(c: any = {}): any {
  return {
    gridColor: c.gridBorderColor ?? c.cellBorderColor ?? c.rowLineColor ?? { r: 147, g: 112, b: 219, a: 1 },
    showLineNames: !!c.showLineNames,
    showLineNumbers: !!(c.showPositiveLineNumbers || c.showNegativeLineNumbers),
    showExtendedGridLines: !!c.showGridExtensionLines,
    showTrackSizes: !!c.showTrackSizes,
    showAreaNames: !!c.showAreaNames,
  };
}

function flex(c: any = {}): any {
  return {
    flexColor: c.containerBorder?.color ?? c.lineSeparator?.color ?? { r: 147, g: 112, b: 219, a: 1 },
    showOrderNumbers: false,
  };
}

export function installOverlay(s: Session) {
  s.handle("Overlay.enable", () => ({}));
  s.handle("Overlay.disable", () => s.call("DOM.hideHighlight").catch(() => ({})));
  s.handle("Overlay.setInspectMode", (p) => s.call("DOM.setInspectModeEnabled", {
    enabled: p.mode !== "none" && p.mode !== undefined,
    highlightConfig: highlight(p.highlightConfig),
    showRulers: !!p.highlightConfig?.showRulers,
  }));
  s.handle("Overlay.highlightNode", async (p) => {
    const config = highlight(p.highlightConfig);
    if (p.selector) return s.call("DOM.highlightSelector", { selectorString: p.selector, highlightConfig: config });
    if (p.objectId) return s.call("DOM.highlightNode", { objectId: p.objectId, highlightConfig: config });
    return s.call("DOM.highlightNode", { nodeId: await nodeIdOf(s, p), highlightConfig: config });
  });
  s.handle("Overlay.hideHighlight", () => s.call("DOM.hideHighlight"));
  s.handle("Overlay.highlightRect", (p) => s.call("DOM.highlightRect", {
    x: p.x, y: p.y, width: p.width, height: p.height, color: p.color, outlineColor: p.outlineColor,
  }));
  s.handle("Overlay.highlightQuad", (p) => s.call("DOM.highlightQuad", { quad: p.quad, color: p.color, outlineColor: p.outlineColor }));
  s.handle("Overlay.highlightFrame", (p) => s.call("DOM.highlightFrame", {
    frameId: p.frameId, contentColor: p.contentColor, contentOutlineColor: p.contentOutlineColor,
  }));
  s.handle("Overlay.setShowPaintRects", (p) => s.call("Page.setShowPaintRects", { result: !!p.result }));
  installLayoutOverlays(s);
}

// Chrome restates the whole set of grids or flex containers every time one
// is toggled; WebKit adds and removes them one node at a time.
function installLayoutOverlays(s: Session) {
  const shown = { grid: new Set<number>(), flex: new Set<number>() };
  const sync = async (kind: "grid" | "flex", configs: any[]) => {
    const wanted = new Map<number, any>(configs.map((c) => [c.nodeId, c]));
    const [show, hide] = kind === "grid" ? ["DOM.showGridOverlay", "DOM.hideGridOverlay"] : ["DOM.showFlexOverlay", "DOM.hideFlexOverlay"];
    for (const id of shown[kind]) {
      if (!wanted.has(id)) await s.call(hide, { nodeId: id }).catch(() => {});
    }
    shown[kind] = new Set(wanted.keys());
    for (const [nodeId, c] of wanted) {
      const params = kind === "grid"
        ? { nodeId, gridOverlayConfig: grid(c.gridHighlightConfig) }
        : { nodeId, flexOverlayConfig: flex(c.flexContainerHighlightConfig) };
      await s.call(show, params).catch(() => {});
    }
    return {};
  };
  s.handle("Overlay.setShowGridOverlays", (p) => sync("grid", p.gridNodeHighlightConfigs ?? []));
  s.handle("Overlay.setShowFlexOverlays", (p) => sync("flex", p.flexNodeHighlightConfigs ?? []));
}
