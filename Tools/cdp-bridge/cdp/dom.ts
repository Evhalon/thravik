// DOM: the Elements tree, node editing, search, and the node handles the
// Console draws a logged element with.
//
// WebKit's DOM domain is Chrome's older sibling: same node ids, same events,
// same edits. Chrome also names nodes by a `backendNodeId` that outlives the
// frontend's ids; WebKit has only the one id, so it serves as both.

import type { Session } from "./session";
import { ProtocolError } from "./session";
import { remoteObject } from "./values";

/** WebKit DOM.Node → CDP DOM.Node, remembered for `describeNode`. */
export function domNode(s: Session, n: any): any {
  if (!n) return n;
  const out: any = {
    nodeId: n.nodeId,
    backendNodeId: n.nodeId,
    nodeType: n.nodeType,
    nodeName: n.nodeName,
    localName: n.localName ?? "",
    nodeValue: n.nodeValue ?? "",
  };
  for (const key of ["childNodeCount", "attributes", "documentURL", "baseURL", "publicId", "systemId", "xmlVersion", "frameId", "pseudoType", "shadowRootType"]) {
    if (n[key] !== undefined) out[key] = n[key];
  }
  if (n.children) out.children = n.children.map((c: any) => domNode(s, c));
  if (n.contentDocument) out.contentDocument = domNode(s, n.contentDocument);
  if (n.templateContent) out.templateContent = domNode(s, n.templateContent);
  if (n.shadowRoots) out.shadowRoots = n.shadowRoots.map((c: any) => domNode(s, c));
  if (n.pseudoElements) out.pseudoElements = n.pseudoElements.map((c: any) => domNode(s, c));
  if (n.localName === "svg" || n.attributes?.includes("http://www.w3.org/2000/svg")) out.isSVG = true;
  const { children, contentDocument, templateContent, shadowRoots, pseudoElements, ...shallow } = out;
  s.state.nodes.set(n.nodeId, shallow);
  return out;
}

/** The WebKit node id a CDP command names, by any of the three handles. */
export async function nodeIdOf(s: Session, p: any): Promise<number> {
  const id = p.nodeId || p.backendNodeId;
  if (id) return id;
  if (p.objectId) return (await s.call("DOM.requestNode", { objectId: p.objectId })).nodeId;
  throw new ProtocolError("No node with given id found");
}

/** Runs `fn` on the page's node, with its value back by value. */
export async function onNode(s: Session, p: any, fn: string, args: any[] = []): Promise<any> {
  const objectId = p.objectId ?? (await s.call("DOM.resolveNode", { nodeId: await nodeIdOf(s, p), objectGroup: "redent-dom" })).object?.objectId;
  const r = await s.call("Runtime.callFunctionOn", {
    objectId, functionDeclaration: fn, arguments: args.map((value) => ({ value })), returnByValue: true,
  });
  if (!p.objectId) s.call("Runtime.releaseObjectGroup", { objectGroup: "redent-dom" }).catch(() => {});
  if (r.wasThrown) throw new ProtocolError(r.result?.description ?? "Could not compute");
  return r.result?.value;
}

const FORWARDED = [
  "setNodeName", "setNodeValue", "removeNode", "setAttributeValue", "setAttributesAsText", "removeAttribute",
  "setOuterHTML", "moveTo", "undo", "redo", "markUndoableState", "focus", "setInspectedNode",
  "getAttributes", "querySelector", "querySelectorAll", "getSearchResults", "discardSearchResults",
  "requestNode", "pushNodeByPathToFrontend",
];

export function installDOM(s: Session) {
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
      if (params.backendNodeId && !params.nodeId) params.nodeId = params.backendNodeId;
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
    if (!node) throw new ProtocolError("No node with given id found");
    return { node };
  });
  s.handle("DOM.pushNodesByBackendIdsToFrontend", (p) => ({
    nodeIds: (p.backendNodeIds ?? []).map((id: number) => (s.state.nodes.has(id) ? id : 0)),
  }));
  s.handle("DOM.getTopLayerElements", () => ({ nodeIds: [] }));
  s.handle("DOM.getQueryingDescendantsForContainer", () => ({ nodeIds: [] }));
  installGeometry(s);
  installEvents(s);
}

const BOX_MODEL = `function () {
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

function installGeometry(s: Session) {
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
    }`),
  }));
  s.handle("DOM.getNodeForLocation", async (p) => {
    const r = await s.call("Runtime.evaluate", {
      expression: `document.elementFromPoint(${Number(p.x)}, ${Number(p.y)})`, objectGroup: "redent-dom",
      contextId: s.state.mainContextId || undefined,
    });
    if (!r.result?.objectId) throw new ProtocolError("No node found at given location");
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
      arguments: [{ objectId: target.object.objectId }, before ? { objectId: before.object.objectId } : { value: null }],
    });
    return { nodeId: (await s.call("DOM.requestNode", { objectId: r.result.objectId })).nodeId };
  });
}

function installEvents(s: Session) {
  s.on("DOM.documentUpdated", () => {
    s.state.nodes.clear();
    s.emit("DOM.documentUpdated", {});
  });
  s.on("DOM.setChildNodes", (p) => s.emit("DOM.setChildNodes", { parentId: p.parentId, nodes: (p.nodes ?? []).map((n: any) => domNode(s, n)) }));
  s.on("DOM.childNodeInserted", (p) => s.emit("DOM.childNodeInserted", { ...p, node: domNode(s, p.node) }));
  s.on("DOM.shadowRootPushed", (p) => s.emit("DOM.shadowRootPushed", { hostId: p.hostId, root: domNode(s, p.root) }));
  s.on("DOM.pseudoElementAdded", (p) => s.emit("DOM.pseudoElementAdded", { parentId: p.parentId, pseudoElement: domNode(s, p.pseudoElement) }));
  s.on("DOM.childNodeRemoved", (p) => {
    s.state.nodes.delete(p.nodeId);
    s.emit("DOM.childNodeRemoved", p);
  });
  s.on("DOM.attributeModified", (p) => {
    const node = s.state.nodes.get(p.nodeId);
    if (node?.attributes) node.attributes = withAttribute(node.attributes, p.name, p.value);
    s.emit("DOM.attributeModified", p);
  });
  s.on("DOM.attributeRemoved", (p) => {
    const node = s.state.nodes.get(p.nodeId);
    if (node?.attributes) node.attributes = withAttribute(node.attributes, p.name, null);
    s.emit("DOM.attributeRemoved", p);
  });
  for (const event of ["characterDataModified", "childNodeCountUpdated", "shadowRootPopped", "pseudoElementRemoved", "inlineStyleInvalidated"]) {
    s.on(`DOM.${event}`, (p) => s.emit(`DOM.${event}`, p));
  }
  // The element picker's choice. Chrome asks for it through the Overlay.
  s.on("DOM.inspect", (p) => s.emit("Overlay.inspectNodeRequested", { backendNodeId: p.nodeId }));
}

function withAttribute(attributes: string[], name: string, value: string | null): string[] {
  const out: string[] = [];
  let found = false;
  for (let i = 0; i < attributes.length; i += 2) {
    if (attributes[i] !== name) {
      out.push(attributes[i], attributes[i + 1]);
    } else {
      found = true;
      if (value !== null) out.push(name, value);
    }
  }
  if (!found && value !== null) out.push(name, value);
  return out;
}
