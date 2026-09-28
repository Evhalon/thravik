// WebKit CSS values → Chrome's. WebKit names an editable style or rule by an
// id; Chrome names it by its style sheet and source range. Every translated
// style and rule records its id under that range, so an edit Chrome sends
// back finds the WebKit id it means.

export type CSSIds = { styles: Map<string, any>; rules: Map<string, any>; groupings: Map<string, any> };

export function rangeKey(styleSheetId: string | undefined, range: any): string {
  return `${styleSheetId}|${range?.startLine}|${range?.startColumn}`;
}

const ORIGINS: Record<string, string> = { "user-agent": "user-agent", inspector: "inspector", user: "regular", author: "regular" };

export function origin(o: string | undefined): string {
  return ORIGINS[o ?? ""] ?? "regular";
}

export function style(ids: CSSIds, st: any): any {
  if (!st) return st;
  const sheet = st.styleId?.styleSheetId;
  const out: any = {
    cssProperties: (st.cssProperties ?? []).map((p: any) => ({
      name: p.name,
      value: p.value,
      important: p.priority === "important",
      implicit: !!p.implicit,
      ...(p.text !== undefined ? { text: p.text } : {}),
      parsedOk: p.parsedOk ?? true,
      disabled: p.status === "disabled",
      ...(p.range ? { range: p.range } : {}),
    })),
    shorthandEntries: (st.shorthandEntries ?? []).map((e: any) => ({ name: e.name, value: e.value, important: e.priority === "important" })),
  };
  if (sheet && st.range) {
    out.styleSheetId = sheet;
    out.range = st.range;
    ids.styles.set(rangeKey(sheet, st.range), st.styleId);
  }
  if (st.cssText !== undefined) out.cssText = st.cssText;
  return out;
}

export function rule(ids: CSSIds, r: any): any {
  const sheet = r.ruleId?.styleSheetId;
  const out: any = {
    selectorList: selectorList(r.selectorList),
    origin: origin(r.origin),
    style: style(ids, r.style),
  };
  if (sheet) {
    out.styleSheetId = sheet;
    if (r.selectorList?.range) ids.rules.set(rangeKey(sheet, r.selectorList.range), r.ruleId);
  }
  Object.assign(out, groupings(ids, r.groupings ?? [], sheet));
  return out;
}

export function ruleMatch(ids: CSSIds, m: any): any {
  return { rule: rule(ids, m.rule), matchingSelectors: m.matchingSelectors ?? [] };
}

/** Each selector gets its own range when the list sits on one line, which
 *  is what lets Chrome edit a selector in place. */
export function selectorList(list: any): any {
  const selectors: any[] = (list?.selectors ?? []).map((sel: any) => ({
    text: sel.text,
    ...(Array.isArray(sel.specificity) ? { specificity: { a: sel.specificity[0], b: sel.specificity[1], c: sel.specificity[2] } } : {}),
  }));
  const range = list?.range;
  if (range && range.startLine === range.endLine && typeof list.text === "string") {
    let column = range.startColumn;
    const parts = list.text.split(",");
    parts.forEach((part: string, index: number) => {
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

const MEDIA_SOURCES: Record<string, string> = {
  "media-rule": "mediaRule", "media-import-rule": "importRule", "media-link-node": "linkedSheet", "media-style-node": "inlineSheet",
};

/** WebKit lists a rule's @media, @supports, @layer … as one grouping list,
 *  innermost first; Chrome keeps one list per kind, in the same order. */
function groupings(ids: CSSIds, list: any[], sheet: string | undefined): any {
  const out: any = {};
  const push = (key: string, value: any) => { (out[key] ??= []).push(value); };
  for (const g of list) {
    const located: any = { text: g.text ?? "" };
    if (g.range && sheet) {
      located.range = g.range;
      located.styleSheetId = sheet;
      if (g.ruleId) ids.groupings.set(rangeKey(sheet, g.range), g.ruleId);
    }
    if (MEDIA_SOURCES[g.type]) push("media", { ...located, source: MEDIA_SOURCES[g.type], ...(g.sourceURL ? { sourceURL: g.sourceURL } : {}) });
    else if (g.type === "supports-rule") push("supports", { ...located, active: true });
    else if (g.type === "container-rule") push("containerQueries", located);
    else if (g.type === "layer-rule" || g.type === "layer-import-rule") push("layers", located);
    else if (g.type === "scope-rule") push("scopes", located);
    else if (g.type === "starting-style-rule") push("startingStyles", located);
    else if (g.type === "style-rule") push("nestingSelectors", g.text ?? "");
  }
  return out;
}

export function header(h: any): any {
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
    endColumn: h.startColumn ?? 0,
  };
}
