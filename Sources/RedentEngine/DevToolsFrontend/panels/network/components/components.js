var Je=Object.defineProperty;var I=(i,e)=>{for(var t in e)Je(i,t,{get:e[t],enumerable:!0})};var xe={};I(xe,{CATEGORY_NAME_GENERAL:()=>K,CATEGORY_NAME_OPEN_INFO:()=>W,CATEGORY_NAME_OPTIONS:()=>j,DEFAULT_VIEW:()=>be,DirectSocketConnectionView:()=>de});import*as Se from"./../../../core/common/common.js";import*as G from"./../../../core/host/host.js";import*as u from"./../../../core/i18n/i18n.js";import*as C from"./../../../core/sdk/sdk.js";import*as Y from"./../../../ui/legacy/legacy.js";import*as V from"./../../../ui/lit/lit.js";import*as T from"./../../../ui/visual_logging/visual_logging.js";var B=`.header{background-color:var(--sys-color-surface1);border-bottom:1px solid var(--sys-color-divider);border-top:1px solid var(--sys-color-divider);line-height:25px;padding:0 5px}.header::marker{font-size:11px;line-height:1}.header:focus{background-color:var(--sys-color-state-header-hover)}details[open] .header-count{display:none}details .hide-when-closed{display:none}details[open] .hide-when-closed{display:block}details summary input{vertical-align:middle}.row{display:flex;line-height:18px;padding-left:8px;gap:var(--sys-size-6);user-select:text;margin:var(--sys-size-3) 0}div.raw-headers-row{display:block}.row:first-of-type{margin-top:var(--sys-size-5)}.row:last-child{margin-bottom:var(--sys-size-5)}.header-name{color:var(--sys-color-on-surface-subtle);font:var(--sys-typescale-body5-medium);width:30%;min-width:160px;max-width:240px;flex-shrink:0;text-transform:capitalize}.header-value{word-break:break-all;display:flex;align-items:center;gap:2px;font:var(--sys-typescale-body4-regular)}.header-name,
.header-value{&::selection{color:var(--sys-color-on-tonal-container);background-color:var(--sys-color-tonal-container)}}.green-circle::before,
.red-circle::before,
.yellow-circle::before{content:'';display:inline-block;width:12px;height:12px;border-radius:6px;vertical-align:text-top;margin-right:2px}.green-circle::before{background-color:var(--sys-color-green-bright)}.red-circle::before{background-color:var(--sys-color-error-bright)}.yellow-circle::before{background-color:var(--issue-color-yellow)}.status-with-comment{color:var(--sys-color-token-subtle)}.raw-headers{font-family:var(--source-code-font-family);font-size:var(--source-code-font-size);white-space:pre-wrap;word-break:break-all}.link,
.devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}.inline-icon{vertical-align:sub}.header-grid-container{display:inline-grid;grid-template-columns:156px 50px 1fr;gap:4px;width:calc(100% - 15px)}.header-grid-container div:last-child{text-align:right}.header .devtools-link{color:var(--sys-color-on-surface)}devtools-link{position:relative}devtools-link .inline-icon{padding-right:3px;vertical-align:middle}.purple.dot::before{background-color:var(--sys-color-purple-bright);content:var(--image-file-empty);width:6px;height:6px;border-radius:50%;outline:1px solid var(--icon-gap-toolbar);left:9px;position:absolute;top:11px;z-index:1}summary label{display:inline-flex;align-items:center;vertical-align:middle;gap:var(--sys-size-3)}summary devtools-checkbox{margin-top:1px}
/*# sourceURL=${import.meta.resolve("./RequestHeadersView.css")} */`;var{render:Qe,html:N}=V,f={general:"General",options:"Options",openInfo:"Open info",type:"DirectSocket type",errorMessage:"Error message",status:"Status",directSocketTypeTcp:"TCP",directSocketTypeUdpConnected:"UDP (connected)",directSocketTypeUdpBound:"UDP (bound)",directSocketStatusOpening:"Opening",directSocketStatusOpen:"Open",directSocketStatusClosed:"Closed",directSocketStatusAborted:"Aborted",joinedMulticastGroups:"joinedMulticastGroups"},Xe=u.i18n.registerUIStrings("panels/network/components/DirectSocketConnectionView.ts",f),y=u.i18n.getLocalizedString.bind(void 0,Xe);function Ze(i){switch(i){case C.NetworkRequest.DirectSocketType.TCP:return y(f.directSocketTypeTcp);case C.NetworkRequest.DirectSocketType.UDP_BOUND:return y(f.directSocketTypeUdpBound);case C.NetworkRequest.DirectSocketType.UDP_CONNECTED:return y(f.directSocketTypeUdpConnected)}}function et(i){switch(i){case C.NetworkRequest.DirectSocketStatus.OPENING:return y(f.directSocketStatusOpening);case C.NetworkRequest.DirectSocketStatus.OPEN:return y(f.directSocketStatusOpen);case C.NetworkRequest.DirectSocketStatus.CLOSED:return y(f.directSocketStatusClosed);case C.NetworkRequest.DirectSocketStatus.ABORTED:return y(f.directSocketStatusAborted)}}var K="general",j="options",W="open-info",be=(i,e,t)=>{function o(l){return i.openCategories.includes(l)}function s(l,g,$){return N`
        <details
          class="direct-socket-category"
          ?open=${o(l)}
          @toggle=${le=>i.onToggleCategory(le,l)}
          jslog=${T.sectionHeader(l).track({click:!0})}
          aria-label=${g}
        >
          <summary
            class="header"
            @keydown=${le=>i.onSummaryKeyDown(le,l)}
          >
            <div class="header-grid-container">
              <div>
                ${g}
              </div>
              <div class="hide-when-closed"></div>
            </div>
          </summary>
          ${$}
        </details>
      `}function r(l,g,$){return g?N`
        <div class="row">
          <div class="header-name">${l}:</div>
          <div
            class="header-value ${$?.join(" ")}"
            @copy=${()=>i.onCopyRow()}
          >${g}</div>
        </div>
      `:V.nothing}let a=i.socketInfo,d=N`
      <div jslog=${T.section(K)}>
        ${r(y(f.type),Ze(a.type))}
        ${r(y(f.status),et(a.status))}
        ${r(y(f.errorMessage),a.errorMessage)}
        ${r(y(f.joinedMulticastGroups),a.joinedMulticastGroups?Array.from(a.joinedMulticastGroups).join(", "):"")}
      </div>`,n=N`
      <div jslog=${T.section(j)}>
        ${r(u.i18n.lockedString("remoteAddress"),a.createOptions.remoteAddr)}
        ${r(u.i18n.lockedString("remotePort"),a.createOptions.remotePort?.toString(10))}
        ${r(u.i18n.lockedString("localAddress"),a.createOptions.localAddr)}
        ${r(u.i18n.lockedString("localPort"),a.createOptions.localPort?.toString(10))}
        ${r(u.i18n.lockedString("noDelay"),a.createOptions.noDelay?.toString())}
        ${r(u.i18n.lockedString("keepAliveDelay"),a.createOptions.keepAliveDelay?.toString(10))}
        ${r(u.i18n.lockedString("sendBufferSize"),a.createOptions.sendBufferSize?.toString(10))}
        ${r(u.i18n.lockedString("receiveBufferSize"),a.createOptions.receiveBufferSize?.toString(10))}
        ${r(u.i18n.lockedString("dnsQueryType"),a.createOptions.dnsQueryType)}
        ${r(u.i18n.lockedString("multicastTimeToLive"),a.createOptions.multicastTimeToLive?.toString(10))}
        ${r(u.i18n.lockedString("multicastLoopback"),a.createOptions.multicastLoopback?.toString())}
        ${r(u.i18n.lockedString("multicastAllowAddressSharing"),a.createOptions.multicastAllowAddressSharing?.toString())}
      </div>`,m=V.nothing;a.openInfo&&(m=N`
          <div jslog=${T.section(W)}>
            ${r(u.i18n.lockedString("remoteAddress"),a.openInfo.remoteAddr)}
            ${r(u.i18n.lockedString("remotePort"),a.openInfo?.remotePort?.toString(10))}
            ${r(u.i18n.lockedString("localAddress"),a.openInfo.localAddr)}
            ${r(u.i18n.lockedString("localPort"),a.openInfo?.localPort?.toString(10))}
          </div>`),Qe(N`
    <style>${Y.inspectorCommonStyles}</style>
    <style>${B}</style>
    ${s(K,y(f.general),d)}
    ${s(j,y(f.options),n)}
    ${a.openInfo?s(W,y(f.openInfo),m):V.nothing}
  `,t,{container:{attributes:{jslog:`${T.pane("connection-info").track({resize:!0})}`}}})},de=class extends Y.Widget.Widget{#t;#e;constructor(e,t=be){super({useShadowDom:"pure"}),this.#t=e,this.#e=t,this.performUpdate()}wasShown(){super.wasShown(),this.#t.addEventListener(C.NetworkRequest.Events.TIMING_CHANGED,this.requestUpdate,this)}willHide(){super.willHide(),this.#t.removeEventListener(C.NetworkRequest.Events.TIMING_CHANGED,this.requestUpdate,this)}performUpdate(){if(!this.#t||!this.#t.directSocketInfo)return;let e=[K,j,W].filter(o=>this.#i(o).get(),this),t={socketInfo:this.#t.directSocketInfo,openCategories:e,onSummaryKeyDown:(o,s)=>{if(!o.target)return;let a=o.target.parentElement;if(!a)throw new Error("<details> element is not found for a <summary> element");let d;switch(o.key){case"ArrowLeft":d=!1;break;case"ArrowRight":d=!0;break;default:return}a.open!==d&&this.#o(s,d)},onToggleCategory:(o,s)=>{let r=o.target;this.#o(s,r.open)},onCopyRow:()=>{G.userMetrics.actionTaken(G.UserMetrics.Action.NetworkPanelCopyValue)}};this.#e(t,void 0,this.contentElement)}#o(e,t){this.#i(e).set(t),this.requestUpdate()}#i(e){return Se.Settings.Settings.instance().createSetting(`connection-info-${e}-category-expanded`,!0)}};var Ee={};I(Ee,{EditableSpan:()=>J});import*as ce from"./../../../ui/components/helpers/helpers.js";import{html as tt,render as ot}from"./../../../ui/lit/lit.js";import*as Ce from"./../../../ui/visual_logging/visual_logging.js";var $e=`:host{display:inline}.editable{cursor:text;overflow-wrap:anywhere;min-height:18px;line-height:18px;min-width:0.5em;background:transparent;border:none;border-radius:4px;outline:none;display:inline-block;font-family:var(--monospace-font-family);font-size:var(--monospace-font-size);&:hover{border:1px solid var(--sys-color-neutral-outline)}&:focus{border:1px solid var(--sys-color-state-focus-ring)}}.editable::selection{color:var(--sys-color-on-tonal-container);background-color:var(--sys-color-tonal-container)}
/*# sourceURL=${import.meta.resolve("./EditableSpan.css")} */`;var J=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e="";connectedCallback(){this.#t.addEventListener("focusin",this.#s.bind(this)),this.#t.addEventListener("keydown",this.#o.bind(this)),this.#t.addEventListener("input",this.#i.bind(this))}set data(e){this.#e=e.value,ce.ScheduledRender.scheduleRender(this,this.#n)}get value(){return this.#t.querySelector("span")?.innerText||""}set value(e){this.#e=e;let t=this.#t.querySelector("span");t&&(t.innerText=e)}#o(e){e.key==="Enter"&&(e.preventDefault(),e.target?.blur())}#i(e){this.#e=e.target.innerText}#s(e){let t=e.target,o=window.getSelection(),s=document.createRange();s.selectNodeContents(t),o?.removeAllRanges(),o?.addRange(s)}#n(){if(!ce.ScheduledRender.isScheduledRender(this))throw new Error("HeaderSectionRow render was not scheduled");ot(tt`
      <style>${$e}</style>
      <span
        contenteditable="plaintext-only"
        class="editable"
        tabindex="0"
        .innerText=${this.#e}
        jslog=${Ce.value("header-editor").track({change:!0,keydown:"Enter|Escape"})}
        ></span>`,this.#t,{host:this})}focus(){requestAnimationFrame(()=>{this.#t.querySelector(".editable")?.focus()})}};customElements.define("devtools-editable-span",J);var Oe={};I(Oe,{EnableHeaderEditingEvent:()=>X,HeaderEditedEvent:()=>q,HeaderRemovedEvent:()=>Q,HeaderSectionRow:()=>Z,compareHeaders:()=>c,isValidHeaderName:()=>M});import"./../../../ui/kit/kit.js";import*as D from"./../../../core/host/host.js";import*as ee from"./../../../core/i18n/i18n.js";import*as Te from"./../../../core/platform/platform.js";import*as De from"./../../../core/sdk/sdk.js";import*as te from"./../../../third_party/chromium/client-variations/client-variations.js";import"./../../../ui/components/buttons/buttons.js";import*as L from"./../../../ui/components/helpers/helpers.js";import*as Le from"./../../../ui/legacy/legacy.js";import*as w from"./../../../ui/lit/lit.js";import*as he from"./../../../ui/visual_logging/visual_logging.js";var Re=`:host{display:block}.row{display:flex;line-height:18px;padding-left:8px;gap:var(--sys-size-6);user-select:text;margin:var(--sys-size-3) 0}.row:hover{background-color:var(--sys-color-state-hover-on-subtle)}.header-name{font:var(--sys-typescale-body5-medium);color:var(--sys-color-on-surface-subtle);width:30%;min-width:160px;max-width:240px;flex-shrink:0;text-transform:capitalize;overflow-wrap:break-word}.header-name,
.header-value{&::selection{color:var(--sys-color-on-tonal-container);background-color:var(--sys-color-tonal-container)}}.header-name.pseudo-header{text-transform:none}.header-editable .header-name{color:var(--sys-color-token-property-special)}.row.header-deleted .header-name{color:var(--sys-color-token-subtle)}.header-value{display:flex;overflow-wrap:anywhere;margin-inline-end:14px;font-family:var(--monospace-font-family);font-size:var(--monospace-font-size)}.header-badge-text{font-variant:small-caps;font-weight:500;white-space:pre-wrap;word-break:break-all;text-transform:none}.header-badge{display:inline;background-color:var(--sys-color-error);color:var(--sys-color-on-error);border-radius:100vh;padding-left:6px;padding-right:6px}.call-to-action{background-color:var(--sys-color-neutral-container);padding:8px;border-radius:5px;margin:4px}.call-to-action-body{display:flex;gap:var(--sys-size-4);padding:6px 0;margin-left:var(--sys-size-1);border-left:2px solid var(--issue-color-yellow);padding-left:11px;line-height:20px}.call-to-action .explanation{font-weight:bold}.call-to-action code{font-size:90%}.call-to-action .example .comment::before{content:" \u2014 "}.link,
.devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}.explanation .link{font-weight:normal}.inline-icon{margin-top:var(--sys-size-2)}.row-flex-icon{margin:2px 5px 0}.header-value code{display:block;white-space:pre-wrap;font-size:90%;color:var(--sys-color-token-subtle)}devtools-link .inline-icon{padding-right:3px}.header-highlight{background-color:var(--sys-color-yellow-container)}.header-warning{color:var(--sys-color-error)}.header-overridden{background-color:var(--sys-color-tertiary-container);border-left:3px solid var(--sys-color-tertiary);padding-left:5px}.header-deleted{background-color:var(--sys-color-surface-error);border-left:3px solid var(--sys-color-error-bright);color:var(--sys-color-token-subtle);text-decoration:line-through}.header-highlight.header-overridden{background-color:var(--sys-color-yellow-container);border-left:3px solid var(--sys-color-tertiary);padding-left:5px}.inline-button{vertical-align:middle}.row .inline-button{opacity:0%;visibility:hidden;transition:opacity 200ms;padding-left:2px}.row.header-overridden:focus-within .inline-button,
.row.header-overridden:hover .inline-button{opacity:100%;visibility:visible}.row:hover .inline-button.enable-editing{opacity:100%;visibility:visible}.flex-right{margin-left:auto}.flex-columns{flex-direction:column}
/*# sourceURL=${import.meta.resolve("./HeaderSectionRow.css")} */`;var{render:it,html:v}=w,k={copyValue:"Copy value",activeClientExperimentVariation:"Active `client experiment variation IDs`.",activeClientExperimentVariationIds:"Active `client experiment variation IDs` that trigger server-side behavior.",decoded:"Decoded:",editHeader:"Override header",headerNamesOnlyLetters:"Header names should contain only letters, digits, hyphens, or underscores",learnMore:"Learn more",learnMoreInTheIssuesTab:"Learn more in the issues tab",reloadPrompt:"Refresh the page/request for these changes to take effect",removeOverride:"Remove this header override"},st=ee.i18n.registerUIStrings("panels/network/components/HeaderSectionRow.ts",k),R=ee.i18n.getLocalizedString.bind(void 0,st),M=i=>/^[a-z0-9_\-]+$/i.test(i),c=(i,e)=>i?.replaceAll(/\s/g," ")===e?.replaceAll(/\s/g," "),q=class i extends Event{static eventName="headeredited";headerName;headerValue;constructor(e,t){super(i.eventName,{}),this.headerName=e,this.headerValue=t}},Q=class i extends Event{static eventName="headerremoved";headerName;headerValue;constructor(e,t){super(i.eventName,{}),this.headerName=e,this.headerValue=t}},X=class i extends Event{static eventName="enableheaderediting";constructor(){super(i.eventName,{})}},Z=class extends HTMLElement{#t=this.attachShadow({mode:"open"});#e=null;#o=!1;#i=!0;set data(e){this.#e=e.header,this.#o=this.#e.originalValue!==void 0&&this.#e.value!==this.#e.originalValue,this.#i=M(this.#e.name),L.ScheduledRender.scheduleRender(this,this.#s)}#s(){if(!L.ScheduledRender.isScheduledRender(this))throw new Error("HeaderSectionRow render was not scheduled");if(!this.#e)return;let e=w.Directives.classMap({row:!0,"header-highlight":!!this.#e.highlight,"header-overridden":!!this.#e.isOverride||this.#o,"header-editable":this.#e.valueEditable===1,"header-deleted":!!this.#e.isDeleted}),t=w.Directives.classMap({"header-name":!0,"pseudo-header":this.#e.name.startsWith(":")}),o=w.Directives.classMap({"header-value":!0,"header-warning":!!this.#e.headerValueIncorrect,"flex-columns":this.#e.name==="x-client-data"&&!this.#e.isResponseHeader}),s=this.#e.nameEditable&&this.#e.valueEditable===1,r=this.#e.nameEditable||this.#e.isDeleted||this.#o;it(v`
      <style>${Re}</style>
      <div class=${e}>
        <div class=${t}>
          ${this.#e.headerNotSet?v`<div class="header-badge header-badge-text">${ee.i18n.lockedString("not-set")}</div> `:w.nothing}
          ${s&&!this.#i?v`<devtools-icon class="inline-icon disallowed-characters medium" title=${k.headerNamesOnlyLetters} name='cross-circle-filled'>
            </devtools-icon>`:w.nothing}
          ${s&&!this.#e.isDeleted?v`<devtools-editable-span
              @focusout=${this.#m}
              @keydown=${this.#l}
              @input=${this.#h}
              @paste=${this.#f}
              .data=${{value:this.#e.name}}
            ></devtools-editable-span>`:this.#e.name}
        </div>
        <div
          class=${o}
          @copy=${()=>D.userMetrics.actionTaken(D.UserMetrics.Action.NetworkPanelCopyValue)}
          @contextmenu=${this.#v}
        >
          ${this.#n()}
        </div>
        ${r?v`<devtools-icon name="info" class="row-flex-icon flex-right medium" title=${k.reloadPrompt}>
          </devtools-icon>`:w.nothing}
      </div>
      ${this.#p(this.#e.blockedDetails)}
    `,this.#t,{host:this}),this.#e.highlight&&this.scrollIntoView({behavior:"auto"})}#n(){if(!this.#e)return w.nothing;if(this.#e.name==="x-client-data"&&!this.#e.isResponseHeader)return this.#u(this.#e);if(this.#e.isDeleted||this.#e.valueEditable!==1){let e=this.#e.isResponseHeader&&!this.#e.isDeleted&&this.#e.valueEditable!==2;return v`
      ${this.#e.value||""}
      ${this.#a(this.#e)}
      ${e?v`
        <devtools-button
          title=${R(k.editHeader)}
          .accessibleLabel=${R(k.editHeader)}
          .size=${"SMALL"}
          .iconName=${"edit"}
          .variant=${"icon"}
          @click=${()=>{this.dispatchEvent(new X)}}
          jslog=${he.action("enable-header-overrides").track({click:!0})}
          class="enable-editing inline-button"
        ></devtools-button>
      `:w.nothing}
    `}return v`
      <devtools-editable-span
        @focusout=${this.#c}
        @input=${this.#r}
        @paste=${this.#r}
        @keydown=${this.#l}
        .data=${{value:this.#e.value||""}}
      ></devtools-editable-span>
      ${this.#a(this.#e)}
      <devtools-button
        title=${R(k.removeOverride)}
        .size=${"SMALL"}
        .iconName=${"bin"}
        .variant=${"icon"}
        class="remove-header inline-button"
        @click=${this.#g}
        jslog=${he.action("remove-header-override").track({click:!0})}
      ></devtools-button>
    `}#u(e){let t=te.parseClientVariations(e.value||""),o=te.formatClientVariations(t,R(k.activeClientExperimentVariation),R(k.activeClientExperimentVariationIds));return v`
      <div>${e.value||""}</div>
      <div>${R(k.decoded)}</div>
      <code>${o}</code>
    `}focus(){requestAnimationFrame(()=>{this.#t.querySelector(".header-name devtools-editable-span")?.focus()})}#a(e){if(e.name==="set-cookie"&&e.setCookieBlockedReasons){let t=e.setCookieBlockedReasons.map(De.NetworkRequest.setCookieBlockedReasonToUiString).join(`
`);return v`
        <devtools-icon class="row-flex-icon medium" title=${t} name='warning-filled'>
        </devtools-icon>
      `}return w.nothing}#p(e){return e?v`
      <div class="call-to-action">
        <div class="call-to-action-body">
          <div class="explanation">${e.explanation()}</div>
          ${e.examples.map(t=>v`
            <div class="example">
              <code>${t.codeSnippet}</code> ${t.comment?v`<span class="comment"> ${t.comment()}</span>`:""}
           </div>`)} ${this.#d(e)}
        </div>
      </div>
    `:w.nothing}#d(e){return e?.reveal?v`
        <div class="devtools-link" @click=${e.reveal}>
          <devtools-icon name="issue-exclamation-filled" class="inline-icon medium">
          </devtools-icon
          >${R(k.learnMoreInTheIssuesTab)}
        </div>
      `:e?.link?v`
        <devtools-link href=${e.link.url} class="link">
          <devtools-icon name="open-externally" class="inline-icon extra-large" style="color: var(--icon-link);">
          </devtools-icon
          >${R(k.learnMore)}
        </devtools-link>
      `:w.nothing}#c(e){let t=e.target;if(!this.#e)return;let o=t.value.trim();c(o,this.#e.value?.trim())||(this.#e.value=o,this.dispatchEvent(new q(this.#e.name,o)),L.ScheduledRender.scheduleRender(this,this.#s)),window.getSelection()?.removeAllRanges(),this.#e.originalName=""}#m(e){let t=e.target;if(!this.#e)return;let o=Te.StringUtilities.toLowerCaseString(t.value.trim());o===""?t.value=this.#e.name:c(o,this.#e.name.trim())||(this.#e.name=o,this.dispatchEvent(new q(o,this.#e.value||"")),L.ScheduledRender.scheduleRender(this,this.#s)),window.getSelection()?.removeAllRanges()}#g(){if(!this.#e)return;let e=this.#t.querySelector(".header-value devtools-editable-span");this.#e.originalValue&&(e.value=this.#e?.originalValue),this.dispatchEvent(new Q(this.#e.name,this.#e.value||""))}#l(e){let t=e.target;if(e.key==="Escape"){if(e.consume(),t.matches(".header-name devtools-editable-span"))t.value=this.#e?.name||"",this.#h(e);else if(t.matches(".header-value devtools-editable-span")&&(t.value=this.#e?.value||"",this.#r(e),this.#e?.originalName)){let o=this.#t.querySelector(".header-name devtools-editable-span");o.value=this.#e.originalName,this.#e.originalName="",o.dispatchEvent(new Event("input")),o.focus();return}t.blur()}}#h(e){let t=e.target,o=M(t.value);this.#i!==o&&(this.#i=o,L.ScheduledRender.scheduleRender(this,this.#s))}#r(e){let t=e.target,o=this.#e?.originalValue!==void 0&&!c(this.#e?.originalValue||"",t.value);this.#o!==o&&(this.#o=o,this.#e&&(this.#e.highlight=!1),L.ScheduledRender.scheduleRender(this,this.#s))}#f(e){if(!e.clipboardData)return;let t=e.target,o=e.clipboardData.getData("text/plain")||"",s=o.indexOf(":");if(s<1){t.value=o,e.preventDefault(),t.dispatchEvent(new Event("input",{bubbles:!0}));return}this.#e&&(this.#e.originalName=this.#e.name);let r=o.substring(s+1,o.length).trim(),a=o.substring(0,s);t.value=a,t.dispatchEvent(new Event("input"));let d=this.#t.querySelector(".header-value devtools-editable-span");d&&(d.focus(),d.value=r,d.dispatchEvent(new Event("input"))),e.preventDefault()}#v(e){if(!this.#e)return;e.stopPropagation(),e.preventDefault();let t=new Le.ContextMenu.ContextMenu(e);t.clipboardSection().appendItem(R(k.copyValue),()=>{D.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(this.#e?.value||""),D.userMetrics.actionTaken(D.UserMetrics.Action.NetworkPanelCopyValue)}),t.show()}};customElements.define("devtools-header-section-row",Z);var Ae={};I(Ae,{DEFAULT_VIEW:()=>Ue,RequestHeaderSection:()=>me,requestHeadersViewStyles:()=>B});import"./../../../ui/kit/kit.js";import*as ge from"./../../../core/i18n/i18n.js";import*as ue from"./../../../core/platform/platform.js";import*as Ie from"./../../../ui/legacy/legacy.js";import*as fe from"./../../../ui/lit/lit.js";import*as Ne from"./../../../ui/visual_logging/visual_logging.js";import"./../forward/forward.js";var He=`@scope to (devtools-widget > *){:scope{display:block}devtools-header-section-row:last-of-type{margin-bottom:10px}devtools-header-section-row:first-of-type{margin-top:2px}.call-to-action{background-color:var(--sys-color-neutral-container);padding:8px;border-radius:5px;margin:4px}.call-to-action-body{display:flex;gap:var(--sys-size-4);padding:6px 0;margin-left:var(--sys-size-1);border-left:2px solid var(--issue-color-yellow);padding-left:11px;line-height:20px}.call-to-action .explanation{font-weight:bold}.call-to-action code{font-size:90%}.call-to-action .example .comment::before{content:" \u2014 "}.link,
  .devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}.explanation .link{font-weight:normal}.inline-icon{margin-top:var(--sys-size-2)}@media (forced-colors: active){.link,
    .devtools-link{color:linktext;text-decoration-color:linktext}}}
/*# sourceURL=${import.meta.resolve("./RequestHeaderSection.css")} */`;var{render:rt,html:pe}=fe,F={learnMore:"Learn more",provisionalHeadersAreShownDisableCache:"Provisional headers are shown. Disable cache to see full headers.",onlyProvisionalHeadersAre:"Only provisional headers are available because this request was not sent over the network and instead was served from a local cache, which doesn\u2019t store the original request headers. Disable cache to see full request headers.",provisionalHeadersAreShown:"Provisional headers are shown."},nt=ge.i18n.registerUIStrings("panels/network/components/RequestHeaderSection.ts",F),oe=ge.i18n.getLocalizedString.bind(void 0,nt),Ue=(i,e,t)=>{let o=i.headers;rt(pe`
    <style>${He}</style>
    ${i.isProvisionalHeaders?at(i.isRequestCached):fe.nothing}
    ${o.map(s=>pe`
      <devtools-header-section-row
        .data=${{header:s}}
        jslog=${Ne.item("request-header").track({resize:!0})}
      ></devtools-header-section-row>
    `)}
  `,t)};function at(i){let e,t="";return i?(e=oe(F.provisionalHeadersAreShownDisableCache),t=oe(F.onlyProvisionalHeadersAre)):e=oe(F.provisionalHeadersAreShown),pe`
    <div class="call-to-action">
      <div class="call-to-action-body">
        <devtools-icon class="inline-icon medium" name='warning-filled'></devtools-icon>
        <div class="explanation" title=${t}>
          ${e} <devtools-link href="https://developer.chrome.com/docs/devtools/network/reference/#provisional-headers" class="link">${oe(F.learnMore)}</devtools-link>
        </div>
      </div>
    </div>
  `}var me=class extends Ie.Widget.Widget{#t=null;#e=[];#o;constructor(e,t=Ue){super(e,{useShadowDom:!0}),this.#o=t}set toReveal(e){e&&(e.section==="Request"&&this.#e.filter(t=>t.name===e.header?.toLowerCase()).forEach(t=>{t.highlight=!0}),this.requestUpdate())}set request(e){this.#t=e,this.#e=this.#t.requestHeaders().map(t=>({name:ue.StringUtilities.toLowerCaseString(t.name),value:t.value,valueEditable:2})),this.#e.sort((t,o)=>ue.StringUtilities.compare(t.name,o.name)),this.requestUpdate()}performUpdate(){this.#t&&this.#o({headers:this.#e,isProvisionalHeaders:this.#t.requestHeadersText()===void 0,isRequestCached:this.#t.cached()||this.#t.cachedInMemory()},void 0,this.contentElement)}};var _e={};I(_e,{DEFAULT_VIEW:()=>Fe,RequestTrustTokensView:()=>ye,statusConsideredSuccess:()=>ze});import"./../../../ui/components/report_view/report_view.js";import"./../../../ui/kit/kit.js";import*as we from"./../../../core/i18n/i18n.js";import*as ve from"./../../../core/sdk/sdk.js";import*as Ve from"./../../../ui/legacy/legacy.js";import*as U from"./../../../ui/lit/lit.js";import*as Me from"./../../../ui/visual_logging/visual_logging.js";var Pe=`@scope to (devtools-widget > *){.code{font-family:var(--monospace-font-family);font-size:var(--monospace-font-size)}.issuers-list{display:flex;flex-direction:column;list-style-type:none;padding:0;margin:0}.status-icon{margin:0 0.3em 2px 0;vertical-align:middle;&.failure{color:var(--icon-error)}&.success{color:var(--icon-checkmark-green)}}}
/*# sourceURL=${import.meta.resolve("./RequestTrustTokensView.css")} */`;var{html:O,render:lt}=U,h={parameters:"Parameters",type:"Type",refreshPolicy:"Refresh policy",issuers:"Issuers",topLevelOrigin:"Top level origin",issuer:"Issuer",result:"Result",status:"Status",numberOfIssuedTokens:"Number of issued tokens",success:"Success",failure:"Failure",theOperationsResultWasServedFrom:"The operation\u2019s result was served from cache.",theOperationWasFulfilledLocally:"The operation was fulfilled locally, no request was sent.",theKeysForThisPSTIssuerAreUnavailable:"The keys for this PST issuer are unavailable. The issuer may need to be registered via the Chrome registration process.",aClientprovidedArgumentWas:"A client-provided argument was malformed or otherwise invalid.",eitherNoInputsForThisOperation:"Either no inputs for this operation are available or the output exceeds the operations quota.",theServersResponseWasMalformedOr:"The server\u2019s response was malformed or otherwise invalid.",theOperationFailedForAnUnknown:"The operation failed for an unknown reason.",perSiteLimit:"Per-site issuer limit reached."},dt=we.i18n.registerUIStrings("panels/network/components/RequestTrustTokensView.ts",h),p=we.i18n.getLocalizedString.bind(void 0,dt);function qe(i,e,t){return!e||Array.isArray(e)&&e.length===0?U.nothing:O`
    <devtools-report-key>${i}</devtools-report-key>
    <devtools-report-value class=${t?"code":""}>
      ${Array.isArray(e)?O`
        <ul class="issuers-list">
            ${e.map(o=>O`<li>${o}</li>`)}
        </ul>`:e}
    </devtools-report-value>
  `}var ct=(i,e,t)=>i?O`
    <devtools-report-section-header>${p(h.result)}</devtools-report-section-header>
    <devtools-report-key>${p(h.status)}</devtools-report-key>
    <devtools-report-value>
      <span>
        <devtools-icon class="status-icon medium ${i==="Success"?"success":"failure"}"
        name=${i==="Success"?"check-circle":"cross-circle-filled"}>
        </devtools-icon>
        <strong>${p(i==="Success"?h.success:h.failure)}</strong>
        ${e?O` ${e}`:U.nothing}
      </span>
    </devtools-report-value>
    ${qe(p(h.numberOfIssuedTokens),t)}
    <devtools-report-divider></devtools-report-divider>
    `:U.nothing,ht=i=>!i||i.length===0?U.nothing:O`
    <devtools-report-section-header jslog=${Me.pane("trust-tokens").track({resize:!0})}>
      ${p(h.parameters)}
    </devtools-report-section-header>
    ${i.map(e=>qe(e.name,e.value,e.isCode))}
    <devtools-report-divider></devtools-report-divider>
  `,Fe=(i,e,t)=>{lt(O`
    <style>${Pe}</style>
    <devtools-report>
      ${ht(i.params)}
      ${ct(i.status,i.description,i.issuedTokenCount)}
    </devtools-report>
  `,t)},ye=class extends Ve.Widget.Widget{#t=null;#e;constructor(e,t=Fe){super(e),this.#e=t}get request(){return this.#t}set request(e){this.#t!==e&&(this.#i(),this.#t=e,this.#o(),this.requestUpdate())}#o(){this.#t&&this.isShowing()&&this.#t.addEventListener(ve.NetworkRequest.Events.TRUST_TOKEN_RESULT_ADDED,this.requestUpdate,this)}#i(){this.#t&&this.#t.removeEventListener(ve.NetworkRequest.Events.TRUST_TOKEN_RESULT_ADDED,this.requestUpdate,this)}wasShown(){super.wasShown(),this.#o(),this.requestUpdate()}willHide(){super.willHide(),this.#i()}performUpdate(){if(!this.request)return;let e=this.request.trustTokenParams(),t=this.request.trustTokenOperationDoneEvent(),o={};e&&(o.params=[{name:p(h.type),value:e.operation.toString(),isCode:!0}],e.operation==="Redemption"&&o.params.push({name:p(h.refreshPolicy),value:e.refreshPolicy.toString(),isCode:!0}),e.issuers&&e.issuers.length>0&&o.params.push({name:p(h.issuers),value:e.issuers}),t?.topLevelOrigin&&o.params.push({name:p(h.topLevelOrigin),value:t.topLevelOrigin}),t?.issuerOrigin&&o.params.push({name:p(h.issuer),value:t.issuerOrigin})),t&&(o.status=ze(t.status)?"Success":"Failure",o.description=ut(t.status)??void 0,o.issuedTokenCount=t.type==="Issuance"?t.issuedTokenCount:void 0),this.#e(o,void 0,this.contentElement)}};function ze(i){return i==="Ok"||i==="AlreadyExists"||i==="FulfilledLocally"}function ut(i){switch(i){case"Ok":return null;case"AlreadyExists":return p(h.theOperationsResultWasServedFrom);case"FulfilledLocally":return p(h.theOperationWasFulfilledLocally);case"InvalidArgument":return p(h.aClientprovidedArgumentWas);case"ResourceExhausted":return p(h.eitherNoInputsForThisOperation);case"BadResponse":return p(h.theServersResponseWasMalformedOr);case"MissingIssuerKeys":return p(h.theKeysForThisPSTIssuerAreUnavailable);case"FailedPrecondition":case"ResourceLimited":case"InternalError":case"Unauthorized":case"UnknownError":return p(h.theOperationFailedForAnUnknown);case"SiteIssuerLimit":return p(h.perSiteLimit)}}var Ye={};I(Ye,{EarlyHintsHeaderSection:()=>re,RESPONSE_HEADER_SECTION_DATA_KEY:()=>ie,ResponseHeaderSection:()=>ne});import*as _ from"./../../../core/common/common.js";import*as b from"./../../../core/host/host.js";import*as A from"./../../../core/i18n/i18n.js";import*as x from"./../../../core/platform/platform.js";import*as Be from"./../../../core/text_utils/text_utils.js";import*as P from"./../../../models/issues_manager/issues_manager.js";import*as H from"./../../../models/persistence/persistence.js";import"./../forward/forward.js";import*as Ke from"./../../sources/sources.js";import"./../../../ui/components/buttons/buttons.js";import*as je from"./../../../ui/legacy/legacy.js";import{html as z,nothing as pt,render as We}from"./../../../ui/lit/lit.js";import*as ae from"./../../../ui/visual_logging/visual_logging.js";var ke=`:host{display:block}devtools-header-section-row:last-of-type{margin-bottom:var(--sys-size-5)}devtools-header-section-row:first-of-type{margin-top:var(--sys-size-5)}.add-header-button{margin:var(--sys-size-5) 0 var(--sys-size-5) var(--sys-size-4)}devtools-header-section-row + .add-header-button{margin-top:calc(-1 * var(--sys-size-3))}
/*# sourceURL=${import.meta.resolve("./ResponseHeaderSection.css")} */`;var S={addHeader:"Add header",chooseThisOptionIfTheResourceAnd:"Choose this option if the resource and the document are served from the same site.",onlyChooseThisOptionIfAn:"Only choose this option if an arbitrary website including this resource does not impose a security risk.",thisDocumentWasBlockedFrom:"The document was blocked from loading in a popup opened by a sandboxed iframe because this document specified a cross-origin opener policy.",toEmbedThisFrameInYourDocument:"To embed this frame in your document, the response needs to enable the cross-origin embedder policy by specifying the following response header:",toUseThisResourceFromADifferent:"To use this resource from a different origin, the server needs to specify a cross-origin resource policy in the response headers:",toUseThisResourceFromADifferentOrigin:"To use this resource from a different origin, the server may relax the cross-origin resource policy response header:",toUseThisResourceFromADifferentSite:"To use this resource from a different site, the server may relax the cross-origin resource policy response header:"},Ge=A.i18n.registerUIStrings("panels/network/components/ResponseHeaderSection.ts",S),mt=A.i18n.getLocalizedString.bind(void 0,Ge),E=A.i18n.getLazilyComputedLocalizedString.bind(void 0,Ge),ie="ResponseHeaderSection",se=class extends HTMLElement{shadow=this.attachShadow({mode:"open"});headerDetails=[];setHeaders(e){e.sort(function(t,o){return x.StringUtilities.compare(t.name.toLowerCase(),o.name.toLowerCase())}),this.headerDetails=e.map(t=>({name:x.StringUtilities.toLowerCaseString(t.name),value:t.value.replace(/\s/g," ")}))}highlightHeaders(e){e.toReveal?.section==="Response"&&this.headerDetails.filter(t=>c(t.name,e.toReveal?.header?.toLowerCase())).forEach(t=>{t.highlight=!0})}},re=class extends se{#t;set data(e){this.#t=e.request,this.setHeaders(this.#t.earlyHintsHeaders),this.highlightHeaders(e),this.#e()}#e(){this.#t&&We(z`
      <style>${ke}</style>
      ${this.headerDetails.map(e=>z`
        <devtools-header-section-row .data=${{header:e}}></devtools-header-section-row>
      `)}
    `,this.shadow,{host:this})}};customElements.define("devtools-early-hints-header-section",re);var ne=class extends se{#t;#e=[];#o=null;#i=[];#s=0;set data(e){this.#t=e.request,this.#s=H.NetworkPersistenceManager.NetworkPersistenceManager.isForbiddenNetworkUrl(this.#t.url())?2:0;let t=this.#t.sortedResponseHeaders.concat(this.#t.setCookieHeaders);this.setHeaders(t);let o=[];if(this.#t.wasBlocked()){let n=gt.get(this.#t.blockedReason());if(n){if(P.RelatedIssue.hasIssueOfCategory(this.#t,"CrossOriginEmbedderPolicy",P.IssuesManager.IssuesManager.instance())){let m=()=>{b.userMetrics.issuesPanelOpenedFrom(b.UserMetrics.IssueOpener.LEARN_MORE_LINK_COEP),this.#t&&P.RelatedIssue.reveal(this.#t,P.IssuesManager.IssuesManager.instance(),"CrossOriginEmbedderPolicy")};n.blockedDetails&&(n.blockedDetails.reveal=m)}o.push(n)}}function s(n,m){let l=0,g=0,$=[];for(;l<n.length&&g<m.length;)n[l].name<m[g].name?$.push({...n[l++],headerNotSet:!1}):n[l].name>m[g].name?$.push({...m[g++],headerNotSet:!0}):$.push({...m[g++],...n[l++],headerNotSet:!1});for(;l<n.length;)$.push({...n[l++],headerNotSet:!1});for(;g<m.length;)$.push({...m[g++],headerNotSet:!0});return $}this.headerDetails=s(this.headerDetails,o);let r=this.#t.blockedResponseCookies(),a=new Map(r?.map(n=>[n.cookieLine.replace(/\s/g," "),n.blockedReasons]));for(let n of this.headerDetails)if(n.name==="set-cookie"&&n.value){let m=a.get(n.value);m&&(n.setCookieBlockedReasons=m)}this.highlightHeaders(e);let d=this.#t.getAssociatedData(ie);d?this.#e=d:(this.#e=this.headerDetails.map(n=>({name:n.name,value:n.value,originalValue:n.value,valueEditable:this.#s})),this.#a()),this.#u(),this.#t.setAssociatedData(ie,this.#e),this.#r()}#n(){this.#t&&(this.#s=H.NetworkPersistenceManager.NetworkPersistenceManager.isForbiddenNetworkUrl(this.#t.url())?2:0,this.#e=this.headerDetails.map(e=>({name:e.name,value:e.value,originalValue:e.value,valueEditable:this.#s})),this.#a(),this.#t.setAssociatedData(ie,this.#e))}async#u(){if(this.#t){if(this.#o=H.NetworkPersistenceManager.NetworkPersistenceManager.instance().getHeadersUISourceCodeFromUrl(this.#t.url()),!this.#o){this.#n(),this.#r();return}try{let e=await this.#o.requestContentData().then(Be.ContentData.ContentData.contentDataOrEmpty);if(this.#i=JSON.parse(e.text||"[]"),!this.#i.every(H.NetworkPersistenceManager.isHeaderOverride))throw new Error("Type mismatch after parsing");_.Settings.Settings.instance().moduleSetting("persistence-network-overrides-enabled").get()&&this.#s===0&&(this.#s=1);for(let t of this.#e)t.valueEditable=this.#s}catch{console.error("Failed to parse",this.#o?.url()||"source code file","for locally overriding headers."),this.#n()}finally{this.#r()}}}#a(){if(!this.#t||this.#t.originalResponseHeaders.length===0)return;let e=this.#t.originalResponseHeaders.map(s=>({name:x.StringUtilities.toLowerCaseString(s.name),value:s.value.replace(/\s/g," ")}));e.sort(function(s,r){return x.StringUtilities.compare(s.name,r.name)});let t=0,o=0;for(;t<this.headerDetails.length;){let s=this.headerDetails[t].name,r=this.headerDetails[t].value||"",a=this.headerDetails[t].headerNotSet;for(;t<this.headerDetails.length-1&&this.headerDetails[t+1].name===s;)t++,r+=`, ${this.headerDetails[t].value}`;for(;o<e.length&&e[o].name<s;)o++;if(o<e.length&&e[o].name===s){let d=e[o].value;for(;o<e.length-1&&e[o+1].name===s;)o++,d+=`, ${e[o].value}`;o++,s!=="set-cookie"&&!a&&!c(r,d)&&this.#e.filter(n=>c(n.name,s)).forEach(n=>{n.isOverride=!0})}else s!=="set-cookie"&&!a&&this.#e.filter(d=>c(d.name,s)).forEach(d=>{d.isOverride=!0});t++}this.#e.filter(s=>s.name==="set-cookie").forEach(s=>{this.#t?.originalResponseHeaders.find(r=>x.StringUtilities.toLowerCaseString(r.name)==="set-cookie"&&c(r.value,s.value))===void 0&&(s.isOverride=!0)})}#p(e){let t=e.target;if(t.dataset.index===void 0)return;let o=Number(t.dataset.index);M(e.headerName)&&(this.#l(e.headerName,e.headerValue,o),b.userMetrics.actionTaken(b.UserMetrics.Action.HeaderOverrideHeaderEdited))}#d(e){let t=H.NetworkPersistenceManager.NetworkPersistenceManager.instance().rawPathFromUrl(e,!0),o=t.lastIndexOf("/");return _.ParsedURL.ParsedURL.substring(t,o+1)}#c(){this.#o?.setWorkingCopy(JSON.stringify(this.#i,null,2)),this.#o?.commitWorkingCopy()}#m(e,t,o){for(let s=this.#i.length-1;s>=0;s--){let r=this.#i[s];if(r.applyTo!==e)continue;let a=r.headers.findIndex(d=>c(d.name,t)&&c(d.value,o));if(!(a<0)){r.headers.splice(a,1),r.headers.length===0&&this.#i.splice(s,1);return}}}#g(e){let t=e.target;if(t.dataset.index===void 0||!this.#t)return;let o=Number(t.dataset.index),s=this.#d(this.#t.url());this.#m(s,e.headerName,e.headerValue),this.#c(),this.#e[o].isDeleted=!0,this.#r(),b.userMetrics.actionTaken(b.UserMetrics.Action.HeaderOverrideHeaderRemoved)}#l(e,t,o){if(!this.#t)return;this.#t.originalResponseHeaders.length===0&&(this.#t.originalResponseHeaders=this.#t.sortedResponseHeaders.map(l=>({...l})));let s=this.#e[o].name,r=this.#e[o].value;this.#e[o].name=e,this.#e[o].value=t;let a=[];e==="set-cookie"?a.push({name:e,value:t,valueEditable:this.#s}):a=this.#e.filter(l=>c(l.name,e)&&(!c(l.value,l.originalValue)||l.isOverride));let d=this.#d(this.#t.url()),n=null,[m]=this.#i.slice(-1);if(m?.applyTo===d?n=m:(n={applyTo:d,headers:[]},this.#i.push(n)),e==="set-cookie"){let l=n.headers.findIndex(g=>c(g.name,s)&&c(g.value,r));l>=0&&n.headers.splice(l,1)}else n.headers=n.headers.filter(l=>!c(l.name,e));if(!c(this.#e[o].name,s)){for(let l=0;l<n.headers.length;++l)if(c(n.headers[l].name,s)&&c(n.headers[l].value,r)){n.headers.splice(l,1);break}}for(let l of a)n.headers.push({name:l.name,value:l.value||""});n.headers.length===0&&this.#i.pop(),this.#c()}#h(){this.#e.push({name:x.StringUtilities.toLowerCaseString(A.i18n.lockedString("header-name")),value:A.i18n.lockedString("header value"),isOverride:!0,nameEditable:!0,valueEditable:1});let e=this.#e.length-1;this.#l(this.#e[e].name,this.#e[e].value||"",e),this.#r();let t=this.shadow.querySelectorAll("devtools-header-section-row"),[o]=Array.from(t).slice(-1);o?.focus(),b.userMetrics.actionTaken(b.UserMetrics.Action.HeaderOverrideHeaderAdded)}#r(){if(!this.#t)return;let e=this.#e.map((t,o)=>({...this.headerDetails[o],...t,isResponseHeader:!0}));We(z`
      <style>${ke}</style>
      ${e.map((t,o)=>z`
        <devtools-header-section-row
            .data=${{header:t}}
            @headeredited=${this.#p}
            @headerremoved=${this.#g}
            @enableheaderediting=${this.#f}
            data-index=${o}
            jslog=${ae.item("response-header")}
        ></devtools-header-section-row>
      `)}
      ${this.#s===1?z`
        <devtools-button
          class="add-header-button"
          .variant=${"outlined"}
          .iconName=${"plus"}
          @click=${this.#h}
          jslog=${ae.action("add-header").track({click:!0})}>
          ${mt(S.addHeader)}
        </devtools-button>
      `:pt}
    `,this.shadow,{host:this})}async#f(){if(!this.#t)return;b.userMetrics.actionTaken(b.UserMetrics.Action.HeaderOverrideEnableEditingClicked);let e=this.#t.url(),t=H.NetworkPersistenceManager.NetworkPersistenceManager.instance();t.project()?(_.Settings.Settings.instance().moduleSetting("persistence-network-overrides-enabled").set(!0),await t.getOrCreateHeadersUISourceCodeFromUrl(e)):je.InspectorView.InspectorView.instance().displaySelectOverrideFolderInfobar(async()=>{await Ke.SourcesNavigator.OverridesNavigatorView.setupNewWorkspace(),await t.getOrCreateHeadersUISourceCodeFromUrl(e)})}};customElements.define("devtools-response-header-section",ne);var gt=new Map([["coep-frame-resource-needs-coep-header",{name:x.StringUtilities.toLowerCaseString("cross-origin-embedder-policy"),value:null,blockedDetails:{explanation:E(S.toEmbedThisFrameInYourDocument),examples:[{codeSnippet:"Cross-Origin-Embedder-Policy: require-corp"}],link:{url:"https://web.dev/coop-coep/"}}}],["corp-not-same-origin-after-defaulted-to-same-origin-by-coep",{name:x.StringUtilities.toLowerCaseString("cross-origin-resource-policy"),value:null,blockedDetails:{explanation:E(S.toUseThisResourceFromADifferent),examples:[{codeSnippet:"Cross-Origin-Resource-Policy: same-site",comment:E(S.chooseThisOptionIfTheResourceAnd)},{codeSnippet:"Cross-Origin-Resource-Policy: cross-origin",comment:E(S.onlyChooseThisOptionIfAn)}],link:{url:"https://web.dev/coop-coep/"}}}],["coop-sandboxed-iframe-cannot-navigate-to-coop-page",{name:x.StringUtilities.toLowerCaseString("cross-origin-opener-policy"),value:null,headerValueIncorrect:!1,blockedDetails:{explanation:E(S.thisDocumentWasBlockedFrom),examples:[],link:{url:"https://web.dev/coop-coep/"}}}],["corp-not-same-site",{name:x.StringUtilities.toLowerCaseString("cross-origin-resource-policy"),value:null,headerValueIncorrect:!0,blockedDetails:{explanation:E(S.toUseThisResourceFromADifferentSite),examples:[{codeSnippet:"Cross-Origin-Resource-Policy: cross-origin",comment:E(S.onlyChooseThisOptionIfAn)}],link:null}}],["corp-not-same-origin",{name:x.StringUtilities.toLowerCaseString("cross-origin-resource-policy"),value:null,headerValueIncorrect:!0,blockedDetails:{explanation:E(S.toUseThisResourceFromADifferentOrigin),examples:[{codeSnippet:"Cross-Origin-Resource-Policy: same-site",comment:E(S.chooseThisOptionIfTheResourceAnd)},{codeSnippet:"Cross-Origin-Resource-Policy: cross-origin",comment:E(S.onlyChooseThisOptionIfAn)}],link:null}}]]);export{xe as DirectSocketConnectionView,Ee as EditableSpan,Oe as HeaderSectionRow,Ae as RequestHeaderSection,_e as RequestTrustTokensView,Ye as ResponseHeaderSection};
//# sourceMappingURL=components.js.map
