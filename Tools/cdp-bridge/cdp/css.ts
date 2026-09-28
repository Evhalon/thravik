// CSS: the Styles, Computed and Fonts panes, and editing them. WebKit's CSS
// domain carries the same rules and properties under older names.

import type { Session } from "./session";
import { ProtocolError } from "./session";
import { replay } from "./replay";
import { onNode } from "./dom";
import { type CSSIds, header, rangeKey, ruleMatch, selectorList, style } from "./css-values";

export function installCSS(s: Session) {
  const ids: CSSIds = { styles: new Map(), rules: new Map(), groupings: new Map() };
  s.handle("CSS.enable", () => replay(s, "CSS"));
  s.handle("CSS.disable", () => ({}));
  s.handle("CSS.getMatchedStylesForNode", async (p) => {
    const [matched, inline] = await Promise.all([
      s.call("CSS.getMatchedStylesForNode", { nodeId: p.nodeId, includePseudo: true, includeInherited: true }),
      s.call("CSS.getInlineStylesForNode", { nodeId: p.nodeId }),
    ]);
    return {
      ...(inline.inlineStyle ? { inlineStyle: style(ids, inline.inlineStyle) } : {}),
      ...(inline.attributesStyle ? { attributesStyle: style(ids, inline.attributesStyle) } : {}),
      matchedCSSRules: (matched.matchedCSSRules ?? []).map((m: any) => ruleMatch(ids, m)),
      pseudoElements: (matched.pseudoElements ?? []).map((e: any) => ({
        pseudoType: e.pseudoId, matches: (e.matches ?? []).map((m: any) => ruleMatch(ids, m)),
      })),
      inherited: (matched.inherited ?? []).map((e: any) => ({
        ...(e.inlineStyle ? { inlineStyle: style(ids, e.inlineStyle) } : {}),
        matchedCSSRules: (e.matchedCSSRules ?? []).map((m: any) => ruleMatch(ids, m)),
      })),
    };
  });
  s.handle("CSS.getInlineStylesForNode", async (p) => {
    const r = await s.call("CSS.getInlineStylesForNode", { nodeId: p.nodeId });
    return {
      ...(r.inlineStyle ? { inlineStyle: style(ids, r.inlineStyle) } : {}),
      ...(r.attributesStyle ? { attributesStyle: style(ids, r.attributesStyle) } : {}),
    };
  });
  s.handle("CSS.getComputedStyleForNode", async (p) => ({
    computedStyle: ((await s.call("CSS.getComputedStyleForNode", { nodeId: p.nodeId })).computedStyle ?? [])
      .map((c: any) => ({ name: c.name, value: c.value })),
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
  installEvents(s);
}

function installEditing(s: Session, ids: CSSIds) {
  const find = (map: Map<string, any>, sheet: string, range: any, what: string) => {
    const id = map.get(rangeKey(sheet, range));
    if (!id) throw new ProtocolError(`This ${what} can no longer be edited; select the element again`);
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

function installEvents(s: Session) {
  s.on("CSS.styleSheetAdded", (p) => s.emit("CSS.styleSheetAdded", { header: header(p.header) }));
  s.on("CSS.styleSheetRemoved", (p) => s.emit("CSS.styleSheetRemoved", { styleSheetId: p.styleSheetId }));
  s.on("CSS.styleSheetChanged", (p) => s.emit("CSS.styleSheetChanged", { styleSheetId: p.styleSheetId }));
  s.on("CSS.mediaQueryResultChanged", () => s.emit("CSS.mediaQueryResultChanged", {}));
}
