// Chrome's "Inspect" from the page's context menu. Redent finds the node under
// the pointer as a path of child indices, taken before DevTools opened and
// the page shrank beneath it; Chrome reveals it the way it reveals inspect().

import type { Session } from "./session";
import { remoteObject } from "./values";

/** Follows the path from `<html>`; -1 steps into an open shadow root. */
const RESOLVE = `function (path) {
  let node = document.documentElement;
  for (const step of path) {
    node = step < 0 ? node.shadowRoot : node.children[step];
    if (!node) return null;
  }
  return node;
}`;

export function inspectPath(s: Session, path: number[]) {
  if (!Array.isArray(path) || !path.every(Number.isInteger)) return;
  s.afterEnabled("Runtime", async () => {
    const r = await s.call("Runtime.evaluate", {
      expression: `(${RESOLVE})(${JSON.stringify(path)})`,
      objectGroup: "redent-inspected", generatePreview: true, contextId: s.state.mainContextId || undefined,
    }).catch(() => null);
    if (!r?.result?.objectId) return;
    s.emit("Runtime.inspectRequested", {
      object: remoteObject(r.result), hints: {}, executionContextId: s.state.mainContextId || 1,
    });
  });
}
