var Zt=Object.defineProperty;var l=(o,e)=>{for(var t in e)Zt(o,t,{get:e[t],enumerable:!0})};var We={};l(We,{AccessibilityTreeNode:()=>W});import*as ye from"./../../../core/i18n/i18n.js";import*as Be from"./../../../core/platform/platform.js";import*as Fe from"./../../../core/sdk/sdk.js";import*as qe from"./../../../ui/components/render_coordinator/render_coordinator.js";import*as Re from"./../../../ui/legacy/legacy.js";import{html as D,nothing as eo,render as to}from"./../../../ui/lit/lit.js";var He=`.container{width:100%;display:inline-block}.container:hover{background-color:var(--sys-color-state-hover-on-subtle)}span{color:var(--sys-color-token-meta);font-family:var(--monospace-font-family);font-size:var(--monospace-font-size)}.role-value{color:var(--sys-color-token-tag)}.attribute-name{color:var(--sys-color-token-attribute)}.attribute-value{color:var(--sys-color-token-attribute-value)}
/*# sourceURL=${import.meta.resolve("./accessibilityTreeNode.css")} */`;var _e={ignored:"Ignored"},oo=ye.i18n.registerUIStrings("panels/elements/components/AccessibilityTreeNode.ts",_e),so=ye.i18n.getLocalizedString.bind(void 0,oo);function no(o){return o.length>1e4?Be.StringUtilities.trimMiddle(o,1e4):o}var W=class extends HTMLElement{#t=Re.UIUtils.createShadowRootWithCoreStyles(this,{cssFile:He});#e=!0;#o="";#n="";#s=[];#r="";set data(e){this.#e=e.ignored,this.#o=e.name,this.#n=e.role,this.#s=e.properties,this.#r=e.id,this.#i()}async#i(){let e=D`<span class='role-value'>${no(this.#n)}</span>`,t=D`"<span class='attribute-value'>${this.#o}</span>"`,s=this.#s.map(({name:r,value:i})=>Fe.AccessibilityModel.isPrintableType(i.type)?D` <span class='attribute-name'>${r}</span>:&nbsp;<span class='attribute-value'>${i.value}</span>`:eo),n=this.#e?D`<span>${so(_e.ignored)}</span>`:D`${e}&nbsp;${t}${s}`;await qe.write(`Accessibility node ${this.#r} render`,()=>{to(D`<div class='container'>${n}</div>`,this.#t,{host:this})})}};customElements.define("devtools-accessibility-tree-node",W);var Ke={};l(Ke,{AdornerManager:()=>be,RegisteredAdorners:()=>F});var F;(function(o){o.AD="ad",o.CONTAINER="container",o.CUSTOM_ELEMENT="custom-element",o.FLEX="flex",o.GRID="grid",o.GRID_LANES="grid-lanes",o.INTEREST="interest",o.MEDIA="media",o.POPOVER="popover",o.REVEAL="reveal",o.SCROLL="scroll",o.SCROLL_SNAP="scroll-snap",o.SLOT="slot",o.VIEW_SOURCE="view-source",o.STARTING_STYLE="starting-style",o.SUBGRID="subgrid",o.TOP_LAYER="top-layer"})(F||(F={}));var be=class{#t=new Map;#e;constructor(e){this.#e=e,this.#s()}updateSettings(e){this.#t=e,this.#o()}getSettings(){return this.#t}isAdornerEnabled(e){return this.#t.get(e)||!1}#o(){let e=[];for(let[t,s]of this.#t)e.push({adorner:t,isEnabled:s});this.#e.set(e)}#n(){let e=this.#e.get();for(let t of e)this.#t.set(t.adorner,t.isEnabled)}#s(){this.#n();let e=new Set(this.#t.keys());for(let t of Object.values(F))if(e.delete(t),!this.#t.has(t)){let s=t!==F.MEDIA;this.#t.set(t,s)}for(let t of e)this.#t.delete(t);this.#o()}};var Qe={};l(Qe,{ComputedStyleProperty:()=>Y,NavigateToSourceEvent:()=>K});import{html as Ge,render as ro}from"./../../../ui/lit/lit.js";import*as Xe from"./../../../ui/visual_logging/visual_logging.js";var Ye=`:host{position:relative;overflow:hidden;flex:auto;text-overflow:ellipsis}.computed-style-property{--goto-size:16px;font-family:var(--monospace-font-family);font-size:var(--monospace-font-size);min-height:16px;box-sizing:border-box;padding-top:2px;white-space:var(--override-computed-style-property-white-space,nowrap);user-select:text}.computed-style-property:hover{background-color:var(--sys-color-state-hover-on-subtle);cursor:text}.computed-style-property.inherited{opacity:75%;font-style:italic}.property-name,
.property-value{display:contents;overflow:hidden;text-overflow:ellipsis}.property-name{width:16em;max-width:52%;margin-right:calc(var(--goto-size) / 2);display:inline-block;vertical-align:text-top;color:var(--webkit-css-property-color,var(--sys-color-token-property-special))}.property-value{margin-left:2em}.goto{display:none;cursor:pointer;position:absolute;width:var(--goto-size);height:var(--goto-size);margin:-1px 0 0 calc(-1 * var(--goto-size));mask:var(--image-file-goto-filled) center /contain no-repeat;background-color:var(--sys-color-primary-bright)}.computed-style-property:hover .goto{display:inline-block}.hidden{display:none}:host-context(.computed-narrow) .computed-style-property{white-space:normal;& .goto{display:none;margin-left:0}}:host-context(.computed-narrow) .property-name,
:host-context(.computed-narrow) .property-value{display:inline-block;width:100%;max-width:100%;margin-left:0;white-space:nowrap}:host-context(.computed-narrow) .computed-style-property:not(.inherited):hover{& .property-value{margin-left:var(--goto-size)}& .goto{display:inline-block}}@media (forced-colors: active){.computed-style-property.inherited{opacity:100%}.computed-style-property:hover{forced-color-adjust:none;background-color:Highlight}.computed-style-property:hover *{color:HighlightText}.goto{background-color:HighlightText}}
/*# sourceURL=${import.meta.resolve("./computedStyleProperty.css")} */`;var K=class o extends Event{static eventName="onnavigatetosource";constructor(){super(o.eventName,{bubbles:!0,composed:!0})}},Y=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e=!1;#o=!1;connectedCallback(){this.#s()}set inherited(e){e!==this.#e&&(this.#e=e,this.#s())}set traceable(e){e!==this.#o&&(this.#o=e,this.#s())}#n(){this.dispatchEvent(new K)}#s(){ro(Ge`
      <style>${Ye}</style>
      <div class="computed-style-property ${this.#e?"inherited":""}">
        <div class="property-name">
          <slot name="name"></slot>
        </div>
        <span class="hidden" aria-hidden="false">: </span>
        ${this.#o?Ge`<span class="goto" @click=${this.#n} jslog=${Xe.action("elements.jump-to-style").track({click:!0})}></span>`:null}
        <div class="property-value">
          <slot name="value"></slot>
        </div>
        <span class="hidden" aria-hidden="false">;</span>
      </div>
    `,this.#t,{host:this})}};customElements.define("devtools-computed-style-property",Y);var tt={};l(tt,{ComputedStyleTrace:()=>G});import*as Ze from"./../../../ui/components/buttons/buttons.js";import*as et from"./../../../ui/legacy/legacy.js";import{html as io,render as ao}from"./../../../ui/lit/lit.js";var Je=`:host{text-overflow:ellipsis;overflow:hidden;flex-grow:1}.computed-style-trace{margin-left:16px;font-family:var(--monospace-font-family);font-size:var(--monospace-font-size)}.computed-style-trace:hover{background-color:var(--sys-color-state-hover-on-subtle);cursor:text}.goto{--size:16px;display:none;cursor:pointer;position:absolute;width:var(--size);height:var(--size);margin:-1px 0 0 calc(-1 * var(--size));mask:var(--image-file-goto-filled) center /contain no-repeat;background-color:var(--sys-color-primary-bright)}.computed-style-trace:hover .goto{display:inline-block}.devtools-link{color:var(--sys-color-on-surface);text-decoration-color:var(--sys-color-token-subtle);text-decoration-line:underline;cursor:pointer}.trace-value{margin-left:16px}.computed-style-trace.inactive slot[name="trace-value"]{text-decoration:line-through}.trace-selector{--override-trace-selector-color:var(--sys-color-token-subtle);color:var(--override-trace-selector-color);padding-left:2em}.trace-link{user-select:none;float:right;padding-left:1em;position:relative;z-index:1}@media (forced-colors: active){.computed-style-trace:hover{forced-color-adjust:none;background-color:Highlight}.goto{background-color:Highlight}.computed-style-trace:hover *{color:HighlightText}.computed-style-trace:hover .trace-selector{--override-trace-selector-color:HighlightText}}
/*# sourceURL=${import.meta.resolve("./computedStyleTrace.css")} */`;var G=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e="";#o=!1;#n=()=>{};#s;connectedCallback(){this.#r()}set data(e){this.#e=e.selector,this.#o=e.active,this.#n=e.onNavigateToSource,this.#s=e.ruleOriginNode,this.#r()}#r(){ao(io`
      <style>${Ze.textButtonStyles}</style>
      <style>${et.inspectorCommonStyles}</style>
      <style>${Je}</style>
      <div class="computed-style-trace ${this.#o?"active":"inactive"}">
        <span class="goto" @click=${this.#n}></span>
        <slot name="trace-value" @click=${this.#n}></slot>
        <span class="trace-selector">${this.#e}</span>
        <span class="trace-link">${this.#s}</span>
      </div>
    `,this.#t,{host:this})}};customElements.define("devtools-computed-style-trace",G);var nt={};l(nt,{CSSHintDetailsView:()=>X});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/legacy.js";import*as we from"./../../../core/i18n/i18n.js";import{html as xe,render as lo}from"./../../../ui/lit/lit.js";var ot=`.hint-popup-wrapper{max-width:232px}code{font-weight:bold;font-family:inherit}.hint-popup-possible-fix{margin-top:8px}.clickable{color:var(--sys-color-primary)}.underlined{text-decoration:underline}.unbreakable-text{white-space:nowrap}.footer{margin-top:var(--sys-size-5)}
/*# sourceURL=${import.meta.resolve("./cssHintDetailsView.css")} */`;var st={learnMore:"Learn More"},co=we.i18n.registerUIStrings("panels/elements/components/CSSHintDetailsView.ts",st),po=we.i18n.getLocalizedString.bind(void 0,co),X=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e;constructor(e){super(),this.#e=e,this.#o()}#o(){let e=this.#e.getLearnMoreLink();lo(xe`
        <style>${ot}</style>
        <div class="hint-popup-wrapper">
          <div class="hint-popup-reason">
            ${this.#e.getMessage()}
          </div>
          ${this.#e.getPossibleFixMessage()?xe`
              <div class="hint-popup-possible-fix">
                  ${this.#e.getPossibleFixMessage()}
              </div>
          `:""}
          ${e?xe`
                      <div class="footer">
                        <devtools-link id="learn-more" href=${e} class="clickable underlined unbreakable-text">
                            ${po(st.learnMore)}
                        </devtools-link>
                      </div>
                  `:""}
        </div>
      `,this.#t,{host:this})}};customElements.define("devtools-css-hint-details-view",X);var ct={};l(ct,{CSSPropertyDocsView:()=>J});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/legacy.js";import*as at from"./../../../core/common/common.js";import*as M from"./../../../core/i18n/i18n.js";import{html as Q,nothing as Se,render as uo}from"./../../../ui/lit/lit.js";import*as lt from"./../../../ui/visual_logging/visual_logging.js";var rt=`.docs-popup-wrapper{max-width:420px;font-size:12px;line-height:1.4}.docs-popup-section{margin-top:8px}.clickable{color:var(--sys-color-primary)}.underlined{text-decoration:underline}.unbreakable-text{white-space:nowrap}.footer{display:flex;justify-content:space-between}#baseline{display:inline-flex;align-items:flex-start;gap:4px}#baseline-icon{width:18px;height:18px}
/*# sourceURL=${import.meta.resolve("./cssPropertyDocsView.css")} */`;var f={learnMore:"Learn more",dontShow:"Don\u2019t show",limitedAvailability:"Limited availability across major browsers",limitedAvailabilityInBrowsers:"Limited availability across major browsers (not fully implemented in {PH1})",browserOnPlatform:"{PH1} on {PH2}",newlyAvailableSince:"Newly available across major browsers (`Baseline` since {PH1})",widelyAvailableSince:"Widely available across major browsers (`Baseline` since {PH1})",unknownDate:"an unknown date"},mo=M.i18n.registerUIStrings("panels/elements/components/CSSPropertyDocsView.ts",f),y=M.i18n.getLocalizedString.bind(void 0,mo),ho="../../../Images/baseline-high-availability.svg",fo="../../../Images/baseline-low-availability.svg",go="../../../Images/baseline-limited-availability.svg",vo=o=>{let e;switch(o.status){case"high":e=ho;break;case"low":e=fo;break;default:e=go}return new URL(e,import.meta.url).toString()},yo=new Set(["C","CA","E","FF","FFA","S","SM"]),bo=new Map([["C",{name:"Chrome",platform:"desktop"}],["CA",{name:"Chrome",platform:"Android"}],["E",{name:"Edge",platform:"desktop"}],["FF",{name:"Firefox",platform:"desktop"}],["FFA",{name:"Firefox",platform:"Android"}],["S",{name:"Safari",platform:"macOS"}],["SM",{name:"Safari",platform:"iOS"}]]);function xo(o){return new Intl.ListFormat(M.DevToolsLocale.DevToolsLocale.instance().locale,{style:"long",type:"disjunction"}).format(o.entries().map(([t,s])=>s.length!==1||s[0]==="desktop"?t:y(f.browserOnPlatform,{PH1:t,PH2:s[0]})))}var it=o=>{if(!o)return y(f.unknownDate);let e=new Date(o);return new Intl.DateTimeFormat(M.DevToolsLocale.DevToolsLocale.instance().locale,{month:"long",year:"numeric"}).format(e)},wo=o=>{let e=o.map(n=>n.replace(/\d*$/,"")),t=yo.difference(new Set(e)),s=new Map;for(let n of t){let r=bo.get(n);if(r){let{name:i,platform:a}=r;s.set(i,[...s.get(i)??[],a])}}return s},So=(o,e)=>{if(o.status==="false"){let t=e&&wo(e);return t?y(f.limitedAvailabilityInBrowsers,{PH1:xo(t)}):y(f.limitedAvailability)}return o.status==="low"?y(f.newlyAvailableSince,{PH1:it(o.baseline_low_date)}):y(f.widelyAvailableSince,{PH1:it(o.baseline_high_date)})},J=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e;constructor(e){super(),this.#e=e,this.#n()}#o(e){let t=!e.target.checked;at.Settings.Settings.instance().moduleSetting("show-css-property-documentation-on-hover").set(t)}#n(){let{description:e,references:t,baseline:s,browsers:n}=this.#e,r=t?.[0].url;uo(Q`
      <style>${rt}</style>
      <div class="docs-popup-wrapper">
        ${e?Q`
          <div id="description">
            ${e}
          </div>
        `:Se}
        ${s?Q`
          <div id="baseline" class="docs-popup-section">
            <img
              id="baseline-icon"
              src=${vo(s)}
              role="presentation"
            >
            <span>
              ${So(s,n)}
            </span>
          </div>
        `:Se}
        ${r?Q`
          <div class="docs-popup-section footer">
            <devtools-link
              id="learn-more"
              href=${r}
              class="clickable underlined unbreakable-text"
            >
              ${y(f.learnMore)}
            </devtools-link>
            <devtools-checkbox
              @change=${this.#o}
              jslog=${lt.toggle("css-property-doc").track({change:!0})}>
              ${y(f.dontShow)}
            </devtools-checkbox>
          </div>
        `:Se}
      </div>
    `,this.#t,{host:this})}};customElements.define("devtools-css-property-docs-view",J);var wt={};l(wt,{findFlexContainerIcon:()=>ee,findFlexItemIcon:()=>bt,findGridContainerIcon:()=>q,findGridItemIcon:()=>xt,findIcon:()=>Eo,getPhysicalDirections:()=>p,reverseDirection:()=>ke,rotateAlignContentIcon:()=>$e,rotateAlignItemsIcon:()=>Le,rotateFlexDirectionIcon:()=>ft,rotateFlexWrapIcon:()=>yt,rotateGridDirectionIcon:()=>gt,rotateJustifyContentIcon:()=>Ie,rotateJustifyItemsIcon:()=>vt});var ko=new Set(["tb","tb-rl","vertical-lr","vertical-rl"]);function ke(o){if(o==="left-to-right")return"right-to-left";if(o==="right-to-left")return"left-to-right";if(o==="top-to-bottom")return"bottom-to-top";if(o==="bottom-to-top")return"top-to-bottom";throw new Error("Unknown PhysicalFlexDirection")}function dt(o){return{...o,"row-reverse":ke(o.row),"column-reverse":ke(o.column)}}function p(o){let e=o.get("direction")==="rtl",t=o.get("writing-mode");return t&&ko.has(t)?dt({row:e?"bottom-to-top":"top-to-bottom",column:t==="vertical-lr"?"left-to-right":"right-to-left"}):dt({row:e?"right-to-left":"left-to-right",column:"top-to-bottom"})}function ft(o){let e=!0,t=!1,s=-90;return o==="right-to-left"?(s=90,t=!1,e=!1):o==="top-to-bottom"?(s=0,e=!1,t=!1):o==="bottom-to-top"&&(s=0,e=!1,t=!0),{iconName:"flex-direction",rotate:s,scaleX:e?-1:1,scaleY:t?-1:1}}function gt(o){let e=!0,t=!1,s=-90;return o==="right-to-left"?(s=90,t=!1,e=!1):o==="top-to-bottom"?(s=0,e=!1,t=!1):o==="bottom-to-top"&&(s=0,e=!1,t=!0),{iconName:"grid-direction",rotate:s,scaleX:e?-1:1,scaleY:t?-1:1}}function $e(o,e){return{iconName:o,rotate:e==="right-to-left"?90:e==="left-to-right"?-90:0,scaleX:1,scaleY:1}}function Ie(o,e){return{iconName:o,rotate:e==="top-to-bottom"?90:e==="bottom-to-top"?-90:0,scaleX:e==="right-to-left"?-1:1,scaleY:1}}function vt(o,e){return{iconName:o,rotate:e==="top-to-bottom"?90:e==="bottom-to-top"?-90:0,scaleX:e==="right-to-left"?-1:1,scaleY:1}}function Le(o,e){return{iconName:o,rotate:e==="right-to-left"?90:e==="left-to-right"?-90:0,scaleX:1,scaleY:1}}function x(o){function e(t){let s=p(t);return ft(s[o])}return e}function pt(o){function e(t){let s=p(t);return gt(s[o])}return e}function c(o){function e(t){let s=p(t),n=new Map([["column",s.row],["row",s.column],["column-reverse",s.row],["row-reverse",s.column]]),r=t.get("flex-direction")||"row",i=n.get(r);if(!i)throw new Error("Unknown direction for flex-align icon");return $e(o,i)}return e}function w(o){function e(t){let s=p(t),r=(t.get("grid-auto-flow")||"row").includes("column")?s.row:s.column;return $e(o,r)}return e}function u(o){function e(t){let s=p(t);return Ie(o,s[t.get("flex-direction")||"row"])}return e}function g(o){function e(t){let s=p(t),r=(t.get("grid-auto-flow")||"row").includes("column")?s.column:s.row;return Ie(o,r)}return e}function b(o){function e(t){let s=p(t),r=(t.get("grid-auto-flow")||"row").includes("column")?s.column:s.row;return vt(o,r)}return e}function v(o){function e(t){let s=p(t),n=new Map([["column",s.row],["row",s.column],["column-reverse",s.row],["row-reverse",s.column]]),r=t.get("flex-direction")||"row",i=n.get(r);if(!i)throw new Error("Unknown direction for flex-align icon");return Le(o,i)}return e}function S(o){function e(t){let s=p(t),r=(t.get("grid-auto-flow")||"row").includes("column")?s.row:s.column;return Le(o,r)}return e}function k(){return{iconName:"align-items-baseline",rotate:0,scaleX:1,scaleY:1}}function Z(o){function e(t){return v(o)(t)}return e}function m(o){function e(t){return S(o)(t)}return e}function yt(o,e){return{iconName:o,rotate:e==="bottom-to-top"||e==="top-to-bottom"?90:0,scaleX:1,scaleY:1}}function ut(o){function e(t){let s=p(t),n=t.get("flex-direction")||"row";return yt(o,s[n])}return e}var $o=new Map([["flex-direction: row",x("row")],["flex-direction: column",x("column")],["flex-direction: column-reverse",x("column-reverse")],["flex-direction: row-reverse",x("row-reverse")],["flex-direction: initial",x("row")],["flex-direction: unset",x("row")],["flex-direction: revert",x("row")],["align-content: center",c("align-content-center")],["align-content: space-around",c("align-content-space-around")],["align-content: space-between",c("align-content-space-between")],["align-content: stretch",c("align-content-stretch")],["align-content: space-evenly",c("align-content-space-evenly")],["align-content: flex-end",c("align-content-end")],["align-content: flex-start",c("align-content-start")],["align-content: start",c("align-content-start")],["align-content: end",c("align-content-end")],["align-content: normal",c("align-content-stretch")],["align-content: revert",c("align-content-stretch")],["align-content: unset",c("align-content-stretch")],["align-content: initial",c("align-content-stretch")],["justify-content: center",u("justify-content-center")],["justify-content: space-around",u("justify-content-space-around")],["justify-content: space-between",u("justify-content-space-between")],["justify-content: space-evenly",u("justify-content-space-evenly")],["justify-content: flex-end",u("justify-content-end")],["justify-content: flex-start",u("justify-content-start")],["justify-content: end",u("justify-content-end")],["justify-content: start",u("justify-content-start")],["justify-content: right",u("justify-content-end")],["justify-content: left",u("justify-content-start")],["align-items: stretch",v("align-items-stretch")],["align-items: flex-end",v("align-items-end")],["align-items: flex-start",v("align-items-start")],["align-items: end",v("align-items-end")],["align-items: start",v("align-items-start")],["align-items: self-end",v("align-items-end")],["align-items: self-start",v("align-items-start")],["align-items: center",v("align-items-center")],["align-items: baseline",k],["align-content: baseline",k],["flex-wrap: wrap",ut("flex-wrap")],["flex-wrap: nowrap",ut("flex-no-wrap")]]),Io=new Map([["align-self: baseline",k],["align-self: center",Z("align-self-center")],["align-self: flex-start",Z("align-self-start")],["align-self: flex-end",Z("align-self-end")],["align-self: start",m("align-self-start")],["align-self: end",m("align-self-end")],["align-self: self-start",m("align-self-start")],["align-self: self-end",m("align-self-end")],["align-self: stretch",Z("align-self-stretch")]]),Lo=new Map([["grid-auto-flow: row",pt("row")],["grid-auto-flow: column",pt("column")],["align-content: center",w("align-content-center")],["align-content: space-around",w("align-content-space-around")],["align-content: space-between",w("align-content-space-between")],["align-content: stretch",w("align-content-stretch")],["align-content: space-evenly",w("align-content-space-evenly")],["align-content: end",w("align-content-end")],["align-content: start",w("align-content-start")],["align-content: baseline",k],["justify-content: center",g("justify-content-center")],["justify-content: space-around",g("justify-content-space-around")],["justify-content: space-between",g("justify-content-space-between")],["justify-content: space-evenly",g("justify-content-space-evenly")],["justify-content: end",g("justify-content-end")],["justify-content: start",g("justify-content-start")],["justify-content: right",g("justify-content-end")],["justify-content: left",g("justify-content-start")],["justify-content: stretch",g("justify-content-stretch")],["align-items: stretch",S("align-items-stretch")],["align-items: end",S("align-items-end")],["align-items: start",S("align-items-start")],["align-items: self-end",S("align-items-end")],["align-items: self-start",S("align-items-start")],["align-items: center",S("align-items-center")],["align-items: baseline",k],["justify-items: center",b("justify-items-center")],["justify-items: stretch",b("justify-items-stretch")],["justify-items: end",b("justify-items-end")],["justify-items: start",b("justify-items-start")],["justify-items: self-end",b("justify-items-end")],["justify-items: self-start",b("justify-items-start")],["justify-items: right",b("justify-items-end")],["justify-items: left",b("justify-items-start")],["justify-items: baseline",k]]),Co=new Map([["align-self: baseline",k],["align-self: center",m("align-self-center")],["align-self: start",m("align-self-start")],["align-self: end",m("align-self-end")],["align-self: self-start",m("align-self-start")],["align-self: self-end",m("align-self-end")],["align-self: stretch",m("align-self-stretch")]]),mt=o=>{let e=o?.get("display");return e==="flex"||e==="inline-flex"},ht=o=>{let e=o?.get("display");return e==="grid"||e==="inline-grid"};function Eo(o,e,t){if(mt(e)){let s=ee(o,e);if(s)return s}if(mt(t)){let s=bt(o,t);if(s)return s}if(ht(e)){let s=q(o,e);if(s)return s}if(ht(t)){let s=xt(o,t);if(s)return s}return null}function ee(o,e){let t=$o.get(o);return t?t(e||new Map):null}function bt(o,e){let t=Io.get(o);return t?t(e||new Map):null}function q(o,e){let t=Lo.get(o);return t?t(e||new Map):null}function xt(o,e){let t=Co.get(o);return t?t(e||new Map):null}var It={};l(It,{CSSQuery:()=>te});import"./../../../ui/components/tooltips/tooltips.js";import"./../../../ui/legacy/components/inline_editor/inline_editor.js";import*as $ from"./../../../core/sdk/sdk.js";import*as kt from"./../../../ui/legacy/legacy.js";import*as j from"./../../../ui/lit/lit.js";import*as $t from"./../../../ui/visual_logging/visual_logging.js";var St=`.query:not(.editing-query){overflow:hidden}.editable .query-text{color:var(--sys-color-on-surface)}.editable .query-text:hover{text-decoration:var(--override-styles-section-text-hover-text-decoration);cursor:var(--override-styles-section-text-hover-cursor)}
/*# sourceURL=${import.meta.resolve("./cssQuery.css")} */`;var{render:To,html:N}=j,te=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e="";#o;#n=[];#s;#r;#i;#a;#l;#c;#d;#p="";set data(e){this.#e=e.queryPrefix,this.#o=e.queryName,this.#n=[{text:e.queryText,isVariable:!1}],this.#s=e.onQueryTextClick,this.#r=e.onLinkActivate,this.#i=e.getPopoverContents,this.#a=e.jslogContext,this.#u()}parseStyleQueries(e,t,s,n){this.#l=e,this.#c=t,this.#d=s,this.#p=n;let r=this.#n[0]?.text;if(!r)return;let i="if(",d=$.CSSPropertyParser.tokenizeDeclaration("--query",i+r+": 1)");if(!d)return;let U=new $.CSSPropertyParserMatchers.VariableNameMatcher(e,t),R=$.CSSPropertyParser.BottomUpTreeMatching.walk(d,[U]),ve=$.CSSPropertyParser.TreeSearch.findAll(d,T=>R.getMatch(T)instanceof $.CSSPropertyParserMatchers.VariableNameMatch);ve.sort((T,B)=>T.from-B.from);let _=[],ze=d.rule.indexOf(d.propertyValue)+i.length,H=0;for(let T of ve){let B=T.from-ze,Ue=T.to-ze;B>H&&_.push({text:r.substring(H,B),isVariable:!1}),_.push({text:r.substring(B,Ue),isVariable:!0}),H=Ue}H<r.length&&_.push({text:r.substring(H),isVariable:!1}),this.#n=_,this.#u()}#u(){let e=j.Directives.classMap({query:!0,editable:!!this.#s}),t=N`
      <span class="query-text" @click=${this.#s}>${this.#n.map((s,n)=>{if(s.isVariable&&this.#l&&this.#c&&this.#r){let r=s.text,i=this.#l.computeCSSVariable(this.#c,r,this.#d),a=i!==null&&i.value!==void 0,d=()=>{this.#r&&this.#r(i?i.declaration:r)},U=this.#i?.(r,i?.value??null)??null,R=`${this.#p}-${n}-${r}`;return N`
              <devtools-link-swatch class="css-var-link" .data=${{tooltip:{tooltipId:R},text:r,isDefined:a,onLinkActivate:d}}>
              </devtools-link-swatch>
              <devtools-tooltip
                id=${R}
                variant="rich"
                jslogContext="elements.css-var"
              >
                ${U}
              </devtools-tooltip>
            `}return N`${s.text}`})}</span>
    `;To(N`
        <style>${St}</style>
        <style>${kt.inspectorCommonStyles}</style>
        <div class=${e} jslog=${$t.cssRuleHeader(this.#a).track({click:!0,change:!0})}>
          <slot name="indent"></slot>
          ${this.#e?N`<span>${this.#e+" "}</span>`:j.nothing}
          ${this.#o?N`<span>${this.#o+" "}</span>`:j.nothing}
          ${t} {
        </div>`,this.#t,{host:this})}};customElements.define("devtools-css-query",te);var Dt={};l(Dt,{CSSVariableParserError:()=>oe,CSSVariableValueView:()=>se});import*as Ee from"./../../../core/i18n/i18n.js";import*as Te from"./../../../ui/lit/lit.js";var Ce=`.registered-property-popup-wrapper{max-width:232px;font-size:12px;line-height:1.4;word-break:break-all}.monospace{font-family:var(--monospace-font-family);font-size:var(--monospace-font-size)}.divider{margin:8px -7px;border:1px solid var(--sys-color-divider)}.registered-property-links{margin-top:8px}.clickable{color:var(--sys-color-primary);cursor:pointer}.underlined{text-decoration:underline}.unbreakable-text{white-space:nowrap}.css-property{color:var(--webkit-css-property-color,var(--sys-color-token-property-special))}.title{color:var(--sys-color-state-disabled)}
/*# sourceURL=${import.meta.resolve("./cssVariableValueView.css")} */`;var ne={registeredPropertyLinkTitle:"View registered property",invalidPropertyValue:"Invalid property value, expected type {type}",sIsNotDefined:"{PH1} is not defined"},Lt=Ee.i18n.registerUIStrings("panels/elements/components/CSSVariableValueView.ts",ne),Ct=Ee.i18n.getLocalizedString.bind(void 0,Lt),Do=Te.i18nTemplate.bind(void 0,Lt),{render:Et,html:P}=Te;function Tt(o){return P`<div class="registered-property-links">
            <span role="button" @click=${o?.goToDefinition} class="clickable underlined unbreakable-text">
              ${Ct(ne.registeredPropertyLinkTitle)}
            </span>
          </div>`}var oe=class extends HTMLElement{#t=this.attachShadow({mode:"open"});constructor(e){super(),this.#e(e)}#e(e){let t=P`<span class="monospace css-property">${e.registration.syntax()}</span>`;Et(P`
      <style>${Ce}</style>
      <div class="variable-value-popup-wrapper">
        ${Do(ne.invalidPropertyValue,{type:t})}
        ${Tt(e)}
      </div>`,this.#t,{host:this})}},se=class extends HTMLElement{#t=this.attachShadow({mode:"open"});variableName;#e;details;constructor({variableName:e,value:t,details:s}){super(),this.variableName=e,this.details=s,this.value=t}get value(){return this.#e}set value(e){this.#e=e,this.#o()}#o(){let e=this.details?.registration.initialValue(),t=this.details?P`
        <hr class=divider />
        <div class=registered-property-popup-wrapper>
          <div class="monospace">
            <div><span class="css-property">syntax:</span> ${this.details.registration.syntax()}</div>
            <div><span class="css-property">inherits:</span> ${this.details.registration.inherits()}</div>
            ${e?P`<div><span class="css-property">initial-value:</span> ${e}</div>`:""}
          </div>
          ${Tt(this.details)}
        </div>`:"",s=this.value??Ct(ne.sIsNotDefined,{PH1:this.variableName});Et(P`<style>${Ce}</style>
             <div class="variable-value-popup-wrapper">
               ${s}
             </div>
             ${t}
             `,this.#t,{host:this})}};customElements.define("devtools-css-variable-value-view",se);customElements.define("devtools-css-variable-parser-error",oe);var At={};l(At,{ElementsBreadcrumbs:()=>ae,NodeSelectedEvent:()=>ie});import"./../../../ui/kit/kit.js";import"./../../../ui/components/node_text/node_text.js";import*as Pe from"./../../../core/i18n/i18n.js";import*as V from"./../../../core/sdk/sdk.js";import*as Vt from"./../../../ui/components/helpers/helpers.js";import*as L from"./../../../ui/components/render_coordinator/render_coordinator.js";import*as A from"./../../../ui/lit/lit.js";import*as le from"./../../../ui/visual_logging/visual_logging.js";var Mt=`:host{--override-node-text-label-color:var(--sys-color-token-tag);--override-node-text-class-color:var(--sys-color-token-attribute);--override-node-text-id-color:var(--sys-color-token-attribute);--override-node-text-multiple-descriptors-id:var(--sys-color-on-surface);--override-node-text-multiple-descriptors-class:var(--sys-color-token-property)}.crumbs{display:inline-flex;align-items:stretch;width:100%;overflow:hidden;pointer-events:auto;cursor:default;white-space:nowrap;position:relative;background:var(--sys-color-cdt-base-container);font-size:inherit;font-family:inherit}.crumbs-window{flex-grow:2;overflow:hidden}.crumbs-scroll-container{display:inline-flex;margin:0;padding:0}.crumb{display:block;padding:0 7px;line-height:23px;white-space:nowrap}.overflow{padding:0 5px;font-weight:bold;display:block;border:none;flex-grow:0;flex-shrink:0;text-align:center;background-color:var(--sys-color-cdt-base-container);color:var(--sys-color-token-subtle);margin:1px;outline:1px solid var(--sys-color-neutral-outline)}.overflow.hidden{display:none}.overflow:disabled{opacity:50%}.overflow:focus{outline-color:var(--sys-color-primary)}.overflow:not(:disabled):hover{background-color:var(--sys-color-state-hover-on-subtle);color:var(--sys-color-on-surface)}.crumb-link{text-decoration:none;color:inherit}.crumb:hover{background:var(--sys-color-state-hover-on-subtle)}.crumb.selected{background:var(--sys-color-tonal-container)}.crumb:focus{outline:var(--sys-color-primary) auto 1px}
/*# sourceURL=${import.meta.resolve("./elementsBreadcrumbs.css")} */`;var Pt={};l(Pt,{crumbsToRender:()=>Me,determineElementTitle:()=>jt});import*as De from"./../../../core/i18n/i18n.js";var Nt={text:"(text)"},Mo=De.i18n.registerUIStrings("panels/elements/components/ElementsBreadcrumbsUtils.ts",Nt),No=De.i18n.getLocalizedString.bind(void 0,Mo),Me=(o,e)=>e?o.filter(t=>t.nodeType()!==Node.DOCUMENT_NODE).map(t=>({title:jt(t),selected:t.id===e.id,node:t})).reverse():[],I=(o,e={})=>({main:o,extras:e}),jt=o=>{switch(o.nodeType()){case Node.ELEMENT_NODE:{let t=o.pseudoType();if(t)return I("::"+t);let s=I(o.nodeNameInCorrectCase()),n=o.getAttribute("id");n&&(s.extras.id=n);let r=o.getAttribute("class");if(r){let i=new Set(r.split(/\s+/));s.extras.classes=Array.from(i)}return s}case Node.TEXT_NODE:return I(No(Nt.text));case Node.COMMENT_NODE:return I("<!-->");case Node.DOCUMENT_TYPE_NODE:return I("<!doctype>");case Node.DOCUMENT_FRAGMENT_NODE:return I(o.shadowRootType()?"#shadow-root":o.nodeNameInCorrectCase());default:return I(o.nodeNameInCorrectCase())}};var{html:Ne}=A,re={breadcrumbs:"DOM tree breadcrumbs",scrollLeft:"Scroll left",scrollRight:"Scroll right"},jo=Pe.i18n.registerUIStrings("panels/elements/components/ElementsBreadcrumbs.ts",re),je=Pe.i18n.getLocalizedString.bind(void 0,jo),ie=class o extends Event{static eventName="breadcrumbsnodeselected";node;constructor(e){super(o.eventName,{}),this.node=e}},ae=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e=new ResizeObserver(()=>this.#c());#o=[];#n=null;#s=!1;#r="start";#i=!1;#a=!1;set data(e){this.#n=e.selectedNode,this.#o=e.crumbs,this.#a=!1,Vt.ScheduledRender.scheduleRender(this,this.#m)}disconnectedCallback(){this.#i=!1,this.#e.disconnect()}#l(e){return t=>{t.preventDefault(),this.dispatchEvent(new ie(e))}}async#c(){let e=this.#t.querySelector(".crumbs-scroll-container"),t=this.#t.querySelector(".crumbs-window");if(!e||!t)return;let s=await L.read(()=>t.clientWidth),n=await L.read(()=>e.clientWidth);this.#s?n<s&&(this.#s=!1):n>s&&(this.#s=!0),this.#g(),this.#h(t)}#d(e){return()=>e.highlight()}#p(){V.OverlayModel.OverlayModel.hideDOMNodeHighlight(V.TargetManager.TargetManager.instance())}#u(e){return()=>e.highlight()}#v(){V.OverlayModel.OverlayModel.hideDOMNodeHighlight(V.TargetManager.TargetManager.instance())}#y(){if(!this.#e||this.#i===!0)return;let e=this.#t.querySelector(".crumbs");e&&(this.#e.observe(e),this.#i=!0)}async#b(){let e=this.#t.querySelector(".crumbs-scroll-container"),t=this.#t.querySelector(".crumbs-window");if(!e||!t)return;let s=await L.read(()=>t.clientWidth),n=await L.read(()=>e.clientWidth);this.#s?n<s&&(this.#s=!1,this.#m()):n>s&&(this.#s=!0,this.#m())}#x(e){if(!e.target)return;let t=e.target;this.#h(t)}#h(e){let t=e.scrollWidth-e.clientWidth,s=e.scrollLeft,n=10;s<n?this.#r="start":s>=t-n?this.#r="end":this.#r="middle",this.#m()}#w(e){return()=>{this.#a=!0;let t=this.#t.querySelector(".crumbs-window");if(!t)return;let s=t.clientWidth/2,n=e==="left"?Math.max(Math.floor(t.scrollLeft-s),0):t.scrollLeft+s;t.scrollTo({behavior:"smooth",left:n})}}#f(e,t){let s=A.Directives.classMap({overflow:!0,[e]:!0,hidden:!this.#s}),n=je(e==="left"?re.scrollLeft:re.scrollRight);return Ne`
      <button
        class=${s}
        @click=${this.#w(e)}
        ?disabled=${t}
        aria-label=${n}
        title=${n}>
        <devtools-icon name=${"triangle-"+e} style="width: var(--sys-size-6); height: 10px;">
        </devtools-icon>
      </button>
      `}#m(){let e=Me(this.#o,this.#n);A.render(Ne`
      <style>${Mt}</style>
      <nav class="crumbs" aria-label=${je(re.breadcrumbs)} jslog=${le.elementsBreadcrumbs()}>
        ${this.#f("left",this.#r==="start")}

        <div class="crumbs-window" @scroll=${this.#x}>
          <ul class="crumbs-scroll-container">
            ${e.map(t=>{let s={crumb:!0,selected:t.selected};return Ne`
                <li class=${A.Directives.classMap(s)}
                  data-node-id=${t.node.id}
                  data-crumb="true"
                >
                  <a href="#" draggable=false class="crumb-link"
                    jslog=${le.item().track({click:!0,resize:!0})}
                    @click=${this.#l(t.node)}
                    @mousemove=${this.#d(t.node)}
                    @mouseleave=${this.#p}
                    @focus=${this.#u(t.node)}
                    @blur=${this.#v}
                  >
                    <devtools-node-text data-node-title=${t.title.main} .data=${{nodeTitle:t.title.main,nodeId:t.title.extras.id,nodeClasses:t.title.extras.classes}}>
                    </devtools-node-text>
                  </a>
                </li>`})}
          </ul>
        </div>
        ${this.#f("right",this.#r==="end")}
      </nav>
    `,this.#t,{host:this}),this.#b(),this.#y(),this.#g()}async#g(){if(!this.#n||!this.#t||!this.#s||this.#a)return;let e=this.#n.id,t=this.#t.querySelector(`.crumb[data-node-id="${e}"]`);t&&await L.scroll(()=>{t.scrollIntoView({behavior:"auto"})})}};customElements.define("devtools-elements-breadcrumbs",ae);var Ht={};l(Ht,{ElementsTreeExpandButton:()=>ce});import"./../../../ui/kit/kit.js";import*as Ve from"./../../../core/i18n/i18n.js";import{html as Po,render as Vo}from"./../../../ui/lit/lit.js";import*as zt from"./../../../ui/visual_logging/visual_logging.js";var Ot=`:host{display:inline-flex;vertical-align:middle}:host(.hidden){display:none}.expand-button{display:inline-flex;justify-content:center;align-items:center;box-sizing:border-box;width:14px;height:10px;margin:0 2px;border:1px solid var(--override-adorner-border-color,var(--sys-color-tonal-outline));border-radius:10px;background:var(--override-adorner-background-color,var(--sys-color-cdt-base-container));padding:0;position:relative;&:hover::after,
  &:active::before{content:"";height:100%;width:100%;border-radius:inherit;position:absolute;top:0;left:0}&:hover::after{background-color:var(--sys-color-state-hover-on-subtle)}&:active::before{background-color:var(--sys-color-state-ripple-neutral-on-subtle)}}.expand-button devtools-icon{width:14px;height:14px;color:var(--sys-color-primary)}
/*# sourceURL=${import.meta.resolve("./elementsTreeExpandButton.css")} */`;var Ut={expand:"Expand"},Ao=Ve.i18n.registerUIStrings("panels/elements/components/ElementsTreeExpandButton.ts",Ut),Oo=Ve.i18n.getLocalizedString.bind(void 0,Ao),ce=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e=()=>{};set data(e){this.#e=e.clickHandler,this.#o()}#o(){this.#n()}#n(){Vo(Po`
      <style>${Ot}</style>
      <button
        class="expand-button"
        tabindex="-1"
        aria-label=${Oo(Ut.expand)}
        jslog=${zt.action("expand").track({click:!0})}
        @click=${this.#e}><devtools-icon name="dots-horizontal"></devtools-icon></button>`,this.#t,{host:this})}};customElements.define("devtools-elements-tree-expand-button",ce);var Rt={};l(Rt,{QueriedSizeRequestedEvent:()=>de,QueryContainer:()=>pe});import"./../../../ui/kit/kit.js";import"./../../../ui/components/node_text/node_text.js";import*as O from"./../../../core/sdk/sdk.js";import*as h from"./../../../ui/lit/lit.js";import*as qt from"./../../../ui/visual_logging/visual_logging.js";var Bt=`.container-link{display:inline-block;color:var(--sys-color-state-disabled)}.container-link:hover{color:var(--sys-color-primary)}.queried-size-details{color:var(--sys-color-on-surface)}.axis-icon{margin-left:0.4em;width:16px;height:12px;vertical-align:text-top}.axis-icon.hidden{display:none}.axis-icon.vertical{transform:rotate(90deg)}
/*# sourceURL=${import.meta.resolve("./queryContainer.css")} */`;var{render:zo,html:Ft}=h,{PhysicalAxis:Cs,QueryAxis:Es}=O.CSSContainerQuery,de=class o extends Event{static eventName="queriedsizerequested";constructor(){super(o.eventName,{})}},pe=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e;#o;#n;#s=!1;#r;set data(e){this.#e=e.queryName,this.#o=e.container,this.#n=e.onContainerLinkClick,this.#l()}updateContainerQueriedSizeDetails(e){this.#r=e,this.#l()}async#i(){this.#o?.highlight("container-outline"),this.#s=!0,this.dispatchEvent(new de)}#a(){O.OverlayModel.OverlayModel.hideDOMNodeHighlight(O.TargetManager.TargetManager.instance()),this.#s=!1,this.#l()}#l(){if(!this.#o)return;let e,t;this.#e||(e=this.#o.getAttribute("id"),t=this.#o.getAttribute("class")?.split(/\s+/).filter(Boolean));let s=this.#e||this.#o.nodeNameInCorrectCase();zo(Ft`
      <style>${Bt}</style>
      →
      <a href="#" draggable=false class="container-link"
         jslog=${qt.cssRuleHeader("container-query").track({click:!0})}
         @click=${this.#n}
         @mouseenter=${this.#i}
         @mouseleave=${this.#a}>
        <devtools-node-text data-node-title=${s} .data=${{nodeTitle:s,nodeId:e,nodeClasses:t}}>
        </devtools-node-text>
      </a>
      ${this.#s?this.#c():h.nothing}
    `,this.#t,{host:this})}#c(){if(!this.#r||this.#r.queryAxis==="")return h.nothing;let e=this.#r.queryAxis==="size",t=h.Directives.classMap({"axis-icon":!0,hidden:e,vertical:this.#r.physicalAxis==="Vertical"});return Ft`
      <span class="queried-size-details">
        (${this.#r.queryAxis}
        <devtools-icon
          class=${t} name="width"></devtools-icon>
        ) ${e&&this.#r.width?" width: ":h.nothing}
        ${this.#r.width||h.nothing}
        ${e&&this.#r.height?" height: ":h.nothing}
        ${this.#r.height||h.nothing}
      </span>
    `}};customElements.define("devtools-query-container",pe);var Jt={};l(Jt,{FlexboxEditableProperties:()=>Gt,FlexboxEditor:()=>he,GridEditableProperties:()=>Xt,GridEditor:()=>fe,GridLanesEditableProperties:()=>Qt,GridLanesEditor:()=>ge,PropertyDeselectedEvent:()=>E,PropertySelectedEvent:()=>C,StylePropertyEditor:()=>z});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/legacy.js";import*as Oe from"./../../../core/i18n/i18n.js";import*as Kt from"./../../../ui/components/input/input.js";import*as Uo from"./../../../ui/lit/lit.js";import*as Yt from"./../../../ui/visual_logging/visual_logging.js";var _t=`.container{min-width:170px}.row{padding:0;color:var(--sys-color-on-surface);padding-bottom:16px}.row:last-child{padding-bottom:0}.property{padding-bottom:4px;white-space:nowrap}.property-name{color:var(--sys-color-token-property-special)}.property-value{color:var(--sys-color-on-surface)}.property-value.not-authored{color:var(--sys-color-state-disabled)}.buttons{display:flex;flex-direction:row}.buttons > :first-child{border-radius:3px 0 0 3px}.buttons > :last-child{border-radius:0 3px 3px 0}.button{border:1px solid var(--sys-color-neutral-outline);background-color:var(--sys-color-cdt-base-container);width:24px;height:24px;min-width:24px;min-height:24px;padding:0;margin:0;display:flex;justify-content:center;align-items:center;cursor:pointer}.button:focus-visible{outline:auto 5px -webkit-focus-ring-color}.button devtools-icon{color:var(--icon-default)}.button:hover devtools-icon{color:var(--icon-default-hover)}.button.selected devtools-icon{color:var(--icon-toggled)}
/*# sourceURL=${import.meta.resolve("./stylePropertyEditor.css")} */`;var me={selectButton:"Add {propertyName}: {propertyValue}",deselectButton:"Remove {propertyName}: {propertyValue}",denseLabel:"Dense"},Ho=Oe.i18n.registerUIStrings("panels/elements/components/StylePropertyEditor.ts",me),Ae=Oe.i18n.getLocalizedString.bind(void 0,Ho),{render:Bo,html:ue,Directives:Wt}=Uo,C=class o extends Event{static eventName="propertyselected";data;constructor(e,t){super(o.eventName,{}),this.data={name:e,value:t}}},E=class o extends Event{static eventName="propertydeselected";data;constructor(e,t){super(o.eventName,{}),this.data={name:e,value:t}}},z=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e=new Map;#o=new Map;editableProperties=[];getEditableProperties(){return this.editableProperties}set data(e){this.#e=e.authoredProperties,this.#o=e.computedProperties,this.#n()}#n(){Bo(ue`
      <style>${_t}</style>
      <style>${Kt.checkboxStyles}</style>
      <div class="container">
        ${this.editableProperties.map(e=>this.#s(e))}
      </div>
    `,this.#t,{host:this})}#s(e){let t=this.#e.get(e.propertyName),s=!t,n=t||this.#o.get(e.propertyName),r=Wt.classMap({"property-value":!0,"not-authored":s});return e.propertyName==="grid-auto-flow"?this.#r(e,n,r):ue`<div class="row">
      <div class="property">
        <span class="property-name">${e.propertyName}</span>: <span class=${r}>${n}</span>
      </div>
      <div class="buttons">
        ${e.propertyValues.map(i=>this.#a(i,e.propertyName,i===t))}
      </div>
    </div>`}#r(e,t,s){let n=this.#e.get(e.propertyName),r=n==="dense"||n==="row dense"||n==="column dense",i=n==="row"||n==="row dense",a=n==="column"||n==="column dense";return ue`<div class="row">
      <div class="property">
        <span class="property-name">${e.propertyName}</span>: <span class=${s}>${t}</span>
      </div>
      <div class="buttons">
        ${this.#a("row",e.propertyName,i)}
        ${this.#a("column",e.propertyName,a)}
        <devtools-checkbox
          .checked=${r}
          @change=${d=>this.#i(d,i,a)}
        >
          ${Ae(me.denseLabel)}
        </devtools-checkbox>
      </div>
    </div>`}#i(e,t,s){let n=e.target.checked,r="grid-auto-flow",i=this.#e.get(r),a="";t?a=n?"row dense":"row":s?a=n?"column dense":"column":a=n?"dense":"",i&&this.dispatchEvent(new E(r,i)),a&&this.dispatchEvent(new C(r,a))}#a(e,t,s=!1){let n=`${t}: ${e}`,r=this.findIcon(n,this.#o);if(!r)throw new Error(`Icon for ${n} is not found`);let i=`transform: rotate(${r.rotate}deg) scale(${r.scaleX}, ${r.scaleY})`,a=Wt.classMap({button:!0,selected:s}),d={propertyName:t,propertyValue:e},U=Ae(s?me.deselectButton:me.selectButton,d);return ue`
      <button title=${U}
              class=${a}
              jslog=${Yt.item().track({click:!0,resize:!0}).context(`${t}-${e}`)}
              @click=${()=>this.#l(t,e,s)}>
        <devtools-icon style=${i} name=${r.iconName}>
        </devtools-icon>
      </button>
    `}#l(e,t,s){if(e==="grid-auto-flow"){let n=this.#e.get(e),r=n?.includes("dense")||!1;if(s){let i=r?"dense":"";n&&this.dispatchEvent(new E(e,n)),i&&this.dispatchEvent(new C(e,i))}else{let i=r?`${t} dense`:t;n&&this.dispatchEvent(new E(e,n)),this.dispatchEvent(new C(e,i))}}else s?this.dispatchEvent(new E(e,t)):this.dispatchEvent(new C(e,t))}findIcon(e,t){throw new Error("Not implemented")}},he=class extends z{jslogContext="cssFlexboxEditor";editableProperties=Gt;findIcon(e,t){return ee(e,t)}};customElements.define("devtools-flexbox-editor",he);var fe=class extends z{jslogContext="cssGridEditor";editableProperties=Xt;findIcon(e,t){return q(e,t)}};customElements.define("devtools-grid-editor",fe);var ge=class extends z{jslogContext="cssGridLanesEditor";editableProperties=Qt;findIcon(e,t){return q(e,t)}};customElements.define("devtools-grid-lanes-editor",ge);var Gt=[{propertyName:"flex-direction",propertyValues:["row","column","row-reverse","column-reverse"]},{propertyName:"flex-wrap",propertyValues:["nowrap","wrap"]},{propertyName:"align-content",propertyValues:["center","flex-start","flex-end","space-around","space-between","stretch"]},{propertyName:"justify-content",propertyValues:["center","flex-start","flex-end","space-between","space-around","space-evenly"]},{propertyName:"align-items",propertyValues:["center","flex-start","flex-end","stretch","baseline"]}],Xt=[{propertyName:"grid-auto-flow",propertyValues:["row","column"]},{propertyName:"align-content",propertyValues:["center","start","end","space-between","space-around","space-evenly","stretch"]},{propertyName:"justify-content",propertyValues:["center","start","end","space-between","space-around","space-evenly","stretch"]},{propertyName:"align-items",propertyValues:["center","start","end","stretch","baseline"]},{propertyName:"justify-items",propertyValues:["center","start","end","stretch"]}],Qt=[{propertyName:"align-content",propertyValues:["center","start","end","space-between","space-around","space-evenly","stretch"]},{propertyName:"justify-content",propertyValues:["center","start","end","space-between","space-around","space-evenly","stretch"]},{propertyName:"align-items",propertyValues:["center","start","end","stretch"]},{propertyName:"justify-items",propertyValues:["center","start","end","stretch"]}];export{We as AccessibilityTreeNode,Ke as AdornerManager,nt as CSSHintDetailsView,ct as CSSPropertyDocsView,wt as CSSPropertyIconResolver,It as CSSQuery,Dt as CSSVariableValueView,Qe as ComputedStyleProperty,tt as ComputedStyleTrace,At as ElementsBreadcrumbs,Pt as ElementsBreadcrumbsUtils,Ht as ElementsTreeExpandButton,Rt as QueryContainer,Jt as StylePropertyEditor};
//# sourceMappingURL=components.js.map
