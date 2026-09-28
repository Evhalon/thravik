var Jn=Object.defineProperty;var $=(i,e)=>{for(var t in e)Jn(i,t,{get:e[t],enumerable:!0})};var Ts={};$(Ts,{Breadcrumbs:()=>bi,flattenBreadcrumbs:()=>wi});import*as yi from"./../../../services/trace_bounds/trace_bounds.js";function wi(i){let e=[i],t=i;for(;t.child!==null;){let s=t.child;s!==null&&(e.push(s),t=s)}return e}var bi=class{initialBreadcrumb;activeBreadcrumb;constructor(e){this.initialBreadcrumb={window:e,child:null};let t=this.initialBreadcrumb;for(;t.child!==null;)t=t.child;this.activeBreadcrumb=t}add(e){if(!this.isTraceWindowWithinTraceWindow(e,this.activeBreadcrumb.window))throw new Error("Can not add a breadcrumb that is equal to or is outside of the parent breadcrumb TimeWindow");let t={window:e,child:null};return this.activeBreadcrumb.child=t,this.setActiveBreadcrumb(t,{removeChildBreadcrumbs:!1,updateVisibleWindow:!0}),t}isTraceWindowWithinTraceWindow(e,t){return e.min>=t.min&&e.max<=t.max&&!(e.min===t.min&&e.max===t.max)}setInitialBreadcrumbFromLoadedModifications(e){this.initialBreadcrumb=e;let t=e;for(;t.child!==null;)t=t.child;this.setActiveBreadcrumb(t,{removeChildBreadcrumbs:!1,updateVisibleWindow:!0})}setActiveBreadcrumb(e,t){t.removeChildBreadcrumbs&&(e.child=null),this.activeBreadcrumb=e,yi.TraceBounds.BoundsManager.instance().setMiniMapBounds(e.window),t.updateVisibleWindow&&yi.TraceBounds.BoundsManager.instance().setTimelineVisibleWindow(e.window)}};var Ps={};$(Ps,{BreadcrumbActivatedEvent:()=>qe,BreadcrumbsUI:()=>Ot});import*as je from"./../../../core/i18n/i18n.js";import*as Is from"./../../../models/trace/trace.js";import*as $s from"./../../../ui/components/helpers/helpers.js";import*as Cs from"./../../../ui/legacy/legacy.js";import*as Si from"./../../../ui/lit/lit.js";import*as _t from"./../../../ui/visual_logging/visual_logging.js";var ks=`.breadcrumbs{display:none;align-items:center;height:29px;padding:3px;overflow:scroll hidden}.breadcrumbs::-webkit-scrollbar{display:none}.breadcrumb{padding:2px 6px;border-radius:4px}.breadcrumb:hover{background-color:var(--sys-color-state-hover-on-subtle)}.range{font-size:12px;white-space:nowrap}.active-breadcrumb{font-weight:bold;color:var(--app-color-active-breadcrumb)}
/*# sourceURL=${import.meta.resolve("./breadcrumbsUI.css")} */`;var{render:Zn,html:Bt}=Si,xi={activateBreadcrumb:"Activate breadcrumb",removeChildBreadcrumbs:"Remove child breadcrumbs"},Qn=je.i18n.registerUIStrings("panels/timeline/components/BreadcrumbsUI.ts",xi),Ls=je.i18n.getLocalizedString.bind(void 0,Qn),qe=class i extends Event{breadcrumb;childBreadcrumbsRemoved;static eventName="breadcrumbactivated";constructor(e,t){super(i.eventName),this.breadcrumb=e,this.childBreadcrumbsRemoved=t}},Ot=class extends HTMLElement{#i=this.attachShadow({mode:"open"});#e=null;#t=null;set data(e){this.#e=e.initialBreadcrumb,this.#t=e.activeBreadcrumb,$s.ScheduledRender.scheduleRender(this,this.#l)}#s(e){this.#t=e,this.dispatchEvent(new qe(e))}#n(){let e=this.#i.querySelector(".breadcrumbs");e&&(e.style.display="flex",requestAnimationFrame(()=>{e.scrollWidth-e.clientWidth>0&&requestAnimationFrame(()=>{e.scrollLeft=e.scrollWidth-e.clientWidth})}))}#o(e,t){let s=new Cs.ContextMenu.ContextMenu(e);s.defaultSection().appendItem(Ls(xi.activateBreadcrumb),()=>{this.dispatchEvent(new qe(t))}),s.defaultSection().appendItem(Ls(xi.removeChildBreadcrumbs),()=>{this.dispatchEvent(new qe(t,!0))}),s.show()}#a(e,t){let s=Is.Helpers.Timing.microToMilli(e.window.range);return Bt`
          <div class="breadcrumb" @contextmenu=${o=>this.#o(o,e)} @click=${()=>this.#s(e)}
          jslog=${_t.item("timeline.breadcrumb-select").track({click:!0,resize:!0})}>
           <span class="${e===this.#t?"active-breadcrumb":""} range">
            ${t===0?`Full range (${je.TimeUtilities.preciseMillisToString(s,2)})`:`${je.TimeUtilities.preciseMillisToString(s,2)}`}
            </span>
          </div>
          ${e.child!==null?Bt`
            <devtools-icon name="chevron-right" class="medium">`:""}
      `}#l(){let e=Bt`
      <style>${ks}</style>
      ${this.#e===null?Si.nothing:Bt`<div class="breadcrumbs" jslog=${_t.section("breadcrumbs")}>
        ${wi(this.#e).map((t,s)=>this.#a(t,s))}
      </div>`}
    `;Zn(e,this.#i,{host:this}),this.#e?.child&&this.#n()}};customElements.define("devtools-breadcrumbs-ui",Ot);var Ws={};$(Ws,{CWVMetrics:()=>ht,getFieldMetrics:()=>jt});import*as Li from"./../../../core/i18n/i18n.js";import*as zs from"./../../../core/platform/platform.js";import*as Bs from"./../../../models/crux-manager/crux-manager.js";import*as _ from"./../../../models/trace/trace.js";import"./../../../ui/components/buttons/buttons.js";import*as Os from"./../../../ui/legacy/legacy.js";import*as Q from"./../../../ui/lit/lit.js";import*as _s from"./../../../ui/visual_logging/visual_logging.js";var Ms=`.metrics{display:grid;align-items:end;grid-template-columns:repeat(3,1fr) 0.5fr;row-gap:5px}.row-border{grid-column:1/5;border-top:var(--sys-size-1) solid var(--sys-color-divider)}.row-label{visibility:hidden;font-size:var(--sys-size-7)}.metrics--field .row-label{visibility:visible}.metrics-row{display:contents}.metric{flex:1;user-select:text;cursor:pointer;background:none;border:none;padding:0;display:block;text-align:left}.metric-value{font-size:var(--sys-size-10)}.metric-value-bad{color:var(--app-color-performance-bad)}.metric-value-ok{color:var(--app-color-performance-ok)}.metric-value-good{color:var(--app-color-performance-good)}.metric-score-unclassified{color:var(--sys-color-token-subtle)}.metric-label{font:var(--sys-typescale-body4-medium)}.number-with-unit{white-space:nowrap;.unit{font-size:14px;padding:0 1px}}.field-mismatch-notice{display:grid;grid-template-columns:auto auto;align-items:center;background-color:var(--sys-color-surface3);margin:var(--sys-size-6) 0;border-radius:var(--sys-shape-corner-extra-small);border:var(--sys-size-1) solid var(--sys-color-divider);h3{margin-block:3px;font:var(--sys-typescale-body4-medium);color:var(--sys-color-on-base);padding:var(--sys-size-5) var(--sys-size-6) 0 var(--sys-size-6)}.field-mismatch-notice__body{padding:var(--sys-size-3) var(--sys-size-6) var(--sys-size-5) var(--sys-size-6)}button{padding:5px;background:unset;border:unset;font:inherit;color:var(--sys-color-primary);text-decoration:underline;cursor:pointer}}.soft-nav-badge-row{display:contents}
/*# sourceURL=${import.meta.resolve("./cwvMetrics.css")} */`;import"./../../../ui/components/markdown_view/markdown_view.js";import*as Ds from"./../../../models/trace/trace.js";import*as Es from"./../../../third_party/marked/marked.js";import*as er from"./../../../ui/lit/lit.js";var{html:tr}=er;function Rs(i){return i.activeCategory===Ds.Insights.Types.InsightCategory.ALL||i.activeCategory===i.insightCategory}function Vt(i){let t={tokens:Es.Marked.lexer(i)};return tr`<devtools-markdown-view .data=${t}></devtools-markdown-view>`}import*as Vs from"./insights/insights.js";var Ee=`.metric-value{text-wrap:nowrap}.metric-value.dim{font-weight:var(--ref-typeface-weight-medium)}.metric-value.waiting{color:var(--sys-color-token-subtle)}.metric-value.good{color:var(--app-color-performance-good)}.metric-value.needs-improvement{color:var(--app-color-performance-ok)}.metric-value.poor{color:var(--app-color-performance-bad)}.metric-value.good.dim{color:var(--app-color-performance-good-dim)}.metric-value.needs-improvement.dim{color:var(--app-color-performance-ok-dim)}.metric-value.poor.dim{color:var(--app-color-performance-bad-dim)}.badge{display:inline-flex;align-items:center;justify-content:center;width:fit-content;height:var(--sys-size-8);border-radius:var(--sys-shape-corner-extra-small);padding:0 var(--sys-size-3);border:var(--sys-size-1) solid var(--sys-color-primary);color:var(--sys-color-primary);font-weight:var(--ref-typeface-weight-bold);font-size:var(--sys-size-5);text-align:center;margin-top:var(--sys-size-5);margin-bottom:var(--sys-size-5)}
/*# sourceURL=${import.meta.resolve("./metricValueStyles.css")} */`;var Fs={};$(Fs,{CLS_THRESHOLDS:()=>Je,INP_THRESHOLDS:()=>Ze,LCP_THRESHOLDS:()=>qt,NetworkCategory:()=>S,NumberWithUnit:()=>Ge,colorForNetworkCategory:()=>As,colorForNetworkRequest:()=>Ye,determineCompareRating:()=>gt,isFieldWorseThanLocal:()=>ki,networkResourceCategory:()=>Wt,rateMetric:()=>xe,renderMetricValue:()=>re});import*as Xe from"./../../../core/i18n/i18n.js";import*as Ke from"./../../../core/platform/platform.js";import*as Hs from"./../../../ui/legacy/theme_support/theme_support.js";import*as Ns from"./../../../ui/visual_logging/visual_logging.js";var Ti={fms:"{PH1}[ms]()",fs:"{PH1}[s]()"},ir=Xe.i18n.registerUIStrings("panels/timeline/components/Utils.ts",Ti),Us=Xe.i18n.getLocalizedString.bind(void 0,ir),S;(function(i){i.DOC="Doc",i.CSS="CSS",i.JS="JS",i.FONT="Font",i.IMG="Img",i.MEDIA="Media",i.WASM="Wasm",i.OTHER="Other"})(S||(S={}));function Wt(i){let{mimeType:e}=i.args.data;switch(i.args.data.resourceType){case"Document":return S.DOC;case"Stylesheet":return S.CSS;case"Image":return S.IMG;case"Media":return S.MEDIA;case"Font":return S.FONT;case"Script":case"WebSocket":return S.JS;default:return e===void 0?S.OTHER:e.endsWith("/css")?S.CSS:e.endsWith("javascript")?S.JS:e.startsWith("image/")?S.IMG:e.startsWith("audio/")||e.startsWith("video/")?S.MEDIA:e.startsWith("font/")||e.includes("font-")?S.FONT:e==="application/wasm"?S.WASM:e.startsWith("text/")?S.DOC:S.OTHER}}function As(i){let e="--app-color-system";switch(i){case S.DOC:e="--app-color-doc";break;case S.JS:e="--app-color-scripting";break;case S.CSS:e="--app-color-css";break;case S.IMG:e="--app-color-image";break;case S.MEDIA:e="--app-color-media";break;case S.FONT:e="--app-color-font";break;case S.WASM:e="--app-color-wasm";break;case S.OTHER:default:e="--app-color-system";break}return Hs.ThemeSupport.instance().getComputedValue(e)}function Ye(i){let e=Wt(i);return As(e)}var qt=[2500,4e3],Je=[.1,.25],Ze=[200,500];function xe(i,e){return i<=e[0]?"good":i<=e[1]?"needs-improvement":"poor"}function re(i,e,t,s,o){let n=document.createElement("span");if(n.classList.add("metric-value"),e===void 0)return n.classList.add("waiting"),n.textContent="-",n;n.textContent=s(e);let r=xe(e,t);return n.classList.add(r),n.setAttribute("jslog",`${Ns.section(i)}`),o?.dim&&n.classList.add("dim"),n}var Ge;(function(i){function e(o){let n=o.indexOf("["),r=n!==-1&&o.indexOf("]",n),a=r&&o.indexOf("(",r),l=a&&o.indexOf(")",a);if(!l||l===-1)return null;let m=o.substring(0,n),p=o.substring(n+1,r),u=o.substring(l+1);return{firstPart:m,unitPart:p,lastPart:u}}i.parse=e;function t(o){let n=document.createElement("span");n.classList.add("number-with-unit");let r=Ke.Timing.microSecondsToMilliSeconds(o),a=Ke.Timing.milliSecondsToSeconds(r),l=Us(Ti.fs,{PH1:a.toFixed(2)}),m=e(l);if(!m)return n.textContent=Xe.TimeUtilities.formatMicroSecondsAsSeconds(o),{text:l,element:n};let{firstPart:p,unitPart:u,lastPart:h}=m;return p&&n.append(p),n.createChild("span","unit").textContent=u,h&&n.append(h),{text:n.textContent,element:n}}i.formatMicroSecondsAsSeconds=t;function s(o,n=0){let r=document.createElement("span");r.classList.add("number-with-unit");let a=Ke.Timing.microSecondsToMilliSeconds(o),l=Us(Ti.fms,{PH1:a.toFixed(n)}),m=e(l);if(!m)return r.textContent=Xe.TimeUtilities.formatMicroSecondsAsMillisFixed(o),{text:l,element:r};let{firstPart:p,unitPart:u,lastPart:h}=m;return p&&r.append(p),r.createChild("span","unit").textContent=u,h&&r.append(h),{text:r.textContent,element:r}}i.formatMicroSecondsAsMillisFixed=s})(Ge||(Ge={}));function gt(i,e,t){let s,o;switch(i){case"LCP":s=qt,o=1e3;break;case"CLS":s=Je,o=.1;break;case"INP":s=Ze,o=200;break;default:Ke.assertNever(i,`Unknown metric: ${i}`)}let n=xe(e,s),r=xe(t,s);return n==="good"&&r==="good"?"similar":e-t>o?"worse":t-e>o?"better":"similar"}function ki(i,e){return i.lcp!==void 0&&e.lcp!==void 0&&gt("LCP",i.lcp,e.lcp)==="better"||i.inp!==void 0&&e.inp!==void 0&&gt("LCP",i.inp,e.inp)==="better"}var{html:ge}=Q.StaticHtml,he={metricScore:"{PH1}: {PH2} {PH3} score",metricScoreUnavailable:"{PH1}: unavailable",fieldScoreLabel:"Field ({PH1})",urlOption:"URL",originOption:"Origin",dismissTitle:"Dismiss",fieldMismatchTitle:"Field & local metrics mismatch",fieldMismatchNotice:"There are many reasons why local and field metrics [may not match](https://web.dev/articles/lab-and-field-data-differences). Adjust [throttling settings and device emulation](https://developer.chrome.com/docs/devtools/device-mode) to analyze traces more similar to the average user\u2019s environment."},sr=Li.i18n.registerUIStrings("panels/timeline/components/CWVMetrics.ts",he),Se=Li.i18n.getLocalizedString.bind(void 0,sr);function or(i,e){if(!i||!e)return null;let t=i.insights?.get(e);if(!t)return null;let s=_.Insights.Common.getLCP(t),o=_.Insights.Common.getCLS(t),n=_.Insights.Common.getINP(t);return{lcp:s,cls:o,inp:n}}function jt(i,e){if(!i||!i.metadata?.cruxFieldData||!e)return null;let t=i.insights?.get(e);if(!t)return null;let s=null;try{s=Bs.CrUXManager.instance().getSelectedScope()}catch{}let o=_.Insights.Common.getFieldMetricsForInsightSet(t,i.metadata,s);return o||null}var nr=(i,e,t)=>{let{parsedTrace:s,insightSetKey:o,didDismissFieldMismatchNotice:n,onDismisFieldMismatchNotice:r,onClickMetric:a}=i,l=or(s,o),m=jt(s,o),p={lcp:l?.lcp?.value!==void 0?_.Helpers.Timing.microToMilli(l?.lcp.value):void 0,inp:l?.inp?.value!==void 0?_.Helpers.Timing.microToMilli(l?.inp.value):void 0},u=m&&{lcp:m.lcp?.value!==void 0?_.Helpers.Timing.microToMilli(m.lcp.value):void 0,inp:m.inp?.value!==void 0?_.Helpers.Timing.microToMilli(m.inp.value):void 0},h=!n&&!!u&&ki(p,u);function f(oe,ne,zt){let Me,De,we;if(ne===null)Me=De="-",we="unclassified";else if(oe==="LCP"){let ut=ne,{text:fi,element:vi}=Ge.formatMicroSecondsAsSeconds(ut);Me=fi,De=vi,we=_.Handlers.ModelHandlers.PageLoadMetrics.scoreClassificationForLargestContentfulPaint(ut)}else if(oe==="CLS")Me=De=ne?ne.toFixed(2):"0",we=_.Handlers.ModelHandlers.LayoutShifts.scoreClassificationForLayoutShift(ne);else if(oe==="INP"){let ut=ne,{text:fi,element:vi}=Ge.formatMicroSecondsAsMillisFixed(ut);Me=fi,De=vi,we=_.Handlers.ModelHandlers.UserInteractions.scoreClassificationForInteractionToNextPaint(ut)}else zs.TypeScriptUtilities.assertNever(oe,`Unexpected metric ${oe}`);let pt=ne!==null?Se(he.metricScore,{PH1:oe,PH2:Me,PH3:we}):Se(he.metricScoreUnavailable,{PH1:oe});return ge`
      <button class="metric"
        @click=${zt?a.bind(zt):null}
        title=${pt}
        aria-label=${pt}
      >
        <div class="metric-value metric-value-${we}">${De}</div>
      </button>
    `}let T=f("LCP",l?.lcp?.value??null,l?.lcp?.event??null),y=f("INP",l?.inp?.value??null,l?.inp?.event??null),j=f("CLS",l?.cls?.value??null,l?.cls?.worstClusterEvent??null),M=s?.insights?.get(o??"")?.navigation,b=M&&_.Types.Events.isSoftNavigationStart(M)?ge`
    <div class="metrics-row soft-nav-badge-row">
      <span class="badge">SOFT NAV</span>
    </div>
  `:Q.nothing,G=ge`
    <div class="metrics-row">
      <span>${T}</span>
      <span>${y}</span>
      <span>${j}</span>
      <span class="row-label">Local</span>
    </div>
    ${m?Q.nothing:b}
    ${!m&&i.skipBottomBorder?Q.nothing:ge`<span class="row-border"></span>`}
  `,mt;if(m){let{lcp:oe,inp:ne,cls:zt}=m,Me=f("LCP",oe?.value??null,null),De=f("INP",ne?.value??null,null),we=f("CLS",zt?.value??null,null),pt=Se(he.originOption);(oe?.pageScope==="url"||ne?.pageScope==="url")&&(pt=Se(he.urlOption)),mt=ge`
      <div class="metrics-row">
        <span>${Me}</span>
        <span>${De}</span>
        <span>${we}</span>
        <span class="row-label">${Se(he.fieldScoreLabel,{PH1:pt})}</span>
      </div>
      ${b}
      ${i.skipBottomBorder?Q.nothing:ge`<span class="row-border"></span>`}
    `}let Ss;h&&(Ss=ge`
      <div class="field-mismatch-notice" jslog=${_s.section("timeline.insights.field-mismatch")}>
        <h3>${Se(he.fieldMismatchTitle)}</h3>
        <devtools-button
          title=${Se(he.dismissTitle)}
          .iconName=${"cross"}
          .variant=${"icon"}
          .jslogContext=${"timeline.insights.dismiss-field-mismatch"}
          @click=${r}
        ></devtools-button>
        <div class="field-mismatch-notice__body">${Vt(Se(he.fieldMismatchNotice))}</div>
      </div>
    `);let Gn={metrics:!0,"metrics--field":!!mt},Yn=ge`<div class=${Q.Directives.classMap(Gn)}>
    <div class="metrics-row">
      <span class="metric-label">LCP</span>
      <span class="metric-label">INP</span>
      <span class="metric-label">CLS</span>
      <span class="row-label"></span>
    </div>
    ${G}
    ${mt}
  </div>`;Q.render(ge`
    <style>${Ms}</style>
    <style>${Ee}</style>
    ${Yn}
    ${Ss}
  `,t)},ht=class extends Os.Widget.Widget{#i;#e={insightSetKey:null,parsedTrace:null};#t=!1;#s=!1;constructor(e,t=nr){super(e,{useShadowDom:!0}),this.#i=t}set data(e){this.#e=e,this.requestUpdate()}get skipBottomBorder(){return this.#s}set skipBottomBorder(e){e!==this.#s&&(this.#s=e,this.requestUpdate())}#n(e){this.element.dispatchEvent(new Vs.EventRef.EventReferenceClick(e))}#o(){this.#t=!0,this.requestUpdate()}performUpdate(){let{parsedTrace:e,insightSetKey:t}=this.#e;if(!e?.insights||!t||!(e.insights instanceof Map)||!e.insights.get(t))return;let o={parsedTrace:e,insightSetKey:t,didDismissFieldMismatchNotice:this.#t,onDismisFieldMismatchNotice:this.#o.bind(this),onClickMetric:this.#n.bind(this),skipBottomBorder:this.#s};this.#i(o,void 0,this.contentElement)}};var js={};$(js,{buildRowsForWebSocketEvent:()=>ar,buildWarningElementsForEvent:()=>rr,generateInvalidationsList:()=>lr});import*as ke from"./../../../core/i18n/i18n.js";import*as qs from"./../../../core/platform/platform.js";import*as ee from"./../../../models/trace/trace.js";import*as Kt from"./../../../ui/i18n/i18n.js";import{Link as Ii}from"./../../../ui/kit/kit.js";var Y={forcedReflow:"Forced reflow",sIsALikelyPerformanceBottleneck:"{PH1} is a likely performance bottleneck.",idleCallbackExecutionExtended:"Idle callback execution extended beyond deadline by {PH1}",sTookS:"{PH1} took {PH2}.",longTask:"Long task",longInteractionINP:"Long interaction",sIsLikelyPoorPageResponsiveness:"{PH1} is indicating poor page responsiveness.",websocketProtocol:"WebSocket protocol",webSocketBytes:"{PH1} byte(s)",webSocketDataLength:"Data length"},Xt=ke.i18n.registerUIStrings("panels/timeline/components/DetailsView.ts",Y),Te=ke.i18n.getLocalizedString.bind(void 0,Xt);function rr(i,e){let t=e.data.Warnings.perEvent.get(i),s=[];if(!t)return s;for(let o of t){let n=ee.Helpers.Timing.microToMilli(ee.Types.Timing.Micro(i.dur||0)),r=document.createElement("span");switch(o){case"FORCED_REFLOW":{let a=Ii.create("https://developers.google.com/web/fundamentals/performance/rendering/avoid-large-complex-layouts-and-layout-thrashing#avoid-forced-synchronous-layouts",Te(Y.forcedReflow),void 0,"forced-reflow");r.appendChild(Kt.getFormatLocalizedString(Xt,Y.sIsALikelyPerformanceBottleneck,{PH1:a}));break}case"IDLE_CALLBACK_OVER_TIME":{if(!ee.Types.Events.isFireIdleCallback(i))break;let a=ke.TimeUtilities.millisToString((n||0)-i.args.data.allottedMilliseconds,!0);r.textContent=Te(Y.idleCallbackExecutionExtended,{PH1:a});break}case"LONG_TASK":{let a=Ii.create("https://web.dev/optimize-long-tasks/",Te(Y.longTask),void 0,"long-tasks");r.appendChild(Kt.getFormatLocalizedString(Xt,Y.sTookS,{PH1:a,PH2:ke.TimeUtilities.millisToString(n||0,!0)}));break}case"LONG_INTERACTION":{let a=Ii.create("https://web.dev/inp",Te(Y.longInteractionINP),void 0,"long-interaction");r.appendChild(Kt.getFormatLocalizedString(Xt,Y.sIsLikelyPoorPageResponsiveness,{PH1:a}));break}default:qs.assertNever(o,`Unhandled warning type ${o}`)}s.push(r)}return s}function ar(i,e){let t=[],s=e.data.Initiators.eventToInitiator.get(i);return s&&ee.Types.Events.isWebSocketCreate(s)?(t.push({key:ke.i18n.lockedString("URL"),value:s.args.data.url}),s.args.data.websocketProtocol&&t.push({key:Te(Y.websocketProtocol),value:s.args.data.websocketProtocol})):ee.Types.Events.isWebSocketCreate(i)&&(t.push({key:ke.i18n.lockedString("URL"),value:i.args.data.url}),i.args.data.websocketProtocol&&t.push({key:Te(Y.websocketProtocol),value:i.args.data.websocketProtocol})),ee.Types.Events.isWebSocketTransfer(i)&&i.args.data.dataLength&&t.push({key:Te(Y.webSocketDataLength),value:`${Te(Y.webSocketBytes,{PH1:i.args.data.dataLength})}`}),t}function lr(i){let e={},t=new Set;for(let s of i){t.add(s.args.data.nodeId);let o=s.args.data.reason||"unknown";if(o==="unknown"&&ee.Types.Events.isScheduleStyleInvalidationTracking(s)&&s.args.data.invalidatedSelectorId)switch(s.args.data.invalidatedSelectorId){case"attribute":o="Attribute",s.args.data.changedAttribute&&(o+=` (${s.args.data.changedAttribute})`);break;case"class":o="Class",s.args.data.changedClass&&(o+=` (${s.args.data.changedClass})`);break;case"id":o="Id",s.args.data.changedId&&(o+=` (${s.args.data.changedId})`);break}if(o==="PseudoClass"&&ee.Types.Events.isStyleRecalcInvalidationTracking(s)&&s.args.data.extraData&&(o+=s.args.data.extraData),o==="Attribute"&&ee.Types.Events.isStyleRecalcInvalidationTracking(s)&&s.args.data.extraData&&(o+=` (${s.args.data.extraData})`),o==="StyleInvalidator")continue;let n=e[o]||[];n.push(s),e[o]=n}return{groupedByReason:e,backendNodeIds:t}}var Gs={};$(Gs,{ExportTraceOptions:()=>Yt});import"./../../../ui/kit/kit.js";import"./../../../ui/components/tooltips/tooltips.js";import"./../../../ui/components/buttons/buttons.js";import*as ft from"./../../../core/common/common.js";import*as Jt from"./../../../core/host/host.js";import*as Ci from"./../../../core/i18n/i18n.js";import"./../../../ui/components/buttons/buttons.js";import"./../../../ui/components/dialogs/dialogs.js";import*as $i from"./../../../ui/components/helpers/helpers.js";import*as Re from"./../../../ui/legacy/legacy.js";import*as ae from"./../../../ui/lit/lit.js";var Ks=`.export-trace-options-content{max-width:var(--sys-size-36)}.export-trace-options-row{display:flex;devtools-checkbox{flex:auto}devtools-button{height:24px}.export-trace-explanation{flex:1;min-width:var(--sys-size-25)}}.export-trace-options-row-last{align-items:center}.info-tooltip-container{max-width:var(--sys-size-28);white-space:normal}devtools-link{color:var(--sys-color-primary);text-decoration-line:underline}
/*# sourceURL=${import.meta.resolve("./exportTraceOptions.css")} */`;var{html:Gt}=ae,E={exportTraceOptionsDialogTitle:"Save performance trace ",showExportTraceOptionsDialogTitle:"Save trace\u2026",includeResourceContent:"Include resource content",includeSourcemap:"Include script source maps",includeAnnotations:"Include annotations",shouldCompress:"Compress with gzip",explanation:"Explanation",saveButtonTitle:"Save",resourceContentPrivacyInfo:"Includes the full content of all loaded HTML, CSS, and scripts (except extensions).",sourceMapsContentPrivacyInfo:"Includes available source maps, which may expose authored code.",moreInfoLabel:"Additional information:"},cr=Ci.i18n.registerUIStrings("panels/timeline/components/ExportTraceOptions.ts",E),H=Ci.i18n.getLocalizedString.bind(void 0,cr),Xs=new Set(["resource-content","script-source-maps"]),Yt=class i extends HTMLElement{#i=this.attachShadow({mode:"open"});#e=null;static#t="export-performance-trace-include-annotations";static#s="export-performance-trace-include-resources";static#n="export-performance-trace-include-sourcemaps";static#o="export-performance-trace-should-compress";#a=ft.Settings.Settings.instance().createSetting(i.#t,!0,"Session");#l=ft.Settings.Settings.instance().createSetting(i.#s,!1,"Session");#d=ft.Settings.Settings.instance().createSetting(i.#n,!1,"Session");#c=ft.Settings.Settings.instance().createSetting(i.#o,!0,"Synced");#r={dialogState:"collapsed",includeAnnotations:this.#a.get(),includeResourceContent:this.#l.get(),includeSourceMaps:this.#d.get(),shouldCompress:this.#c.get()};#f=Re.UIUtils.CheckboxLabel.create(H(E.includeAnnotations),this.#r.includeAnnotations,void 0,"timeline.export-trace-options.annotations-checkbox");#u=Re.UIUtils.CheckboxLabel.create(H(E.includeResourceContent),this.#r.includeResourceContent,void 0,"timeline.export-trace-options.resource-content-checkbox");#p=Re.UIUtils.CheckboxLabel.create(H(E.includeSourcemap),this.#r.includeSourceMaps,void 0,"timeline.export-trace-options.source-maps-checkbox");#h=Re.UIUtils.CheckboxLabel.create(H(E.shouldCompress),this.#r.shouldCompress,void 0,"timeline.export-trace-options.should-compress-checkbox");set data(e){this.#e=e,this.#v()}set state(e){this.#r=e,this.#a.set(e.includeAnnotations),this.#l.set(e.includeResourceContent),this.#d.set(e.includeSourceMaps),this.#c.set(e.shouldCompress),this.#v()}get state(){return this.#r}updateContentVisibility(e){this.state={...this.#r,displayAnnotationsCheckbox:e.annotationsExist,displayResourceContentCheckbox:!0,displaySourceMapsCheckbox:!0}}#v(){$i.ScheduledRender.scheduleRender(this,this.#x)}#y(e,t){let s=Object.assign({},this.#r,{dialogState:"expanded"});switch(e){case this.#f:{s.includeAnnotations=t;break}case this.#u:{s.includeResourceContent=t,s.includeResourceContent||(s.includeSourceMaps=!1);break}case this.#p:{s.includeSourceMaps=t;break}case this.#h:{s.shouldCompress=t;break}}this.state=s}#b(e){return e==="script-source-maps"?H(E.moreInfoLabel)+" "+H(E.sourceMapsContentPrivacyInfo):e==="resource-content"?H(E.moreInfoLabel)+" "+H(E.resourceContentPrivacyInfo):""}#g(e,t,s,o){return Re.Tooltip.Tooltip.install(t,s),t.ariaLabel=s,t.checked=o,t.addEventListener("change",this.#y.bind(this,t,!o),!1),this.#p.disabled=!this.#r.includeResourceContent,Gt`
        <div class='export-trace-options-row'>
          ${t}

          ${Xs.has(e)?Gt`
            <devtools-button
              aria-details=${`export-trace-tooltip-${e}`}
              .accessibleLabel=${this.#b(e)}
              class="pen-icon"
              .iconName=${"info"}
              .variant=${"icon"}
              ></devtools-button>
            `:ae.nothing}
        </div>
      `}#w(e){return Xs.has(e)?Gt`
    <devtools-tooltip
      variant="rich"
      id=${`export-trace-tooltip-${e}`}
    >
      <div class="info-tooltip-container">
      <p>
        ${e==="resource-content"?H(E.resourceContentPrivacyInfo):ae.nothing}
        ${e==="script-source-maps"?H(E.sourceMapsContentPrivacyInfo):ae.nothing}
      </p>
      </div>
    </devtools-tooltip>`:ae.nothing}#x(){if(!$i.ScheduledRender.isScheduledRender(this))throw new Error("Export trace options dialog render was not scheduled");let e=Gt`
      <style>${Ks}</style>
      <devtools-button-dialog class="export-trace-dialog"
      @click=${this.#m.bind(this)}
      .data=${{openOnRender:!1,jslogContext:"timeline.export-trace-options",variant:"toolbar",iconName:"download",disabled:!this.#e?.buttonEnabled,iconTitle:H(E.showExportTraceOptionsDialogTitle),horizontalAlignment:"auto",closeButton:!1,dialogTitle:H(E.exportTraceOptionsDialogTitle),state:this.#r.dialogState,closeOnESC:!0}}>
        <div class='export-trace-options-content'>

          ${this.#r.displayAnnotationsCheckbox?this.#g("annotations",this.#f,H(E.includeAnnotations),this.#r.includeAnnotations):""}
          ${this.#r.displayResourceContentCheckbox?this.#g("resource-content",this.#u,H(E.includeResourceContent),this.#r.includeResourceContent):""}
          ${this.#r.displayResourceContentCheckbox&&this.#r.displaySourceMapsCheckbox?this.#g("script-source-maps",this.#p,H(E.includeSourcemap),this.#r.includeSourceMaps):""}
          ${this.#g("compress-with-gzip",this.#h,H(E.shouldCompress),this.#r.shouldCompress)}
          <div class='export-trace-options-row export-trace-options-row-last'>
            <div class="export-trace-explanation">
              <devtools-link
                href="https://developer.chrome.com/docs/devtools/performance/save-trace"
                class=devtools-link
                .jslogContext=${"save-trace-explanation"}>
                  ${H(E.explanation)}
              </devtools-link>
            </div>
            <devtools-button
                  class="setup-button"
                  data-export-button
                  @click=${this.#T.bind(this)}
                  .data=${{variant:"primary",title:H(E.saveButtonTitle)}}
                >${H(E.saveButtonTitle)}</devtools-button>
                </div>
          ${this.#r.displayResourceContentCheckbox?this.#w("resource-content"):ae.nothing}
          ${this.#r.displayResourceContentCheckbox&&this.#r.displaySourceMapsCheckbox?this.#w("script-source-maps"):ae.nothing}
        </div>
      </devtools-button-dialog>
    `;ae.render(e,this.#i,{host:this})}async#m(){this.state=Object.assign({},this.#r,{dialogState:"expanded"})}async#S(){await this.#e?.onExport({includeResourceContent:this.#r.includeResourceContent,includeSourceMaps:this.#r.includeSourceMaps,addModifications:this.#r.includeAnnotations,shouldCompress:this.#r.shouldCompress}),Jt.userMetrics.actionTaken(Jt.UserMetrics.Action.PerfPanelTraceExported)}async#T(){await this.#S(),this.state=Object.assign({},this.#r,{dialogState:"collapsed"})}};customElements.define("devtools-perf-export-trace-options",Yt);var ao={};$(ao,{FieldSettingsDialog:()=>ei,ShowDialog:()=>Qt});import"./../../../ui/kit/kit.js";import*as ti from"./../../../core/i18n/i18n.js";import*as Zt from"./../../../models/crux-manager/crux-manager.js";import"./../../../ui/components/buttons/buttons.js";import"./../../../ui/components/dialogs/dialogs.js";import*as fe from"./../../../ui/components/helpers/helpers.js";import*as ii from"./../../../ui/components/input/input.js";import*as oo from"./../../../ui/i18n/i18n.js";import*as no from"./../../../ui/legacy/legacy.js";import*as yt from"./../../../ui/lit/lit.js";import*as He from"./../../../ui/visual_logging/visual_logging.js";var Ys=`:host{display:block}:host *{box-sizing:border-box}devtools-dialog{--override-transparent:color-mix(in srgb,var(--color-background) 80%,transparent)}.section-title{font-size:var(--sys-typescale-headline5-size);line-height:var(--sys-typescale-headline5-line-height);font-weight:var(--ref-typeface-weight-medium);margin:0}.privacy-disclosure{margin:8px 0}.url-override{margin:8px 0;display:flex;align-items:center;overflow:hidden;text-overflow:ellipsis;max-width:max-content}details > summary{font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);font-weight:var(--ref-typeface-weight-medium)}.content{max-width:360px;box-sizing:border-box}.open-button-section{display:flex;flex-direction:row}.origin-mapping-grid{border:1px solid var(--sys-color-divider);margin-top:8px}.origin-mapping-description{margin-bottom:8px}.origin-mapping-button-section{display:flex;flex-direction:column;align-items:center;margin-top:var(--sys-size-6)}.config-button{margin-left:auto}.advanced-section-contents{margin:4px 0 14px}.buttons-section{display:flex;justify-content:space-between;margin-top:var(--sys-size-6);margin-bottom:var(--sys-size-2);devtools-button.enable{float:right}}input[type="checkbox"]{height:12px;width:12px;min-height:12px;min-width:12px;margin:6px}input[type="text"][disabled]{color:var(--sys-color-state-disabled)}.warning{margin:2px 8px;color:var(--color-error-text)}devtools-link{color:var(--sys-color-primary);text-decoration-line:underline}.divider{margin:10px 0;border:none;border-top:1px solid var(--sys-color-divider)}
/*# sourceURL=${import.meta.resolve("./fieldSettingsDialog.css")} */`;var so={};$(so,{DEFAULT_VIEW:()=>io,OriginMap:()=>tt});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/components/data_grid/data_grid.js";import*as Mi from"./../../../core/i18n/i18n.js";import*as Zs from"./../../../core/sdk/sdk.js";import*as Qe from"./../../../models/crux-manager/crux-manager.js";import*as Qs from"./../../../ui/components/render_coordinator/render_coordinator.js";import*as eo from"./../../../ui/legacy/legacy.js";import*as J from"./../../../ui/lit/lit.js";var Js=`.origin-warning-icon{width:16px;height:16px;margin-right:4px;color:var(--icon-warning)}.origin{text-overflow:ellipsis;overflow-x:hidden}.error-message{color:var(--sys-color-error);margin-top:8px;font-weight:var(--ref-typeface-weight-medium);white-space:pre-wrap}
/*# sourceURL=${import.meta.resolve("./originMap.css")} */`;var{html:vt}=J,Ue={developmentOrigin:"Development origin",productionOrigin:"Production origin",invalidOrigin:'"{PH1}" is not a valid origin or URL.',alreadyMapped:'"{PH1}" is already mapped to a production origin.',pageHasNoData:"The Chrome UX Report does not have sufficient real user data for this page."},dr=Mi.i18n.registerUIStrings("panels/timeline/components/OriginMap.ts",Ue),et=Mi.i18n.getLocalizedString.bind(void 0,dr),Pi="developmentOrigin",to="productionOrigin";function mr(i,e){return Qs.write(async()=>{if(!i.isCrUXEnabled)return J.nothing;let t=await i.getFieldDataForPage(e);return Object.entries(t).some(([o,n])=>o==="warnings"?!1:!!n)?J.nothing:vt`
      <devtools-icon
        class="origin-warning-icon"
        name="warning-filled"
        title=${et(Ue.pageHasNoData)}
      ></devtools-icon>
    `})}function pr(i,e,t){let s=J.Directives.until(mr(i,e.productionOrigin));return vt`
    <tr data-index=${t} @edit=${i.onCommitEdit} @delete=${i.onRemoveItemRequested}>
      <td data-value=${e.developmentOrigin}>
        <div class="origin" title=${e.developmentOrigin}>${e.developmentOrigin}</div>
      </td>
      <td data-value=${e.productionOrigin}>
        ${s}
        <div class="origin" title=${e.productionOrigin}>${e.productionOrigin}</div>
      </td>
    </tr>
  `}var io=(i,e,t)=>{if(!i.prefillDevelopmentOrigin&&i.mappings.length===0){J.render(J.nothing,t);return}J.render(vt`
    <devtools-data-grid striped inline
        @click=${s=>{s.stopPropagation()}}
        @create=${i.onCreate}>
      <table>
        <tr>
          <th id=${Pi} editable weight="1">${et(Ue.developmentOrigin)}</th>
          <th id=${to} editable weight="1">${et(Ue.productionOrigin)}</th>
        </tr>
        ${i.mappings.map((s,o)=>pr(i,s,o))}
        ${i.prefillDevelopmentOrigin?vt`
          <tr placeholder>
            <td>${i.prefillDevelopmentOrigin}</td>
            <td></td>
          </tr>`:J.nothing}
      </table>
    </devtools-data-grid>
    ${i.errorMessage?vt`<div class="error-message">${i.errorMessage}</div>`:J.nothing}
  `,t)},tt=class extends eo.Widget.VBox{#i;#e="";#t="";constructor(e,t=io){super(e,{useShadowDom:!0}),this.#i=t,this.registerRequiredCSS(Js),Qe.CrUXManager.instance().getConfigSetting().addChangeListener(this.requestUpdate,this),this.requestUpdate()}performUpdate(){let e={mappings:this.#s(),prefillDevelopmentOrigin:this.#t,errorMessage:this.#e,isCrUXEnabled:Qe.CrUXManager.instance().isEnabled(),getFieldDataForPage:t=>Qe.CrUXManager.instance().getFieldDataForPage(t),onCommitEdit:this.#l.bind(this),onRemoveItemRequested:this.#a.bind(this),onCreate:this.#r.bind(this)};this.#i(e,void 0,this.contentElement)}#s(){return Qe.CrUXManager.instance().getConfigSetting().get().originMappings||[]}#n(e){let t=Qe.CrUXManager.instance().getConfigSetting(),s={...t.get()};s.originMappings=e,t.set(s)}#o(e){try{return new URL(e).origin}catch{return null}}startCreation(){let t=Zs.TargetManager.TargetManager.instance().inspectedURL(),s=this.#o(t)||"";this.#t=s,this.requestUpdate()}#a(e){let t=e.currentTarget,s=Number.parseInt(t.dataset.index??"-1",10);if(s<0)return;let o=this.#s();o.splice(s,1),this.#n(o)}#l(e){let t=e.currentTarget,s=Number.parseInt(t.dataset.index??"-1",10);if(s<0)return;let o=this.#s(),n=o[s],r=e.detail.columnId===Pi,a=null;if(r?a=this.#d(e.detail.newText,s):a=this.#c(e.detail.newText),a){this.#e=a,this.requestUpdate();return}this.#e="",r?n.developmentOrigin=this.#o(e.detail.newText)||"":n.productionOrigin=this.#o(e.detail.newText)||"",this.#n(o)}#d(e,t){let s=this.#o(e);if(!s)return et(Ue.invalidOrigin,{PH1:e});let o=this.#s();for(let n=0;n<o.length;++n){if(n===t)continue;if(o[n].developmentOrigin===s)return et(Ue.alreadyMapped,{PH1:s})}return null}#c(e){return this.#o(e)?null:et(Ue.invalidOrigin,{PH1:e})}#r(e){let t=e.detail[Pi]??"",s=e.detail[to]??"";if(!t&&!s||t===this.#t&&!s){this.#t="",this.#e="",this.requestUpdate();return}let o=[this.#d(t),this.#c(s)].filter(Boolean);if(o.length>0){this.#e=o.join(`
`),this.requestUpdate();return}this.#e="",this.#t="";let n=this.#s();n.push({developmentOrigin:this.#o(t)||"",productionOrigin:this.#o(s)||""}),this.#n(n)}};var C={setUp:"Set up",configure:"Configure",ok:"Ok",optOut:"Opt out",cancel:"Cancel",onlyFetchFieldData:"Always show field metrics for the below URL",url:"URL",doesNotHaveSufficientData:"The Chrome UX Report does not have sufficient real-world speed data for this page.",configureFieldData:"Configure field metrics fetching",fetchAggregated:"Fetch aggregated field metrics from the {PH1} to help you contextualize local measurements with what real users experience on the site.",privacyDisclosure:"Privacy disclosure",whenPerformanceIsShown:"When DevTools is open, the URLs you visit will be sent to Google to query field metrics. These requests are not tied to your Google account.",advanced:"Advanced",mapDevelopmentOrigins:"Set a development origin to automatically get relevant field metrics for its production origin.",new:"New",invalidOrigin:'"{PH1}" is not a valid origin or URL.'},ro=ti.i18n.registerUIStrings("panels/timeline/components/FieldSettingsDialog.ts",C),D=ti.i18n.getLocalizedString.bind(void 0,ro),{html:Le,nothing:ur,Directives:{ifDefined:gr}}=yt,{widget:hr,widgetRef:fr}=no.Widget,Qt=class i extends Event{static eventName="showdialog";constructor(){super(i.eventName)}},ei=class extends HTMLElement{#i=this.attachShadow({mode:"open"});#e;#t=Zt.CrUXManager.instance().getConfigSetting();#s="";#n=!1;#o="";#a;constructor(){super();let e=Zt.CrUXManager.instance();this.#t=e.getConfigSetting(),this.#l(),this.#m()}#l(){let e=this.#t.get();this.#s=e.override||"",this.#n=e.overrideEnabled||!1,this.#o=""}#d(e){let t=this.#t.get();this.#t.set({...t,enabled:e,override:this.#s,overrideEnabled:this.#n})}#c(){fe.ScheduledRender.scheduleRender(this,this.#m)}async#r(e){let s=await Zt.CrUXManager.instance().getFieldDataForPage(e);return Object.entries(s).some(([o,n])=>o==="warnings"?!1:!!n)}async#f(e){if(e&&this.#n){if(!this.#w(this.#s)){this.#o=D(C.invalidOrigin,{PH1:this.#s}),fe.ScheduledRender.scheduleRender(this,this.#m);return}if(!await this.#r(this.#s)){this.#o=D(C.doesNotHaveSufficientData),fe.ScheduledRender.scheduleRender(this,this.#m);return}}this.#d(e),this.#p()}#u(){if(!this.#e)throw new Error("Dialog not found");this.#l(),this.#e.setDialogVisible(!0),fe.ScheduledRender.scheduleRender(this,this.#m),this.dispatchEvent(new Qt)}#p(e){if(!this.#e)throw new Error("Dialog not found");this.#e.setDialogVisible(!1),e&&e.stopImmediatePropagation(),fe.ScheduledRender.scheduleRender(this,this.#m)}connectedCallback(){this.#t.addChangeListener(this.#c,this),fe.ScheduledRender.scheduleRender(this,this.#m)}disconnectedCallback(){this.#t.removeChangeListener(this.#c,this)}#h(){return this.#t.get().enabled?Le`
        <devtools-button
          class="config-button"
          @click=${this.#u}
          .data=${{variant:"outlined",title:D(C.configure)}}
        jslog=${He.action("timeline.field-data.configure").track({click:!0})}
        >${D(C.configure)}</devtools-button>
      `:Le`
      <devtools-button
        class="setup-button"
        @click=${this.#u}
        .data=${{variant:"primary",title:D(C.setUp)}}
        jslog=${He.action("timeline.field-data.setup").track({click:!0})}
        data-field-data-setup
      >${D(C.setUp)}</devtools-button>
    `}#v(){return Le`
      <devtools-button
        @click=${()=>{this.#f(!0)}}
        .data=${{variant:"primary",title:D(C.ok)}}
        class="enable"
        jslog=${He.action("timeline.field-data.enable").track({click:!0})}
        data-field-data-enable
      >${D(C.ok)}</devtools-button>
    `}#y(){let e=this.#t.get().enabled?D(C.optOut):D(C.cancel);return Le`
      <devtools-button
        @click=${()=>{this.#f(!1)}}
        .data=${{variant:"outlined",title:e}}
        jslog=${He.action("timeline.field-data.disable").track({click:!0})}
        data-field-data-disable
      >${e}</devtools-button>
    `}#b(e){e.stopPropagation();let t=e.target;this.#s=t.value,this.#o="",fe.ScheduledRender.scheduleRender(this,this.#m)}#g(e){e.stopPropagation();let t=e.target;this.#n=t.checked,this.#o="",fe.ScheduledRender.scheduleRender(this,this.#m)}#w(e){try{return new URL(e).origin}catch{return null}}#x(){return Le`
      <div class="origin-mapping-description">${D(C.mapDevelopmentOrigins)}</div>
      <devtools-widget ${hr(tt)} ${fr(tt,e=>{this.#a=e})}>
      </devtools-widget>
      <div class="origin-mapping-button-section">
        <devtools-button
          @click=${()=>this.#a?.startCreation()}
          .data=${{variant:"text",title:D(C.new),iconName:"plus"}}
          jslogContext="new-origin-mapping"
        >${D(C.new)}</devtools-button>
      </div>
    `}#m=()=>{let e=Le`
      <style>${Ys}</style>
      <style>${ii.textInputStyles}</style>
      <style>${ii.checkboxStyles}</style>
      <div class="open-button-section">${this.#h()}</div>
      <devtools-dialog
        @clickoutsidedialog=${this.#p}
        .position=${"auto"}
        .horizontalAlignment=${"center"}
        .jslogContext=${"timeline.field-data.settings"}
        .expectedMutationsSelector=${".timeline-settings-pane option"}
        .dialogTitle=${D(C.configureFieldData)}
        ${yt.Directives.ref(t=>{t instanceof HTMLElement&&(this.#e=t)})}
      >
        <div class="content">
          <div>
            ${oo.getFormatLocalizedStringTemplate(ro,C.fetchAggregated,{PH1:Le`<devtools-link
                  href="https://developer.chrome.com/docs/crux"
                  >${ti.i18n.lockedString("Chrome UX Report")}</devtools-link
                >`})}
          </div>
          <div class="privacy-disclosure">
            <h3 class="section-title">${D(C.privacyDisclosure)}</h3>
            <div>${D(C.whenPerformanceIsShown)}</div>
          </div>
          <details aria-label=${D(C.advanced)}>
            <summary>${D(C.advanced)}</summary>
            <div class="advanced-section-contents">
              ${this.#x()}
              <hr class="divider">
              <label class="url-override">
                <input
                  type="checkbox"
                  .checked=${this.#n}
                  @change=${this.#g}
                  aria-label=${D(C.onlyFetchFieldData)}
                  jslog=${He.toggle().track({click:!0}).context("field-url-override-enabled")}
                />
                ${D(C.onlyFetchFieldData)}
              </label>
              <input
                type="text"
                @keyup=${this.#b}
                @change=${this.#b}
                class="devtools-text-input"
                .disabled=${!this.#n}
                .value=${this.#s}
                placeholder=${gr(this.#n?D(C.url):void 0)}
              />
              ${this.#o?Le`<div class="warning" role="alert" aria-label=${this.#o}>${this.#o}</div>`:ur}
            </div>
          </details>
          <div class="buttons-section">
            ${this.#y()}
            ${this.#v()}
          </div>
        </div>
      </devtools-dialog>
    `;yt.render(e,this.#i,{host:this})}};customElements.define("devtools-field-settings-dialog",ei);var go={};$(go,{DEFAULT_VIEW:()=>uo,IgnoreListSetting:()=>Ei,regexInputIsValid:()=>Ri});import"./../../../ui/components/menus/menus.js";import*as bt from"./../../../core/common/common.js";import*as Ui from"./../../../core/i18n/i18n.js";import*as Di from"./../../../core/platform/platform.js";import*as mo from"./../../../models/workspace/workspace.js";import"./../../../ui/components/buttons/buttons.js";import"./../../../ui/components/dialogs/dialogs.js";import*as po from"./../../../ui/legacy/legacy.js";import*as Hi from"./../../../ui/lit/lit.js";var lo=`.ignore-list-setting-content{max-width:var(--sys-size-30)}.ignore-list-setting-description{margin-bottom:5px}.regex-row{display:flex;devtools-checkbox{flex:auto}devtools-button{height:24px}&:not(:hover) devtools-button{display:none}}.new-regex-row{display:flex;.new-regex-text-input{flex:auto}.harmony-input[type="text"]{border:1px solid var(--sys-color-neutral-outline);border-radius:4px;outline:none;&.error-input,
    &:invalid{border-color:var(--sys-color-error)}&:not(.error-input, :invalid):focus{border-color:var(--sys-color-state-focus-ring)}&:not(.error-input, :invalid):hover:not(:focus){background:var(--sys-color-state-hover-on-subtle)}}}
/*# sourceURL=${import.meta.resolve("./ignoreListSetting.css")} */`;var{html:co,Directives:vr}=Hi,{live:yr}=vr,Ie={showIgnoreListSettingDialog:"Show ignore list setting dialog",ignoreList:"Ignore list",ignoreListDescription:"Add regular expression rules to remove matching scripts from the flame chart.",ignoreScriptsWhoseNamesMatchS:"Ignore scripts whose names match ''{regex}''",removeRegex:"Remove the regex: ''{regex}''",addNewRegex:"Add a regular expression rule for the script\u2019s URL",ignoreScriptsWhoseNamesMatchNewRegex:"Ignore scripts whose names match the new regex"},br=Ui.i18n.registerUIStrings("panels/timeline/components/IgnoreListSetting.ts",Ie),Ne=Ui.i18n.getLocalizedString.bind(void 0,br),uo=(i,e,t)=>{let{ignoreListEnabled:s,regexes:o,newRegexValue:n,newRegexChecked:r,onExistingRegexEnableToggle:a,onRemoveRegexByIndex:l,onNewRegexInputBlur:m,onNewRegexInputChange:p,onNewRegexInputFocus:u,onNewRegexAdd:h,onNewRegexCancel:f}=i;function T(y,j){let M=Ne(Ie.ignoreScriptsWhoseNamesMatchS,{regex:y.pattern});return co`
      <div class='regex-row'>
        <devtools-checkbox title=${M} aria-label=${M} ?checked=${!y.disabled}
          @change=${N=>a(y,N.currentTarget.checked)}
          .jslogContext=${"timeline.ignore-list-pattern"}>${y.pattern}</devtools-checkbox>
        <devtools-button
            @click=${()=>l(j)}
            .data=${{variant:"icon",iconName:"bin",title:Ne(Ie.removeRegex,{regex:y.pattern}),jslogContext:"timeline.ignore-list-pattern.remove"}}>
        </devtools-button>
      </div>
    `}Hi.render(co`
    <style>${lo}</style>
    <devtools-button-dialog
      @contextmenu=${y=>y.stopPropagation()}
      .data=${{openOnRender:!1,jslogContext:"timeline.ignore-list",variant:"toolbar",iconName:"compress",disabled:!s,iconTitle:Ne(Ie.showIgnoreListSettingDialog),horizontalAlignment:"auto",closeButton:!0,dialogTitle:Ne(Ie.ignoreList)}}>
      <div class='ignore-list-setting-content'>
        <div class='ignore-list-setting-description'>${Ne(Ie.ignoreListDescription)}</div>
        ${o.map(T)}

        <div class='new-regex-row'>
          <devtools-checkbox
            title=${Ne(Ie.ignoreScriptsWhoseNamesMatchNewRegex)}
            .jslogContext=${"timeline.ignore-list-new-regex.checkbox"}
            .checked=${r}
          >
          </devtools-checkbox>
          <input
            @blur=${y=>m(y.currentTarget.value)}
            @input=${y=>p(y.currentTarget.value)}
            @focus=${y=>u(y.currentTarget.value)}
            @keydown=${y=>{let j=y.currentTarget;y.key===Di.KeyboardUtilities.ENTER_KEY?h(j.value):y.key===Di.KeyboardUtilities.ESCAPE_KEY&&(f(),j.blur(),y.stopImmediatePropagation())}}
            class="harmony-input new-regex-text-input"
            title=${Ne(Ie.addNewRegex)}
            placeholder='/framework\\.js$'
            .value=${yr(n)}
            .jslogContext=${"timeline.ignore-list-new-regex.text"}>
        </div>
      </div>
    </devtools-button-dialog>
  `,t)},Ei=class i extends po.Widget.Widget{static createWidgetElement(){let e=document.createElement("devtools-widget");return new i(e),e}#i;#e=bt.Settings.Settings.instance().moduleSetting("enable-ignore-listing");#t=this.#a().getAsArray();#s="";#n=!1;#o=null;constructor(e,t=uo){super(e,{useShadowDom:!0}),this.#i=t,this.element.classList.remove("vbox","flex-auto"),bt.Settings.Settings.instance().moduleSetting("skip-stack-frames-pattern").addChangeListener(this.requestUpdate.bind(this)),bt.Settings.Settings.instance().moduleSetting("enable-ignore-listing").addChangeListener(this.requestUpdate.bind(this)),this.requestUpdate()}#a(){return bt.Settings.Settings.instance().moduleSetting("skip-stack-frames-pattern")}#l(e){this.#o={pattern:e,disabled:!1},this.#t.push(this.#o)}#d(){if(!this.#o)return;let e=this.#t.pop();e&&e!==this.#o&&(console.warn("The last regex is not the editing one."),this.#t.push(e)),this.#o=null,this.#a().setAsArray(this.#t)}#c(){this.#s="",this.#n=!1,this.requestUpdate()}#r(e){let t=e.trim();this.#d(),Ri(t)&&(mo.IgnoreListManager.IgnoreListManager.instance().addRegexToIgnoreList(t),this.#c())}#f(e){this.#r(e),this.#l("")}#u(){this.#d(),this.#c()}#p(){if(this.#o){let e=this.#t[this.#t.length-1];if(e&&e===this.#o)return this.#t.slice(0,-1)}return this.#t}#h(e){let t=e.trim();this.#s=t,this.#o&&Ri(t)&&(this.#o.pattern=t,this.#o.disabled=!t,this.#a().setAsArray(this.#t))}#v(e,t){e.disabled=!t,this.#a().setAsArray(this.#t)}#y(e){this.#t.splice(e,1),this.#a().setAsArray(this.#t)}performUpdate(){let e={ignoreListEnabled:this.#e.get(),regexes:this.#p(),newRegexValue:this.#s,newRegexChecked:this.#n,onExistingRegexEnableToggle:this.#v.bind(this),onRemoveRegexByIndex:this.#y.bind(this),onNewRegexInputBlur:this.#r.bind(this),onNewRegexInputChange:this.#h.bind(this),onNewRegexInputFocus:this.#l.bind(this),onNewRegexAdd:this.#f.bind(this),onNewRegexCancel:this.#u.bind(this)};this.#i(e,void 0,this.contentElement)}};function Ri(i){let e=i.trim();if(!e.length)return!1;let t;try{t=new RegExp(e)}catch{}return!!t}var yo={};$(yo,{DEFAULT_VIEW:()=>vo,InteractionBreakdown:()=>Ai});import*as Ae from"./../../../core/i18n/i18n.js";import*as fo from"./../../../ui/legacy/legacy.js";import*as Fi from"./../../../ui/lit/lit.js";var ho=`@scope to (devtools-widget > *){:host{display:block}.breakdown{margin:0;padding:0;list-style:none;color:var(--sys-color-token-subtle)}.value{display:inline-block;padding:0 5px;color:var(--sys-color-on-surface)}}
/*# sourceURL=${import.meta.resolve("./interactionBreakdown.css")} */`;var{html:wr}=Fi,si={inputDelay:"Input delay",processingDuration:"Processing duration",presentationDelay:"Presentation delay"},xr=Ae.i18n.registerUIStrings("panels/timeline/components/InteractionBreakdown.ts",si),Ni=Ae.i18n.getLocalizedString.bind(void 0,xr),vo=(i,e,t)=>{let{entry:s}=i,o=Ae.TimeUtilities.formatMicroSecondsAsMillisFixed(s.inputDelay),n=Ae.TimeUtilities.formatMicroSecondsAsMillisFixed(s.mainThreadHandling),r=Ae.TimeUtilities.formatMicroSecondsAsMillisFixed(s.presentationDelay);Fi.render(wr`<style>${ho}</style>
      <ul class="breakdown">
        <li data-entry="input-delay">${Ni(si.inputDelay)}<span class="value">${o}</span></li>
        <li data-entry="processing-duration">${Ni(si.processingDuration)}<span class="value">${n}</span></li>
        <li data-entry="presentation-delay">${Ni(si.presentationDelay)}<span class="value">${r}</span></li>
      </ul>
  `,t)},Ai=class i extends fo.Widget.Widget{static createWidgetElement(e){let t=document.createElement("devtools-widget"),s=new i(t);return s.entry=e,t}#i;#e=null;constructor(e,t=vo){super(e,{useShadowDom:!0}),this.#i=t}set entry(e){e!==this.#e&&(this.#e=e,this.requestUpdate())}performUpdate(){if(!this.#e)return;let e={entry:this.#e};this.#i(e,void 0,this.contentElement)}};var Ro={};$(Ro,{DEFAULT_VIEW:()=>Po,LayoutShiftDetails:()=>_i});import*as Fe from"./../../../core/i18n/i18n.js";import*as ko from"./../../../core/sdk/sdk.js";import*as Lo from"./../../../models/trace/helpers/helpers.js";import*as ze from"./../../../models/trace/trace.js";import*as Io from"./../../../ui/components/buttons/buttons.js";import*as Vi from"./../../../ui/legacy/components/utils/utils.js";import*as $o from"./../../../ui/legacy/legacy.js";import*as V from"./../../../ui/lit/lit.js";import*as Co from"./insights/insights.js";import*as oi from"./../../../core/sdk/sdk.js";import*as bo from"./../../../ui/components/buttons/buttons.js";import*as wo from"./../../../ui/legacy/components/utils/utils.js";import*as Bi from"./../../../ui/legacy/legacy.js";import*as xt from"./../../../ui/lit/lit.js";import*as xo from"./../../common/common.js";var{html:wt}=xt,{widget:Sr}=Bi.Widget,Tr=(i,e,t)=>{let{relatedNodeEl:s,fallbackUrl:o,fallbackHtmlSnippet:n,fallbackText:r}=i,a;if(s)a=wt`<div class='node-link'>${s}</div>`;else if(o){let m={tabStop:!0,showColumnNumber:!1,maxLength:20},p=wo.Linkifier.Linkifier.linkifyURL(o,m);a=wt`<div class='node-link'>
      <style>${bo.textButtonStyles}</style>
      ${p}
    </div>`}else n?a=wt`<pre style='text-wrap: auto'>${n}</pre>`:r?a=wt`<span>${r}</span>`:a=xt.nothing;xt.render(a,t)},zi=class extends Bi.Widget.Widget{#i;#e;#t;#s;#n;#o;#a;#l=new Map;constructor(e,t=Tr){super(e,{useShadowDom:!0}),this.#i=t}set data(e){this.#e=e.backendNodeId,this.#t=e.frame,this.#s=e.options,this.#n=e.fallbackUrl,this.#o=e.fallbackHtmlSnippet,this.#a=e.fallbackText,this.requestUpdate()}async#d(){if(this.#e===void 0)return;let e=this.#l.get(this.#e);if(e)return e==="NO_NODE_FOUND"?void 0:e;let s=oi.TargetManager.TargetManager.instance().primaryPageTarget()?.model(oi.DOMModel.DOMModel);if(!s)return;let n=(await s.pushNodesByBackendIdsToFrontend(new Set([this.#e])))?.get(this.#e);if(!n){this.#l.set(this.#e,"NO_NODE_FOUND");return}if(n.frameId()!==this.#t){this.#l.set(this.#e,"NO_NODE_FOUND");return}let r=xo.DOMLinkifier.Linkifier.instance().linkify(n,this.#s);return this.#l.set(this.#e,r),r}async performUpdate(){let e={relatedNodeEl:await this.#d(),fallbackUrl:this.#n,fallbackHtmlSnippet:this.#o,fallbackText:this.#a};this.#i(e,void 0,this.contentElement)}};function Oi(i){return wt`${Sr(zi,{data:i})}`}var So=`@scope to (devtools-widget > *){.layout-shift-details-title,
  .cluster-details-title{padding-bottom:var(--sys-size-5);display:flex;align-items:center;.layout-shift-event-title,
    .cluster-event-title{background-color:var(--app-color-rendering);width:var(--sys-size-6);height:var(--sys-size-6);border:var(--sys-size-1) solid var(--sys-color-divider);box-sizing:content-box;display:inline-block;margin-right:var(--sys-size-3)}}.layout-shift-details-table{font:var(--sys-typescale-body4-regular);margin-bottom:var(--sys-size-4);text-align:left;border-block:var(--sys-size-1) solid var(--sys-color-divider);border-collapse:collapse;font-variant-numeric:tabular-nums;th,
    td{padding-right:var(--sys-size-4);min-width:var(--sys-size-20);max-width:var(--sys-size-28)}}.table-title{th{font:var(--sys-typescale-body4-medium)}tr{border-bottom:var(--sys-size-1) solid var(--sys-color-divider)}}.timeline-link{cursor:pointer;text-decoration:underline;color:var(--sys-color-primary);background:none;border:none;padding:0;font:inherit;text-align:left}.parent-cluster-link{margin-left:var(--sys-size-2)}.timeline-link.invalid-link{color:var(--sys-color-state-disabled)}.details-row{display:flex;min-height:var(--sys-size-9)}.title{color:var(--sys-color-token-subtle);overflow:hidden;padding-right:var(--sys-size-5);display:inline-block;vertical-align:top}.culprit{display:inline-flex;flex-direction:row;gap:var(--sys-size-3)}.value{display:inline-block;user-select:text;text-overflow:ellipsis;overflow:hidden;padding:0 var(--sys-size-3)}.layout-shift-summary-details,
  .layout-shift-cluster-summary-details{font:var(--sys-typescale-body4-regular);display:flex;flex-direction:column;column-gap:var(--sys-size-4);padding:var(--sys-size-5) var(--sys-size-5) 0 var(--sys-size-5)}.culprits{display:flex;flex-direction:column}.shift-row:not(:last-child){border-bottom:var(--sys-size-1) solid var(--sys-color-divider)}.total-row{font:var(--sys-typescale-body4-medium)}}
/*# sourceURL=${import.meta.resolve("./layoutShiftDetails.css")} */`;var{html:z,render:To}=V,kr=20,A={startTime:"Start time",shiftScore:"Shift score",elementsShifted:"Elements shifted",culprit:"Culprit",injectedIframe:"Injected iframe",fontRequest:"Font request",nonCompositedAnimation:"Non-composited animation",animation:"Animation",parentCluster:"Parent cluster",cluster:"Layout shift cluster @ {PH1}",layoutShift:"Layout shift @ {PH1}",total:"Total",unsizedImage:"Unsized image"},Lr=Fe.i18n.registerUIStrings("panels/timeline/components/LayoutShiftDetails.ts",A),F=Fe.i18n.getLocalizedString.bind(void 0,Lr),_i=class extends $o.Widget.Widget{#i;#e=null;#t=null;#s=!1;constructor(e,t=Po){super(e),this.#i=t}set event(e){this.#e=e,this.requestUpdate()}set parsedTrace(e){this.#t=e,this.requestUpdate()}set isFreshRecording(e){this.#s=e,this.requestUpdate()}#n(e){this.contentElement.dispatchEvent(new Co.EventRef.EventReferenceClick(e))}#o(e){let t=e.type==="mouseover";if(e.type==="mouseleave"&&this.contentElement.dispatchEvent(new CustomEvent("toggle-popover",{detail:{show:t},bubbles:!0,composed:!0})),!(e.target instanceof HTMLElement)||!this.#e)return;let s=e.target.closest("tbody tr");if(!s?.parentElement)return;let o=ze.Types.Events.isSyntheticLayoutShift(this.#e)?this.#e:this.#e.events.find(n=>n.ts===parseInt(s.getAttribute("data-ts")??"",10));this.contentElement.dispatchEvent(new CustomEvent("toggle-popover",{detail:{event:o,show:t},bubbles:!0,composed:!0}))}performUpdate(){this.#i({event:this.#e,parsedTrace:this.#t,isFreshRecording:this.#s,togglePopover:e=>this.#o(e),onEventClick:e=>this.#n(e)},{},this.contentElement)}},Po=(i,e,t)=>{if(!i.event||!i.parsedTrace){To(V.nothing,t);return}let s=ze.Name.forEntry(i.event);To(z`
        <style>${So}</style>
        <style>${Io.textButtonStyles}</style>

      <div class="layout-shift-summary-details">
        <div
          class="event-details"
          @mouseover=${i.togglePopover}
          @mouseleave=${i.togglePopover}
        >
        <div class="layout-shift-details-title">
          <div class="layout-shift-event-title"></div>
          ${s}
        </div>
        ${ze.Types.Events.isSyntheticLayoutShift(i.event)?Ir(i.event,i.parsedTrace.insights,i.parsedTrace,i.isFreshRecording,i.onEventClick):$r(i.event,i.parsedTrace.insights,i.parsedTrace,i.onEventClick)}
        </div>
      </div>
      `,t)};function Mo(i,e){return i?.values().find(t=>e?e===t.navigation?.args.data?.navigationId:!t.navigation)}function Ir(i,e,t,s,o){if(!e)return V.nothing;let n=Mo(e,i.args.data?.navigationId)?.model.CLSCulprits;if(!n)return V.nothing;let r=n.shifts.get(i),a=i.args.data?.impacted_nodes??[];s||(a=a?.filter(u=>u.debug_name));let l=r&&(r.webFonts.length||r.iframes.length||r.nonCompositedAnimations.length||r.unsizedImages.length),m=a?.length,p=n.clusters.find(u=>u.events.find(h=>h===i));return z`
      <table class="layout-shift-details-table">
        <thead class="table-title">
          <tr>
            <th>${F(A.startTime)}</th>
            <th>${F(A.shiftScore)}</th>
            ${m?z`
              <th>${F(A.elementsShifted)}</th>`:V.nothing}
            ${l?z`
              <th>${F(A.culprit)}</th> `:V.nothing}
          </tr>
        </thead>
        <tbody>
          ${Do(i,!0,t,a,o,r)}
        </tbody>
      </table>
      ${Pr(p,o,t)}
    `}function $r(i,e,t,s){if(!e)return V.nothing;let o=Mo(e,i.navigationId)?.model.CLSCulprits;if(!o)return V.nothing;let r=!!Array.from(o.shifts.entries()).filter(([a])=>i.events.includes(a)).map(([,a])=>a).flatMap(a=>Object.values(a)).flat().length;return z`
    <table class="layout-shift-details-table">
      <thead class="table-title">
        <tr>
          <th>${F(A.startTime)}</th>
          <th>${F(A.shiftScore)}</th>
          <th>${F(A.elementsShifted)}</th>
          ${r?z`
            <th>${F(A.culprit)}</th> `:V.nothing}
        </tr>
      </thead>
      <tbody>
        ${i.events.map(a=>{let l=o.shifts.get(a),m=a.args.data?.impacted_nodes??[];return Do(a,!1,t,m,s,l)})}

        <tr>
          <td class="total-row">${F(A.total)}</td>
          <td class="total-row">${i.clusterCumulativeScore.toFixed(4)}</td>
        </tr>
      </tbody>
    </table>
  `}function Do(i,e,t,s,o,n){let r=i.args.data?.weighted_score_delta;if(!r)return V.nothing;let a=!!(n&&(n.webFonts.length||n.iframes.length||n.nonCompositedAnimations.length||n.unsizedImages.length));return z`
      <tr class="shift-row" data-ts=${i.ts}>
        <td>${Cr(i,e,t,o)}</td>
        <td>${r.toFixed(4)}</td>
        ${s.length?z`
          <td>
            <div class="elements-shifted">
              ${Mr(i,s)}
            </div>
          </td>`:V.nothing}
        ${a?z`
          <td class="culprits">
            ${n?.webFonts.map(l=>Rr(l))}
            ${n?.iframes.map(l=>Ur(l))}
            ${n?.nonCompositedAnimations.map(l=>Dr(l,o))}
            ${n?.unsizedImages.map(l=>Er(i.args.frame,l))}
          </td>`:V.nothing}
      </tr>`}function Cr(i,e,t,s){let o=ze.Types.Timing.Micro(i.ts-t.data.Meta.traceBounds.min);if(e)return z`${Fe.TimeUtilities.preciseMillisToString(Lo.Timing.microToMilli(o))}`;let n=Fe.TimeUtilities.formatMicroSecondsTime(o);return z`
         <button type="button" class="timeline-link" @click=${()=>s(i)}>${F(A.layoutShift,{PH1:n})}</button>`}function Pr(i,e,t){if(!i)return V.nothing;let s=ze.Types.Timing.Micro(i.ts-(t.data.Meta.traceBounds.min??0)),o=Fe.TimeUtilities.formatMicroSecondsTime(s);return z`
      <span class="parent-cluster">${F(A.parentCluster)}:<button type="button" class="timeline-link parent-cluster-link" @click=${()=>e(i)}>${F(A.cluster,{PH1:o})}</button>
      </span>`}function Mr(i,e){return z`
      ${e?.map(t=>t.node_id!==void 0?Oi({backendNodeId:t.node_id,frame:i.args.frame,fallbackHtmlSnippet:t.debug_name}):V.nothing)}`}function Dr(i,e){let t=i.animation;return t?z`
        <span class="culprit">
        <span class="culprit-type">${F(A.nonCompositedAnimation)}: </span>
        <button type="button" class="culprit-value timeline-link" @click=${()=>e(t)}>${F(A.animation)}</button>
      </span>`:V.nothing}function Er(i,e){let t=Oi({backendNodeId:e.backendNodeId,frame:i,fallbackUrl:e.paintImageEvent.args.data.url});return z`
    <span class="culprit">
      <span class="culprit-type">${F(A.unsizedImage)}: </span>
      <span class="culprit-value">${t}</span>
    </span>`}function Rr(i){let e=Eo(i.args.data.url);return z`
      <span class="culprit">
        <span class="culprit-type">${F(A.fontRequest)}: </span>
        <span class="culprit-value">${e}</span>
      </span>`}function Eo(i){return Vi.Linkifier.Linkifier.linkifyURL(i,{tabStop:!0,showColumnNumber:!1,maxLength:kr})}function Ur(i){let e=i.frame,t=ko.FrameManager.FrameManager.instance().getFrame(e),s;return t?s=Vi.Linkifier.Linkifier.linkifyRevealable(t,t.displayName()):s=Eo(i.url),z`
      <span class="culprit">
        <span class="culprit-type"> ${F(A.injectedIframe)}: </span>
        <span class="culprit-value">${s}</span>
      </span>`}var Jo={};$(Jo,{DEFAULT_VIEW:()=>Yo,LiveMetricsView:()=>Gi});import"./../../../ui/components/settings/settings.js";import"./../../../ui/kit/kit.js";import"./../../../ui/components/menus/menus.js";var Bo={};$(Bo,{MetricCard:()=>ni});import*as K from"./../../../core/i18n/i18n.js";import*as Fo from"./../../../core/platform/platform.js";import*as Wi from"./../../../models/crux-manager/crux-manager.js";import"./../../../ui/components/buttons/buttons.js";import*as qi from"./../../../ui/components/helpers/helpers.js";import*as zo from"./../../../ui/helpers/helpers.js";import*as le from"./../../../ui/lit/lit.js";var Uo=`.metric-card{border-radius:var(--sys-shape-corner-small);padding:14px 16px;background-color:var(--sys-color-surface3);height:100%;box-sizing:border-box}.title{display:flex;justify-content:space-between;font-size:var(--sys-typescale-headline5-size);line-height:var(--sys-typescale-headline5-line-height);font-weight:var(--ref-typeface-weight-medium);margin:0;margin-bottom:6px}.title-help{height:var(--sys-typescale-headline5-line-height);margin-left:4px}.metric-values-section{position:relative;display:flex;column-gap:8px;margin-bottom:8px}.metric-values-section:focus-visible{outline:2px solid -webkit-focus-ring-color}.metric-source-block{flex:1}.metric-source-value{font-size:32px;line-height:36px;font-weight:var(--ref-typeface-weight-regular)}.metric-source-label{font-weight:var(--ref-typeface-weight-medium)}.warning{margin-top:4px;color:var(--sys-color-error);font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);display:flex;&::before{content:" ";width:var(--sys-typescale-body4-line-height);height:var(--sys-typescale-body4-line-height);mask-size:var(--sys-typescale-body4-line-height);mask-image:var(--image-file-warning);background-color:var(--sys-color-error);margin-right:4px;flex-shrink:0}}.good-bg{background-color:var(--app-color-performance-good)}.needs-improvement-bg{background-color:var(--app-color-performance-ok)}.poor-bg{background-color:var(--app-color-performance-bad)}.divider{width:100%;border:0;border-bottom:1px solid var(--sys-color-divider);margin:8px 0;box-sizing:border-box}.compare-text{margin-top:8px}.environment-recs-intro{margin-top:8px}.environment-recs{margin:9px 0}.environment-recs > summary{font-weight:var(--ref-typeface-weight-medium);margin-bottom:4px;font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);display:flex;&::before{content:" ";width:var(--sys-typescale-body4-line-height);height:var(--sys-typescale-body4-line-height);mask-size:var(--sys-typescale-body4-line-height);mask-image:var(--image-file-triangle-right);background-color:var(--icon-default);margin-right:4px;flex-shrink:0}}details.environment-recs[open] > summary::before{mask-image:var(--image-file-triangle-down)}.environment-recs-list{margin:0}.detailed-compare-text{margin-bottom:8px}.bucket-summaries{margin-top:8px;white-space:nowrap}.bucket-summaries.histogram{display:grid;grid-template-columns:minmax(min-content,auto) minmax(40px,60px) max-content;grid-auto-rows:1fr;column-gap:8px;place-items:center flex-end}.bucket-label{justify-self:start;font-weight:var(--ref-typeface-weight-medium);white-space:wrap;> *{white-space:nowrap}}.bucket-range{color:var(--sys-color-token-subtle)}.histogram-bar{height:6px}.histogram-percent{color:var(--sys-color-token-subtle);font-weight:var(--ref-typeface-weight-medium)}.tooltip{display:none;visibility:hidden;transition-property:visibility;width:min(var(--tooltip-container-width,350px),350px);max-width:max-content;position:absolute;top:100%;left:50%;transform:translateX(-50%);z-index:1;box-sizing:border-box;padding:var(--sys-size-5) var(--sys-size-6);border-radius:var(--sys-shape-corner-small);background-color:var(--sys-color-cdt-base-container);box-shadow:var(--drop-shadow-depth-3);.tooltip-scroll{overflow-x:auto;.tooltip-contents{min-width:min-content}}}.subpart-table{display:grid;column-gap:var(--sys-size-3);white-space:nowrap}.subpart-table-row{display:contents}.subpart-table-value{text-align:right}.subpart-table-header-row{font-weight:var(--ref-typeface-weight-medium)}
/*# sourceURL=${import.meta.resolve("./metricCard.css")} */`;import*as Ho from"./../../../core/i18n/i18n.js";import*as k from"./../../../ui/i18n/i18n.js";var L={goodBetterCompare:"Your local {PH1} value of {PH2} is good, but is significantly better than your users\u2019 experience.",goodWorseCompare:"Your local {PH1} value of {PH2} is good, but is significantly worse than your users\u2019 experience.",goodSimilarCompare:"Your local {PH1} value of {PH2} is good, and is similar to your users\u2019 experience.",goodSummarized:"Your local {PH1} value of {PH2} is good.",needsImprovementBetterCompare:"Your local {PH1} value of {PH2} needs improvement, but is significantly better than your users\u2019 experience.",needsImprovementWorseCompare:"Your local {PH1} value of {PH2} needs improvement, but is significantly worse than your users\u2019 experience.",needsImprovementSimilarCompare:"Your local {PH1} value of {PH2} needs improvement, and is similar to your users\u2019 experience.",needsImprovementSummarized:"Your local {PH1} value of {PH2} needs improvement.",poorBetterCompare:"Your local {PH1} value of {PH2} is poor, but is significantly better than your users\u2019 experience.",poorWorseCompare:"Your local {PH1} value of {PH2} is poor, but is significantly worse than your users\u2019 experience.",poorSimilarCompare:"Your local {PH1} value of {PH2} is poor, and is similar to your users\u2019 experience.",poorSummarized:"Your local {PH1} value of {PH2} is poor.",goodGoodDetailedCompare:"Your local {PH1} value of {PH2} is good and is rated the same as {PH4} of real-user {PH1} experiences. Additionally, the field metrics 75th percentile {PH1} value of {PH3} is good.",goodNeedsImprovementDetailedCompare:"Your local {PH1} value of {PH2} is good and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} needs improvement.",goodPoorDetailedCompare:"Your local {PH1} value of {PH2} is good and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} is poor.",needsImprovementGoodDetailedCompare:"Your local {PH1} value of {PH2} needs improvement and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} is good.",needsImprovementNeedsImprovementDetailedCompare:"Your local {PH1} value of {PH2} needs improvement and is rated the same as {PH4} of real-user {PH1} experiences. Additionally, the field metrics 75th percentile {PH1} value of {PH3} needs improvement.",needsImprovementPoorDetailedCompare:"Your local {PH1} value of {PH2} needs improvement and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} is poor.",poorGoodDetailedCompare:"Your local {PH1} value of {PH2} is poor and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} is good.",poorNeedsImprovementDetailedCompare:"Your local {PH1} value of {PH2} is poor and is rated the same as {PH4} of real-user {PH1} experiences. However, the field metrics 75th percentile {PH1} value of {PH3} needs improvement.",poorPoorDetailedCompare:"Your local {PH1} value of {PH2} is poor and is rated the same as {PH4} of real-user {PH1} experiences. Additionally, the field metrics 75th percentile {PH1} value of {PH3} is poor."},I=Ho.i18n.registerUIStrings("panels/timeline/components/MetricCompareStrings.ts",L);function No(i){let{rating:e,compare:t}=i,s={PH1:i.metric,PH2:i.localValue};if(e==="good"&&t==="better")return k.getFormatLocalizedString(I,L.goodBetterCompare,s);if(e==="good"&&t==="worse")return k.getFormatLocalizedString(I,L.goodWorseCompare,s);if(e==="good"&&t==="similar")return k.getFormatLocalizedString(I,L.goodSimilarCompare,s);if(e==="good"&&!t)return k.getFormatLocalizedString(I,L.goodSummarized,s);if(e==="needs-improvement"&&t==="better")return k.getFormatLocalizedString(I,L.needsImprovementBetterCompare,s);if(e==="needs-improvement"&&t==="worse")return k.getFormatLocalizedString(I,L.needsImprovementWorseCompare,s);if(e==="needs-improvement"&&t==="similar")return k.getFormatLocalizedString(I,L.needsImprovementSimilarCompare,s);if(e==="needs-improvement"&&!t)return k.getFormatLocalizedString(I,L.needsImprovementSummarized,s);if(e==="poor"&&t==="better")return k.getFormatLocalizedString(I,L.poorBetterCompare,s);if(e==="poor"&&t==="worse")return k.getFormatLocalizedString(I,L.poorWorseCompare,s);if(e==="poor"&&t==="similar")return k.getFormatLocalizedString(I,L.poorSimilarCompare,s);if(e==="poor"&&!t)return k.getFormatLocalizedString(I,L.poorSummarized,s);throw new Error("Compare string not found")}function Ao(i){let{localRating:e,fieldRating:t}=i,s={PH1:i.metric,PH2:i.localValue,PH3:i.fieldValue,PH4:i.percent};if(e==="good"&&t==="good")return k.getFormatLocalizedString(I,L.goodGoodDetailedCompare,s);if(e==="good"&&t==="needs-improvement")return k.getFormatLocalizedString(I,L.goodNeedsImprovementDetailedCompare,s);if(e==="good"&&t==="poor")return k.getFormatLocalizedString(I,L.goodPoorDetailedCompare,s);if(e==="good"&&!t)return k.getFormatLocalizedString(I,L.goodSummarized,s);if(e==="needs-improvement"&&t==="good")return k.getFormatLocalizedString(I,L.needsImprovementGoodDetailedCompare,s);if(e==="needs-improvement"&&t==="needs-improvement")return k.getFormatLocalizedString(I,L.needsImprovementNeedsImprovementDetailedCompare,s);if(e==="needs-improvement"&&t==="poor")return k.getFormatLocalizedString(I,L.needsImprovementPoorDetailedCompare,s);if(e==="needs-improvement"&&!t)return k.getFormatLocalizedString(I,L.needsImprovementSummarized,s);if(e==="poor"&&t==="good")return k.getFormatLocalizedString(I,L.poorGoodDetailedCompare,s);if(e==="poor"&&t==="needs-improvement")return k.getFormatLocalizedString(I,L.poorNeedsImprovementDetailedCompare,s);if(e==="poor"&&t==="poor")return k.getFormatLocalizedString(I,L.poorPoorDetailedCompare,s);if(e==="poor"&&!t)return k.getFormatLocalizedString(I,L.poorSummarized,s);throw new Error("Detailed compare string not found")}var{html:R,nothing:it}=le,w={localValue:"Local",field75thPercentile:"Field 75th percentile",fieldP75:"Field p75",good:"Good",needsImprovement:"Needs improvement",poor:"Poor",leqRange:"(\u2264{PH1})",betweenRange:"({PH1}-{PH2})",gtRange:"(>{PH1})",percentage:"{PH1}%",interactToMeasure:"Interact with the page to measure INP.",viewCardDetails:"View card details",considerTesting:"Consider your local test conditions",recThrottlingLCP:"Real users may experience longer page loads due to slower network conditions. Increasing network throttling will simulate slower network conditions.",recThrottlingINP:"Real users may experience longer interactions due to slower CPU speeds. Increasing CPU throttling will simulate a slower device.",recViewportLCP:"Screen size can influence what the LCP element is. Ensure you are testing common viewport sizes.",recViewportCLS:"Screen size can influence what layout shifts happen. Ensure you are testing common viewport sizes.",recJourneyCLS:"How a user interacts with the page can influence layout shifts. Ensure you are testing common interactions like scrolling the page.",recJourneyINP:"How a user interacts with the page influences interaction delays. Ensure you are testing common interactions.",recDynamicContentLCP:"The LCP element can vary between page loads if content is dynamic.",recDynamicContentCLS:"Dynamic content can influence what layout shifts happen.",subpart:"Subpart",lcpHelpTooltip:"LCP reports the render time of the largest image, text block, or video visible in the viewport. Click here to learn more about LCP.",clsHelpTooltip:"CLS measures the amount of unexpected shifted content. Click here to learn more about CLS.",inpHelpTooltip:"INP measures the overall responsiveness to all click, tap, and keyboard interactions. Click here to learn more about INP."},Hr=K.i18n.registerUIStrings("panels/timeline/components/MetricCard.ts",w),x=K.i18n.getLocalizedString.bind(void 0,Hr),ni=class extends HTMLElement{#i=this.attachShadow({mode:"open"});constructor(){super(),this.#k()}#e;#t={metric:"LCP"};set data(e){this.#t=e,qi.ScheduledRender.scheduleRender(this,this.#k)}connectedCallback(){qi.ScheduledRender.scheduleRender(this,this.#k)}#s=e=>{Fo.KeyboardUtilities.isEscKey(e)&&(e.stopPropagation(),this.#a())};#n(e){e.target?.hasFocus()||this.#a()}#o(e){let t=e.target;if(t?.hasFocus())return;let s=e.relatedTarget;s instanceof Node&&t.contains(s)||this.#a()}#a(){let e=this.#e;e&&(document.body.removeEventListener("keydown",this.#s),e.style.removeProperty("left"),e.style.removeProperty("visibility"),e.style.removeProperty("display"),e.style.removeProperty("transition-delay"))}#l(e=0){let t=this.#e;if(!t||t.style.visibility||t.style.display)return;document.body.addEventListener("keydown",this.#s),t.style.display="block",t.style.transitionDelay=`${Math.round(e)}ms`;let s=this.#t.tooltipContainer;if(!s)return;let o=s.getBoundingClientRect();t.style.setProperty("--tooltip-container-width",`${Math.round(o.width)}px`),requestAnimationFrame(()=>{let n=0,r=t.getBoundingClientRect(),a=r.right-o.right,l=r.left-o.left;l<0?n=Math.round(l):a>0&&(n=Math.round(a)),t.style.left=`calc(50% - ${n}px)`,t.style.visibility="visible"})}#d(){switch(this.#t.metric){case"LCP":return K.i18n.lockedString("Largest Contentful Paint (LCP)");case"CLS":return K.i18n.lockedString("Cumulative Layout Shift (CLS)");case"INP":return K.i18n.lockedString("Interaction to Next Paint (INP)")}}#c(){switch(this.#t.metric){case"LCP":return qt;case"CLS":return Je;case"INP":return Ze}}#r(){switch(this.#t.metric){case"LCP":return e=>{let t=e*1e3;return K.TimeUtilities.formatMicroSecondsAsSeconds(t)};case"CLS":return e=>e===0?"0":e.toFixed(2);case"INP":return e=>K.TimeUtilities.preciseMillisToString(e)}}#f(){switch(this.#t.metric){case"LCP":return"https://web.dev/articles/lcp";case"CLS":return"https://web.dev/articles/cls";case"INP":return"https://web.dev/articles/inp"}}#u(){switch(this.#t.metric){case"LCP":return x(w.lcpHelpTooltip);case"CLS":return x(w.clsHelpTooltip);case"INP":return x(w.inpHelpTooltip)}}#p(){let{localValue:e}=this.#t;if(e!==void 0)return e}#h(){let{fieldValue:e}=this.#t;if(e!==void 0&&(typeof e=="string"&&(e=Number(e)),!!Number.isFinite(e)))return e}#v(){let e=this.#p(),t=this.#h();if(!(e===void 0||t===void 0))return gt(this.#t.metric,e,t)}#y(){let e=this.#p();if(e===void 0)return this.#t.metric==="INP"?R`
          <div class="compare-text">${x(w.interactToMeasure)}</div>
        `:le.nothing;let t=this.#v(),s=xe(e,this.#c()),o=re(this.#g(!0),e,this.#c(),this.#r(),{dim:!0});return R`
      <div class="compare-text">
        ${No({metric:K.i18n.lockedString(this.#t.metric),rating:s,compare:t,localValue:o})}
      </div>
    `}#b(){let e=this.#v();if(!e||e==="similar")return le.nothing;let t=[],s=this.#t.metric;return s==="LCP"&&e==="better"?t.push(x(w.recThrottlingLCP)):s==="INP"&&e==="better"&&t.push(x(w.recThrottlingINP)),s==="LCP"?t.push(x(w.recViewportLCP)):s==="CLS"&&t.push(x(w.recViewportCLS)),s==="CLS"?t.push(x(w.recJourneyCLS)):s==="INP"&&t.push(x(w.recJourneyINP)),s==="LCP"?t.push(x(w.recDynamicContentLCP)):s==="CLS"&&t.push(x(w.recDynamicContentCLS)),t.length?R`
      <details class="environment-recs">
        <summary>${x(w.considerTesting)}</summary>
        <ul class="environment-recs-list">${t.map(o=>R`<li>${o}</li>`)}</ul>
      </details>
    `:le.nothing}#g(e){return`timeline.landing.${e?"local":"field"}-${this.#t.metric.toLowerCase()}`}#w(){let e=this.#p();if(e===void 0)return this.#t.metric==="INP"?R`
          <div class="detailed-compare-text">${x(w.interactToMeasure)}</div>
        `:le.nothing;let t=xe(e,this.#c()),s=this.#h(),o=s!==void 0?xe(s,this.#c()):void 0,n=re(this.#g(!0),e,this.#c(),this.#r(),{dim:!0}),r=re(this.#g(!1),s,this.#c(),this.#r(),{dim:!0});return R`
      <div class="detailed-compare-text">${Ao({metric:K.i18n.lockedString(this.#t.metric),localRating:t,fieldRating:o,localValue:n,fieldValue:r,percent:this.#S(t)})}</div>
    `}#x(e){switch(e){case"good":return 0;case"needs-improvement":return 1;case"poor":return 2}}#m(e){let s=this.#t.histogram?.[this.#x(e)].density||0;return`${Math.round(s*100)}%`}#S(e){let t=this.#t.histogram;if(t===void 0)return"-";let s=t[this.#x(e)].density||0,o=Math.round(s*100);return x(w.percentage,{PH1:o})}#T(){let e=Wi.CrUXManager.instance().getConfigSetting().get().enabled,t=this.#r(),s=this.#c(),o=R`
      <div class="bucket-label">
        <span>${x(w.good)}</span>
        <span class="bucket-range"> ${x(w.leqRange,{PH1:t(s[0])})}</span>
      </div>
    `,n=R`
      <div class="bucket-label">
        <span>${x(w.needsImprovement)}</span>
        <span class="bucket-range"> ${x(w.betweenRange,{PH1:t(s[0]),PH2:t(s[1])})}</span>
      </div>
    `,r=R`
      <div class="bucket-label">
        <span>${x(w.poor)}</span>
        <span class="bucket-range"> ${x(w.gtRange,{PH1:t(s[1])})}</span>
      </div>
    `;return e?R`
      <div class="bucket-summaries histogram">
        ${o}
        <div class="histogram-bar good-bg" style="width: ${this.#m("good")}"></div>
        <div class="histogram-percent">${this.#S("good")}</div>
        ${n}
        <div class="histogram-bar needs-improvement-bg" style="width: ${this.#m("needs-improvement")}"></div>
        <div class="histogram-percent">${this.#S("needs-improvement")}</div>
        ${r}
        <div class="histogram-bar poor-bg" style="width: ${this.#m("poor")}"></div>
        <div class="histogram-percent">${this.#S("poor")}</div>
      </div>
    `:R`
        <div class="bucket-summaries">
          ${o}
          ${n}
          ${r}
        </div>
      `}#L(e){let t=e.every(s=>s[2]!==void 0);return R`
      <hr class="divider">
      <div class="subpart-table" role="table">
        <div class="subpart-table-row subpart-table-header-row" role="row">
          <div role="columnheader" style="grid-column: 1">${x(w.subpart)}</div>
          <div role="columnheader" class="subpart-table-value" style="grid-column: 2">${x(w.localValue)}</div>
          ${t?R`
            <div
              role="columnheader"
              class="subpart-table-value"
              style="grid-column: 3"
              title=${x(w.field75thPercentile)}>${x(w.fieldP75)}</div>
          `:it}
        </div>
        ${e.map(s=>R`
          <div class="subpart-table-row" role="row">
            <div role="cell">${s[0]}</div>
            <div role="cell" class="subpart-table-value">${K.TimeUtilities.preciseMillisToString(s[1])}</div>
            ${s[2]!==void 0?R`
              <div role="cell" class="subpart-table-value">${K.TimeUtilities.preciseMillisToString(s[2])}</div>
            `:it}
          </div>
        `)}
      </div>
    `}#k=()=>{let e=Wi.CrUXManager.instance().getConfigSetting().get().enabled,t=this.#f(),s=this.#p(),o=this.#h(),n=this.#c(),r=this.#r(),a=re(this.#g(!0),s,n,r),l=re(this.#g(!1),o,n,r),m=R`
      <style>${Uo}</style>
      <style>${Ee}</style>
      <div class="metric-card">
        <h3 class="title">
          ${this.#d()}
          <devtools-button
            class="title-help"
            title=${this.#u()}
            .iconName=${"help"}
            .variant=${"icon"}
            @click=${()=>zo.openInNewTab(t)}
          ></devtools-button>
        </h3>
        <div tabindex="0" class="metric-values-section"
          @mouseenter=${()=>this.#l(500)}
          @mouseleave=${this.#n}
          @focusin=${this.#l}
          @focusout=${this.#o}
          aria-describedby="tooltip"
        >
          <div class="metric-source-block">
            <div class="metric-source-value" id="local-value">${a}</div>
            ${e?R`<div class="metric-source-label">${x(w.localValue)}</div>`:it}
          </div>
          ${e?R`
            <div class="metric-source-block">
              <div class="metric-source-value" id="field-value">${l}</div>
              <div class="metric-source-label">${x(w.field75thPercentile)}</div>
            </div>
          `:it}
          <div
            id="tooltip"
            class="tooltip"
            role="tooltip"
            aria-label=${x(w.viewCardDetails)}
            ${le.Directives.ref(p=>{p instanceof HTMLElement&&(this.#e=p)})}
          >
            <div class="tooltip-scroll">
              <div class="tooltip-contents">
                <div>
                  ${this.#w()}
                  <hr class="divider">
                  ${this.#T()}
                  ${s&&this.#t.subparts?this.#L(this.#t.subparts):it}
                </div>
              </div>
            </div>
          </div>
        </div>
        ${e?R`<hr class="divider">`:it}
        ${this.#y()}
        ${this.#t.warnings?.map(p=>R`
          <div class="warning">${p}</div>
        `)}
        ${this.#b()}
        <slot name="extra-info"></slot>
      </div>
    `;le.render(m,this.#i,{host:this})}};customElements.define("devtools-metric-card",ni);import*as ri from"./../../../core/common/common.js";import*as nt from"./../../../core/i18n/i18n.js";import*as qo from"./../../../core/root/root.js";import*as jo from"./../../../core/sdk/sdk.js";import*as st from"./../../../models/crux-manager/crux-manager.js";import*as Ko from"./../../../models/emulation/emulation.js";import*as Tt from"./../../../models/live-metrics/live-metrics.js";import*as St from"./../../../models/trace/trace.js";import"./../../../ui/components/buttons/buttons.js";import*as kt from"./../../../ui/i18n/i18n.js";import*as Z from"./../../../ui/legacy/legacy.js";import*as B from"./../../../ui/lit/lit.js";import*as Ji from"./../../../ui/visual_logging/visual_logging.js";import*as Lt from"./../../common/common.js";import*as ai from"./../../mobile_throttling/mobile_throttling.js";var ji=`.container{container-type:inline-size;height:100%;font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);font-weight:var(--ref-typeface-weight-regular);user-select:text}.live-metrics-view{--min-main-area-size:60%;background-color:var(--sys-color-cdt-base-container);display:flex;flex-direction:row;width:100%;height:100%}.live-metrics,
.next-steps{padding:16px;height:100%;overflow-y:auto;box-sizing:border-box}.live-metrics{flex:1;display:flex;flex-direction:column}.live-metrics > *{flex-shrink:0}.next-steps{flex:0 0 336px;box-sizing:border-box;border:none;border-left:1px solid var(--sys-color-divider)}@container (max-width: 650px){.live-metrics-view{flex-direction:column}.next-steps{flex-basis:40%;border:none;border-top:1px solid var(--sys-color-divider)}}.metric-cards{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));width:100%}.section-title{font-size:var(--sys-typescale-headline4-size);line-height:var(--sys-typescale-headline4-line-height);font-weight:var(--ref-typeface-weight-medium);margin:0;margin-bottom:10px}.settings-card{border-radius:var(--sys-shape-corner-small);padding:14px 16px 16px;background-color:var(--sys-color-surface3);margin-bottom:16px}.record-action-card{border-radius:var(--sys-shape-corner-small);padding:12px 16px 12px 12px;background-color:var(--sys-color-surface3);margin-bottom:16px}.card-title{font-size:var(--sys-typescale-headline5-size);line-height:var(--sys-typescale-headline5-line-height);font-weight:var(--ref-typeface-weight-medium);margin:0}.settings-card .card-title{margin-bottom:4px}.device-toolbar-description{margin-bottom:12px;display:flex}.network-cache-setting{display:inline-block;max-width:max-content}.throttling-recommendation-value{font-weight:var(--ref-typeface-weight-medium)}.related-info{text-wrap:nowrap;margin-top:8px;display:flex}.related-info-label{font-weight:var(--ref-typeface-weight-medium);margin-right:4px}.related-info-link{background-color:var(--sys-color-cdt-base-container);border-radius:2px;padding:0 2px;min-width:0}.local-field-link{display:inline-block;width:fit-content;margin-top:8px}.logs-section{margin-top:24px;display:flex;flex-direction:column;flex:1 0 300px;overflow:hidden;max-height:max-content;--app-color-toolbar-background:transparent}.logs-section-header{display:flex;align-items:center}.interactions-clear{margin-left:4px;vertical-align:sub}.log{padding:0;margin:0;overflow:auto}.log-item{border:none;border-bottom:1px solid var(--sys-color-divider);&.highlight{animation:highlight-fadeout 2s}}.interaction{--subpart-table-margin:120px;--details-indicator-width:18px;summary{display:flex;align-items:center;padding:7px 4px;&::before{content:" ";height:14px;width:var(--details-indicator-width);mask-image:var(--image-file-triangle-right);background-color:var(--icon-default);flex-shrink:0}}details[open] summary::before{mask-image:var(--image-file-triangle-down)}}.interaction-type{font-weight:var(--ref-typeface-weight-medium);width:calc(var(--subpart-table-margin) - var(--details-indicator-width));flex-shrink:0}.interaction-inp-chip{background-color:var(--sys-color-yellow-container);color:var(--sys-color-on-yellow-container);padding:0 2px}.interaction-node{flex-grow:1;margin-right:32px;min-width:0}.interaction-info{width:var(--sys-typescale-body4-line-height);height:var(--sys-typescale-body4-line-height);margin-right:6px}.interaction-duration{text-align:end;width:max-content;flex-shrink:0;font-weight:var(--ref-typeface-weight-medium)}.layout-shift{display:flex;align-items:flex-start}.layout-shift-score{margin-right:16px;padding:7px 0;width:150px;box-sizing:border-box}.layout-shift-nodes{flex:1;min-width:0}.layout-shift-node{border-bottom:1px solid var(--sys-color-divider);padding:7px 0;&:last-child{border:none}}.record-action{display:flex;flex-direction:row;align-items:center;justify-content:space-between;gap:8px}.shortcut-label{width:max-content;flex-shrink:0}.field-data-option{margin:8px 0;max-width:100%}.field-setup-buttons{margin-top:14px}.field-data-message{margin-bottom:12px}.field-data-warning{margin-top:4px;color:var(--sys-color-error);font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);display:flex;&::before{content:" ";width:var(--sys-typescale-body4-line-height);height:var(--sys-typescale-body4-line-height);mask-size:var(--sys-typescale-body4-line-height);mask-image:var(--image-file-warning);background-color:var(--sys-color-error);margin-right:4px;flex-shrink:0}}.collection-period-range{font-weight:var(--ref-typeface-weight-medium)}devtools-link{color:var(--sys-color-primary);text-decoration-line:underline}.environment-option{display:flex;align-items:center;margin-top:8px;gap:var(--sys-size-2)}.environment-option-label{display:flex;align-items:center;gap:var(--sys-size-2)}.environment-recs-list{margin:0;padding-left:20px}.environment-rec{font-weight:var(--ref-typeface-weight-medium)}.link-to-log{padding:unset;background:unset;border:unset;font:inherit;color:var(--sys-color-primary);text-decoration:underline;cursor:pointer}@keyframes highlight-fadeout{from{background-color:var(--sys-color-yellow-container)}to{background-color:transparent}}.subpart-table{border-top:1px solid var(--sys-color-divider);padding:7px 4px;margin-left:var(--subpart-table-margin)}.subpart-table-row{display:flex;justify-content:space-between}.subpart-table-header-row{font-weight:var(--ref-typeface-weight-medium);margin-bottom:4px}.log-extra-details-button{padding:unset;background:unset;border:unset;font:inherit;color:var(--sys-color-primary);text-decoration:underline;cursor:pointer}.node-view{display:flex;align-items:center;justify-content:center;height:100%;font-size:var(--sys-typescale-body4-size);line-height:var(--sys-typescale-body4-line-height);font-weight:var(--ref-typeface-weight-regular);user-select:text;main{width:300px;max-width:100%;text-align:center;.section-title{margin-bottom:4px}}}.node-description{margin-bottom:12px}.section-header{display:flex;align-items:center;gap:8px;margin-bottom:10px}.section-header .section-title{margin-bottom:0}
/*# sourceURL=${import.meta.resolve("./liveMetricsView.css")} */`;var{html:v,nothing:Be,Directives:{live:Oo}}=B,{widget:ot}=Z.Widget,Nr=["AUTO",...st.DEVICE_SCOPE_LIST],Ar=60,c={softNavigationPillText:"SOFT NAV",localAndFieldMetrics:"Local and field metrics",localMetrics:"Local metrics",fieldDataHistoryLink:"View history",fieldDataHistoryTooltip:"View field data history in CrUX Vis",eventLogs:"Interaction and layout shift logs section",interactions:"Interactions",layoutShifts:"Layout shifts",nextSteps:"Next steps",fieldMetricsTitle:"Field metrics",environmentSettings:"Environment settings",showFieldDataForDevice:"Show field metrics for device type: {PH1}",notEnoughData:"Not enough data",network:"Network: {PH1}",device:"Device: {PH1}",allDevices:"All devices",desktop:"Desktop",mobile:"Mobile",tablet:"Tablet",auto:"Auto ({PH1})",loadingOption:"{PH1} - Loading\u2026",needsDataOption:"{PH1} - No data",urlOption:"URL",originOption:"Origin",urlOptionWithKey:"URL: {PH1}",originOptionWithKey:"Origin: {PH1}",showFieldDataForPage:"Show field metrics for {PH1}",tryDisablingThrottling:"75th percentile is too fast to simulate with throttling",tryUsingThrottling:"75th percentile is similar to {PH1} throttling",percentDevices:"{PH1}% mobile, {PH2}% desktop",useDeviceToolbar:"Use the [device toolbar](https://developer.chrome.com/docs/devtools/device-mode) and configure throttling to simulate real user environments and identify more performance issues.",disableNetworkCache:"Disable network cache",cpuThrottling:"CPU:",lcpElement:"LCP element",inpInteractionLink:"INP interaction",worstCluster:"Worst cluster",numShifts:`{shiftCount, plural,
    =1 {{shiftCount} shift}
    other {{shiftCount} shifts}
  }`,collectionPeriod:"Collection period: {PH1}",dateRange:"{PH1} - {PH2}",seeHowYourLocalMetricsCompare:"See how your local metrics compare to real user data in the {PH1}.",localFieldLearnMoreLink:"Learn more about local and field metrics",localFieldLearnMoreTooltip:"Local metrics are captured from the current page using your network connection and device. field metrics is measured by real users using many different network connections and devices.",interactionExcluded:"INP is calculated using the 98th percentile of interaction delays, so some interaction delays may be larger than the INP value.",clearCurrentLog:"Clear the current log",timeToFirstByte:"Time to first byte",resourceLoadDelay:"Resource load delay",resourceLoadDuration:"Resource load duration",elementRenderDelay:"Element render delay",inputDelay:"Input delay",processingDuration:"Processing duration",presentationDelay:"Presentation delay",inpInteraction:"The INP interaction is at the 98th percentile of interaction delays.",showInpInteraction:"Go to the INP interaction.",showClsCluster:"Go to worst layout shift cluster.",subpart:"Subpart",duration:"Local duration (ms)",logToConsole:"Log additional interaction data to the console",nodePerformanceTimeline:"Node performance",nodeClickToRecord:"Record a performance timeline of the connected Node process.",networkThrottling:"Network:",recommendedThrottlingReason:"Consider changing setting to simulate real user environments"},It=nt.i18n.registerUIStrings("panels/timeline/components/LiveMetricsView.ts",c),d=nt.i18n.getLocalizedString.bind(void 0,It);function Fr(i){let e=i.getSelectedFieldMetricData("largest_contentful_paint_image_time_to_first_byte")?.percentiles?.p75,t=i.getSelectedFieldMetricData("largest_contentful_paint_image_resource_load_delay")?.percentiles?.p75,s=i.getSelectedFieldMetricData("largest_contentful_paint_image_resource_load_duration")?.percentiles?.p75,o=i.getSelectedFieldMetricData("largest_contentful_paint_image_element_render_delay")?.percentiles?.p75;return typeof e!="number"||typeof t!="number"||typeof s!="number"||typeof o!="number"?null:{timeToFirstByte:St.Types.Timing.Milli(e),resourceLoadDelay:St.Types.Timing.Milli(t),resourceLoadTime:St.Types.Timing.Milli(s),elementRenderDelay:St.Types.Timing.Milli(o)}}function zr(i){let e=i.getSelectedFieldMetricData("round_trip_time");if(!e?.percentiles)return null;let t=Number(e.percentiles.p75);if(!Number.isFinite(t))return null;if(t<Ar)return d(c.tryDisablingThrottling);let s=jo.NetworkManager.getRecommendedNetworkPreset(t);if(!s)return null;let o=typeof s.title=="function"?s.title():s.title;return d(c.tryUsingThrottling,{PH1:o})}function Br(i){let e=i.getFieldResponse(i.fieldPageScope,"ALL")?.record.metrics.form_factors?.fractions;return e?d(c.percentDevices,{PH1:Math.round(e.phone*100),PH2:Math.round(e.desktop*100)}):null}function _o(i,e){let t=i.pageResult?.[`${e}-ALL`]?.record.key[e];if(t)return e==="url"?d(c.urlOptionWithKey,{PH1:t}):d(c.originOptionWithKey,{PH1:t});let s=d(e==="url"?c.urlOption:c.originOption);return d(c.needsDataOption,{PH1:s})}function Vo(i){switch(i){case"ALL":return d(c.allDevices);case"DESKTOP":return d(c.desktop);case"PHONE":return d(c.mobile);case"TABLET":return d(c.tablet)}}function Wo(i,e){let t;if(e==="AUTO"){let o=i.resolveDeviceOptionToScope(e),n=Vo(o);t=d(c.auto,{PH1:n})}else t=Vo(e);return i.pageResult?i.getSelectedFieldResponse()?t:d(c.needsDataOption,{PH1:t}):d(c.loadingOption,{PH1:t})}function Or(i){let e=i.getSelectedFieldResponse();if(!e)return null;let{firstDate:t,lastDate:s}=e.record.collectionPeriod,o=new Date(t.year,t.month-1,t.day),n=new Date(s.year,s.month-1,s.day),r={year:"numeric",month:"short",day:"numeric"};return d(c.dateRange,{PH1:o.toLocaleDateString(void 0,r),PH2:n.toLocaleDateString(void 0,r)})}function Zi(i){return B.Directives.ref(e=>{e instanceof HTMLElement&&(e.data={...i,tooltipContainer:e.closest(".metric-cards")||void 0})})}function _r(i){let e=i.cruxManager.getSelectedFieldMetricData("largest_contentful_paint"),t=i.lcpValue?.nodeRef&&Lt.DOMLinkifier.Linkifier.instance().linkify(i.lcpValue?.nodeRef),s=i.lcpValue?.subparts,o=Fr(i.cruxManager);return v`
    <devtools-metric-card ${Zi({metric:"LCP",localValue:i.lcpValue?.value,fieldValue:e?.percentiles?.p75,histogram:e?.histogram,warnings:i.lcpValue?.warnings,subparts:s&&[[d(c.timeToFirstByte),s.timeToFirstByte,o?.timeToFirstByte],[d(c.resourceLoadDelay),s.resourceLoadDelay,o?.resourceLoadDelay],[d(c.resourceLoadDuration),s.resourceLoadTime,o?.resourceLoadTime],[d(c.elementRenderDelay),s.elementRenderDelay,o?.elementRenderDelay]]})}>
      ${t?v`
          <div class="related-info" slot="extra-info">
            <span class="related-info-label">${d(c.lcpElement)}</span>
            <span class="related-info-link">
             ${ot(Lt.DOMLinkifier.DOMNodeLink,{node:i.lcpValue?.nodeRef})}
            </span>
          </div>
        `:Be}
    </devtools-metric-card>
  `}function Vr(i){let e=i.cruxManager.getSelectedFieldMetricData("cumulative_layout_shift"),t=new Set(i.clsValue?.clusterShiftIds||[]),s=t.size>0&&i.layoutShifts.some(o=>t.has(o.uniqueLayoutShiftId));return v`
    <devtools-metric-card ${Zi({metric:"CLS",localValue:i.clsValue?.value,fieldValue:e?.percentiles?.p75,histogram:e?.histogram,warnings:i.clsValue?.warnings})}>
      ${s?v`
        <div class="related-info" slot="extra-info">
          <span class="related-info-label">${d(c.worstCluster)}</span>
          <button
            class="link-to-log"
            title=${d(c.showClsCluster)}
            @click=${()=>i.revealLayoutShiftCluster(t)}
            jslog=${Ji.action("timeline.landing.show-cls-cluster").track({click:!0})}
          >${d(c.numShifts,{shiftCount:t.size})}</button>
        </div>
      `:Be}
    </devtools-metric-card>
  `}function Wr(i){let e=i.cruxManager.getSelectedFieldMetricData("interaction_to_next_paint"),t=i.inpValue?.subparts,s=i.inpValue?.interactionId?i.interactions.get(i.inpValue.interactionId):void 0;return v`
    <devtools-metric-card ${Zi({metric:"INP",localValue:i.inpValue?.value,fieldValue:e?.percentiles?.p75,histogram:e?.histogram,warnings:i.inpValue?.warnings,subparts:t&&[[d(c.inputDelay),t.inputDelay],[d(c.processingDuration),t.processingDuration],[d(c.presentationDelay),t.presentationDelay]]})}>
      ${s?v`
        <div class="related-info" slot="extra-info">
          <span class="related-info-label">${d(c.inpInteractionLink)}</span>
          <button
            class="link-to-log"
            title=${d(c.showInpInteraction)}
            @click=${()=>i.revealInteraction(s)}
            jslog=${Ji.action("timeline.landing.show-inp-interaction").track({click:!0})}
          >${s.interactionType}</button>
        </div>
      `:Be}
    </devtools-metric-card>
  `}function Ki(i){function e(){i.execute()}return v`
    <div class="record-action">
      <devtools-button @click=${e} .data=${{variant:"text",size:"REGULAR",iconName:i.icon(),title:i.title(),jslogContext:i.id()}}>
        ${i.title()}
      </devtools-button>
      <span class="shortcut-label">${Z.ShortcutRegistry.ShortcutRegistry.instance().shortcutTitleForAction(i.id())}</span>
    </div>
  `}function qr(i){let e=i.cruxManager.getConfigSetting().get().enabled,t=Br(i.cruxManager)||d(c.notEnoughData),s=zr(i.cruxManager)||d(c.notEnoughData);return v`
    <h3 class="card-title">${d(c.environmentSettings)}</h3>
    <div class="device-toolbar-description">${Vt(d(c.useDeviceToolbar))}</div>
    ${e?v`
      <ul class="environment-recs-list">
        <li>${kt.getFormatLocalizedStringTemplate(It,c.device,{PH1:v`<span class="environment-rec">${t}</span>`})}</li>
        <li>${kt.getFormatLocalizedStringTemplate(It,c.network,{PH1:v`<span class="environment-rec">${s}</span>`})}</li>
      </ul>
    `:Be}
    <div class="environment-option">
      <label class="environment-option-label">
        ${d(c.cpuThrottling)}
        <select ${ot(ai.CPUThrottlingSelector.CPUThrottlingSelector)}></select>
      </label>
      <devtools-icon title=${d(c.recommendedThrottlingReason)} name="info"></devtools-icon>
    </div>
    <div class="environment-option">
      <label class="environment-option-label">
        ${d(c.networkThrottling)}
        <select
          ${ot(ai.NetworkThrottlingSelector.NetworkThrottlingSelect,{bindToGlobalConditions:!0})}
        ></select>
      </label>
      <devtools-icon title=${d(c.recommendedThrottlingReason)} name="info"></devtools-icon>
    </div>
    <div class="environment-option">
      <setting-checkbox
        class="network-cache-setting"
        .data=${{setting:ri.Settings.Settings.instance().moduleSetting("cache-disabled"),textOverride:d(c.disableNetworkCache)}}
      ></setting-checkbox>
    </div>
  `}function jr(i){if(!i.cruxManager.getConfigSetting().get().enabled)return B.nothing;let e=_o(i.cruxManager,"url"),t=_o(i.cruxManager,"origin"),s=i.cruxManager.fieldPageScope==="url"?e:t,o=d(c.showFieldDataForPage,{PH1:s}),n=!i.cruxManager.pageResult?.["url-ALL"]&&!i.cruxManager.pageResult?.["origin-ALL"];return v`
    <devtools-select-menu
      id="page-scope-select"
      class="field-data-option"
      @selectmenuselected=${i.handlePageScopeSelected}
      .showDivider=${!0}
      .showArrow=${!0}
      .sideButton=${!1}
      .showSelectedItem=${!0}
      .buttonTitle=${s}
      .disabled=${n}
      title=${o}
    >
      <devtools-menu-item
        .value=${"url"}
        .selected=${i.cruxManager.fieldPageScope==="url"}
      >
        ${e}
      </devtools-menu-item>
      <devtools-menu-item
        .value=${"origin"}
        .selected=${i.cruxManager.fieldPageScope==="origin"}
      >
        ${t}
      </devtools-menu-item>
    </devtools-select-menu>
  `}function Kr(i){if(!i.cruxManager.getConfigSetting().get().enabled)return B.nothing;let e=!i.cruxManager.getFieldResponse(i.cruxManager.fieldPageScope,"ALL"),t=Wo(i.cruxManager,i.cruxManager.fieldDeviceOption);return v`
    <devtools-select-menu
      id="device-scope-select"
      class="field-data-option"
      @selectmenuselected=${i.handleDeviceOptionSelected}
      .showDivider=${!0}
      .showArrow=${!0}
      .sideButton=${!1}
      .showSelectedItem=${!0}
      .buttonTitle=${d(c.device,{PH1:t})}
      .disabled=${e}
      title=${d(c.showFieldDataForDevice,{PH1:t})}
    >
      ${Nr.map(s=>v`
          <devtools-menu-item
            .value=${s}
            .selected=${i.cruxManager.fieldDeviceOption===s}
          >
            ${Wo(i.cruxManager,s)}
          </devtools-menu-item>
        `)}
    </devtools-select-menu>
  `}function Xr(i){if(!i.getConfigSetting().get().enabled)return B.nothing;let e=i.pageResult?.normalizedUrl;if(!e)return B.nothing;let t=new URL("https://cruxvis.withgoogle.com/");t.searchParams.set("view","cwvsummary"),t.searchParams.set("url",e);let s=i.fieldPageScope;t.searchParams.set("identifier",s);let o=i.getSelectedDeviceScope();t.searchParams.set("device",o);let n=`${t.origin}/#/${t.search}`;return v`
      (<devtools-link href=${n}
               class="local-field-link"
               title=${d(c.fieldDataHistoryTooltip)}
      >${d(c.fieldDataHistoryLink)}</devtools-link>)
    `}function Gr(i){let e=Or(i),t=e||d(c.notEnoughData),s=e?Xr(i):B.nothing,o=i.pageResult?.warnings||[];return v`
    <div class="field-data-message">
      <div>${kt.getFormatLocalizedStringTemplate(It,c.collectionPeriod,{PH1:v`<span class="collection-period-range">${t}</span>`})} ${s}</div>
      ${o.map(n=>v`
        <div class="field-data-warning">${n}</div>
      `)}
    </div>
  `}function Yr(i){return i.getConfigSetting().get().enabled?Gr(i):v`
    <div class="field-data-message">
      ${kt.getFormatLocalizedStringTemplate(It,c.seeHowYourLocalMetricsCompare,{PH1:v`<devtools-link href="https://developer.chrome.com/docs/crux">${nt.i18n.lockedString("Chrome UX Report")}</devtools-link>`})}
    </div>
  `}var Xi=new WeakMap;function Xo(i){return i.checkVisibility()?Math.abs(i.scrollHeight-i.clientHeight-i.scrollTop)<=1||!!Xi.get(i):!1}function Go(i){requestAnimationFrame(()=>{Xi.set(i,!0),i.addEventListener("scrollend",()=>{Xi.set(i,!1)},{once:!0}),i.scrollTo({top:i.scrollHeight,behavior:"smooth"})})}function Jr(i,e){return i.interactions.size?v`
    <ol class="log"
      slot="interactions-log-content"
      ${B.Directives.ref(t=>{t instanceof HTMLElement&&(e.shouldKeepInteractionsScrolledToBottom=()=>Xo(t),e.keepInteractionsScrolledToBottom=()=>{Go(t)})})}
    >
      ${i.interactions.values().map(t=>{let s=re("timeline.landing.interaction-event-timing",t.duration,Ze,r=>nt.TimeUtilities.preciseMillisToString(r),{dim:!0}),o=i.inpValue&&i.inpValue.value<t.duration,n=i.inpValue?.interactionId===t.interactionId;return v`
          <li id=${t.interactionId} class="log-item interaction" tabindex="-1">
            <details>
              <summary>
                <span class="interaction-type">
                  ${t.interactionType} ${n?v`<span class="interaction-inp-chip" title=${d(c.inpInteraction)}>INP</span>`:Be}
                </span>
                <span class="interaction-node">
                  ${ot(Lt.DOMLinkifier.DOMNodeLink,{node:t.nodeRef})}
                </span>
                ${o?v`<devtools-icon
                  class="interaction-info"
                  name="info"
                  title=${d(c.interactionExcluded)}
                ></devtools-icon>`:Be}
                <span class="interaction-duration">${s}</span>
              </summary>
              <div class="subpart-table" role="table">
                <div class="subpart-table-row subpart-table-header-row" role="row">
                  <div role="columnheader">${d(c.subpart)}</div>
                  <div role="columnheader">
                    ${t.longAnimationFrameTimings.length?v`
                       <button
                         class="log-extra-details-button"
                         title=${d(c.logToConsole)}
                         @click=${()=>i.logExtraInteractionDetails(t)}
                       >${d(c.duration)}</button>
                     `:d(c.duration)}
                  </div>
                </div>
                <div class="subpart-table-row" role="row">
                  <div role="cell">${d(c.inputDelay)}</div>
                  <div role="cell">${Math.round(t.subparts.inputDelay)}</div>
                </div>
                <div class="subpart-table-row" role="row">
                  <div role="cell">${d(c.processingDuration)}</div>
                  <div role="cell">${Math.round(t.subparts.processingDuration)}</div>
                </div>
                <div class="subpart-table-row" role="row">
                  <div role="cell">${d(c.presentationDelay)}</div>
                  <div role="cell">${Math.round(t.subparts.presentationDelay)}</div>
                </div>
              </div>
            </details>
          </li>
        `})}
    </ol>
  `:B.nothing}function Zr(i,e){return i.layoutShifts.length?v`
    <ol class="log"
      slot="layout-shifts-log-content"
      ${B.Directives.ref(t=>{t instanceof HTMLElement&&(e.shouldKeepLayoutShiftsScrolledToBottom=()=>Xo(t),e.keepLayoutShiftsScrolledToBottom=()=>{Go(t)})})}
    >
      ${i.layoutShifts.map(t=>{let s=re("timeline.landing.layout-shift-event-score",t.score,Je,o=>o.toFixed(4),{dim:!0});return v`
          <li id=${t.uniqueLayoutShiftId} class="log-item layout-shift" tabindex="-1">
            <div class="layout-shift-score">Layout shift score: ${s}</div>
            <div class="layout-shift-nodes">
              ${t.affectedNodeRefs.map(o=>v`
                <div class="layout-shift-node">
                  ${ot(Lt.DOMLinkifier.DOMNodeLink,{node:o})}
                </div>
              `)}
            </div>
          </li>
        `})}
    </ol>
  `:B.nothing}function Qr(i,e){return v`
    <section
      class="logs-section"
      aria-label=${d(c.eventLogs)}
    >
      <devtools-widget ${ot(Yi,{selectedTab:i.highlightedInteractionId?"interactions":i.highlightedLayoutShiftClusterIds?.size?"layout-shifts":void 0})}>
        ${Jr(i,e)}
        ${Zr(i,e)}
      </devtools-widget>
    </section>
  `}function ea(i){return v`
    <style>${ji}</style>
    <style>${Ee}</style>
    <div class="node-view">
      <main>
        <h2 class="section-title">${d(c.nodePerformanceTimeline)}</h2>
        <div class="node-description">${d(c.nodeClickToRecord)}</div>
        <div class="record-action-card">${Ki(i.toggleRecordAction)}</div>
      </main>
    </div>
  `}var Yo=(i,e,t)=>{if(i.isNode){B.render(ea(i),t);return}let s=i.cruxManager.getConfigSetting().get().enabled,o=d(s?c.localAndFieldMetrics:c.localMetrics),r=v`
    <style>${ji}</style>
    <style>${Ee}</style>
    <div class="container">
      <div class="live-metrics-view">
        <main class="live-metrics">
          <div class="section-header">
            <h2 class="section-title">${o}</h2>
            ${i.navigationType==="soft-navigation"?v`<span class="badge">${d(c.softNavigationPillText)}</span>`:Be}
          </div>
          <div class="metric-cards">
            <div id="lcp">
              ${_r(i)}
            </div>
            <div id="cls">
              ${Vr(i)}
            </div>
            <div id="inp">
              ${Wr(i)}
            </div>
          </div>
          <devtools-link
            href=${"https://web.dev/articles/lab-and-field-data-differences#lab_data_versus_field_data"}
            class="local-field-link"
            title=${d(c.localFieldLearnMoreTooltip)}
          >${d(c.localFieldLearnMoreLink)}</devtools-link>
          ${Qr(i,e)}
        </main>
        <aside class="next-steps" aria-labelledby="next-steps-section-title">
          <h2 id="next-steps-section-title" class="section-title">${d(c.nextSteps)}</h2>
          <div id="field-setup" class="settings-card">
            <h3 class="card-title">${d(c.fieldMetricsTitle)}</h3>
            ${Yr(i.cruxManager)}
            ${jr(i)}
            ${Kr(i)}
            <div class="field-setup-buttons">
              <devtools-field-settings-dialog></devtools-field-settings-dialog>
            </div>
          </div>
          <div id="recording-settings" class="settings-card">
            ${qr(i)}
          </div>
          <div id="record" class="record-action-card">
            ${Ki(i.toggleRecordAction)}
          </div>
          <div id="record-page-load" class="record-action-card">
            ${Ki(i.recordReloadAction)}
          </div>
        </aside>
      </div>
    </div>
  `;if(B.render(r,t),i.highlightedInteractionId){let a=t.querySelector("#"+CSS.escape(i.highlightedInteractionId));a&&requestAnimationFrame(()=>{a.scrollIntoView({block:"center"}),a.focus(),Z.UIUtils.runCSSAnimationOnce(a,"highlight")})}if(i.highlightedLayoutShiftClusterIds?.size){let a=[];for(let l of i.highlightedLayoutShiftClusterIds){let m=t.querySelector("#"+CSS.escape(l));m&&a.push(m)}a.length&&requestAnimationFrame(()=>{a[0].scrollIntoView({block:"start"}),a[0].focus();for(let l of a)Z.UIUtils.runCSSAnimationOnce(l,"highlight")})}},Gi=class extends Z.Widget.Widget{isNode=qo.Runtime.Runtime.isNode();#i;#e;#t;#s;#n=new Map;#o=[];#a="";#l=new Set;#d=st.CrUXManager.instance();#c;#r;#f;#u={};#p=Ko.DeviceModeModel.DeviceModeModel.tryInstance();constructor(e,t=Yo){super(e,{useShadowDom:!0}),this.#f=t,this.#c=Z.ActionRegistry.ActionRegistry.instance().getAction("timeline.toggle-recording"),this.#r=Z.ActionRegistry.ActionRegistry.instance().getAction("timeline.record-reload")}async#h(e){this.#i=e.data.lcp,this.#e=e.data.cls,this.#t=e.data.inp,this.#s=e.data.navigationType;let t=this.#o.length<e.data.layoutShifts.length;this.#o=[...e.data.layoutShifts];let s=this.#n.size<e.data.interactions.size;this.#n=new Map(e.data.interactions);let o=s&&this.#u.shouldKeepInteractionsScrolledToBottom?.(),n=t&&this.#u.shouldKeepLayoutShiftsScrolledToBottom?.();this.requestUpdate(),await this.updateComplete,o&&this.#u.keepInteractionsScrolledToBottom?.(),n&&this.#u.keepLayoutShiftsScrolledToBottom?.()}#v(){this.requestUpdate()}#y(){this.requestUpdate()}async#b(){this.isNode||await this.#d.refresh(),this.requestUpdate()}wasShown(){super.wasShown();let e=Tt.LiveMetrics.instance();e.addEventListener("status",this.#h,this);let t=st.CrUXManager.instance();t.addEventListener("field-data-changed",this.#v,this),this.#p?.addEventListener("Updated",this.#y,this),t.getConfigSetting().get().enabled&&this.#b(),this.#i=e.lcpValue,this.#e=e.clsValue,this.#t=e.inpValue,this.#n=e.interactions,this.#o=e.layoutShifts,this.#s=e.navigationType,this.requestUpdate()}willHide(){super.willHide(),Tt.LiveMetrics.instance().removeEventListener("status",this.#h,this),st.CrUXManager.instance().removeEventListener("field-data-changed",this.#v,this),this.#p?.removeEventListener("Updated",this.#y,this)}#g(e){e.itemValue==="url"?this.#d.fieldPageScope="url":this.#d.fieldPageScope="origin",this.requestUpdate()}#w(e){this.#d.fieldDeviceOption=e.itemValue,this.requestUpdate()}async#x(e){this.#a=e.interactionId,this.requestUpdate(),await this.updateComplete,this.#a=""}async#m(e){await Tt.LiveMetrics.instance().logInteractionScripts(e)&&await ri.Console.Console.instance().showPromise()}async#S(e){this.#l=e,this.requestUpdate(),await this.updateComplete,this.#l=new Set}performUpdate(){let e={isNode:this.isNode,lcpValue:this.#i,clsValue:this.#e,inpValue:this.#t,interactions:this.#n,layoutShifts:this.#o,toggleRecordAction:this.#c,recordReloadAction:this.#r,cruxManager:this.#d,handlePageScopeSelected:this.#g.bind(this),handleDeviceOptionSelected:this.#w.bind(this),revealLayoutShiftCluster:this.#S.bind(this),revealInteraction:this.#x.bind(this),logExtraInteractionDetails:this.#m.bind(this),highlightedInteractionId:this.#a,highlightedLayoutShiftClusterIds:this.#l,navigationType:this.#s};this.#f(e,this.#u,this.contentElement)}},ta=(i,e,t)=>{B.render(v`
    <style>
      /* Any children of the root element will be matched to the slots defined within the container
         widget's shadow DOM. */
      :host,
      .widget {
        display: contents;
      }
    </style>
    <devtools-tabbed-pane @select=${s=>i.onTabSelected(s.detail.tabId)}>
      <devtools-toolbar slot="right">
        <devtools-button .iconName=${"clear"} .variant=${"toolbar"}
                         title=${d(c.clearCurrentLog)} @click=${i.onClear}
                         .jslogContext=${"timeline.landing.clear-log"}>
        </devtools-button>
      </devtools-toolbar>
      <!-- Taking advantage of web component slots allows us to render updates in the lit templates defined in the
      main component. This should be more performant and doesn't require us to inject live metrics styles twice. -->
      <slot name="interactions-log-content" id="interactions" ?selected=${Oo(i.selectedTab==="interactions")}
            title=${d(c.interactions)} jslogcontext="timeline.landing.interactions-log">
      </slot>
      <slot name="layout-shifts-log-content" id="layout-shifts" ?selected=${Oo(i.selectedTab==="layout-shifts")}
            title=${d(c.layoutShifts)} jslogcontext="timeline.landing.layout-shifts-log">
      </slot>
    </devtools-tabbed-pane>
  `,t)},Yi=class extends Z.Widget.Widget{#i;#e="interactions";set selectedTab(e){!e||this.#e===e||(this.#e=e,this.requestUpdate())}#t(){let e=Tt.LiveMetrics.instance();switch(this.#e){case"interactions":e.clearInteractions();break;case"layout-shifts":e.clearLayoutShifts();break}}constructor(e,t=ta){super(e,{useShadowDom:!0}),this.#i=t,this.requestUpdate()}performUpdate(){let e={onClear:this.#t.bind(this),selectedTab:this.#e,onTabSelected:t=>{this.selectedTab=t}};this.#i(e,void 0,this.contentElement)}};var cn={};$(cn,{DEFAULT_VIEW:()=>ln,NetworkRequestDetails:()=>es});import"./../../../ui/components/request_link_icon/request_link_icon.js";import*as rn from"./../../../core/common/common.js";import*as rt from"./../../../core/i18n/i18n.js";import*as at from"./../../../core/sdk/sdk.js";import*as an from"./../../../models/trace/helpers/helpers.js";import*as Oe from"./../../../models/trace/trace.js";import*as $t from"./../../../ui/legacy/components/utils/utils.js";import*as di from"./../../../ui/legacy/legacy.js";import*as O from"./../../../ui/lit/lit.js";var Zo=`@scope to (devtools-widget > *){.network-request-details-title{font-size:13px;padding:8px;display:flex;align-items:center}.network-request-details-title > div{box-sizing:border-box;width:14px;height:14px;border:1px solid var(--sys-color-divider);display:inline-block;margin-right:4px}.network-request-details-content{border-bottom:1px solid var(--sys-color-divider)}.network-request-details-cols{display:flex;justify-content:space-between;width:fit-content}:host{display:contents}.network-request-details-col{max-width:300px}.column-divider{border-left:1px solid var(--sys-color-divider)}.network-request-details-col.server-timings{display:grid;grid-template-columns:1fr 1fr 1fr;width:fit-content;width:450px;gap:0}.network-request-details-item, .network-request-details-col{padding:5px 10px}.server-timing-column-header{font-weight:var(--ref-typeface-weight-medium)}.network-request-details-row{min-height:min-content;display:flex;justify-content:space-between}.title{color:var(--sys-color-token-subtle);overflow:hidden;padding-right:10px;display:inline-block;vertical-align:top}.value{display:inline-block;user-select:text;text-overflow:ellipsis;overflow:hidden;&.synthetic{font-style:italic}}.focusable-outline{overflow:visible}.devtools-link,
  .timeline-link{color:var(--text-link);text-decoration:underline;outline-offset:2px;padding:0;text-align:left;.elements-disclosure &{color:var(--text-link)}devtools-icon{vertical-align:baseline;color:var(--sys-color-primary)}:focus .selected & devtools-icon{color:var(--sys-color-tonal-container)}&:focus-visible{outline-width:unset}&.invalid-link{color:var(--text-disabled);text-decoration:none}&:not(.devtools-link-prevent-click, .invalid-link){cursor:pointer}@media (forced-colors: active){&:not(.devtools-link-prevent-click){forced-color-adjust:none;color:linktext}&:focus-visible{background:Highlight;color:HighlightText}}}.text-button.link-style,
  .text-button.link-style:hover,
  .text-button.link-style:active{background:none;border:none;font:inherit}}
/*# sourceURL=${import.meta.resolve("./networkRequestDetails.css")} */`;var li=`@scope to (devtools-widget > *){.bold{font-weight:bold}.url{margin-left:15px;margin-right:5px}.url--host{color:var(--sys-color-token-subtle)}.priority-row{margin-left:15px}.throttled-row{margin-left:15px;color:var(--sys-color-yellow)}.network-category-chip{box-sizing:border-box;width:10px;height:10px;border:1px solid var(--sys-color-divider);display:inline-block;margin-right:4px}devtools-icon.priority{height:13px;width:13px;color:var(--sys-color-on-surface-subtle)}.render-blocking{margin-left:15px;color:var(--sys-color-error)}.divider{border-top:1px solid var(--sys-color-divider);margin:5px 0}.timings-row{align-self:start;display:flex;align-items:center}.indicator{display:inline-block;width:12px;height:6px;margin-right:5px;border:1px solid var(--sys-color-on-surface-subtle);box-sizing:border-box}devtools-icon.indicator{vertical-align:middle;height:12px;width:12px;margin-right:4px;color:var(--sys-color-yellow);border:none}.whisker-left{align-self:center;display:inline-flex;width:11px;height:6px;margin-right:5px;border-left:1px solid var(--sys-color-on-surface-subtle);box-sizing:border-box}.whisker-right{align-self:center;display:inline-flex;width:11px;height:6px;margin-right:5px;border-right:1px solid var(--sys-color-on-surface-subtle);box-sizing:border-box}.horizontal{background-color:var(--sys-color-on-surface-subtle);height:1px;width:10px;align-self:center}.time{margin-left:auto;display:inline-block;padding-left:10px}.timings-row--duration{.indicator{border-color:transparent}.time{font-weight:var(--ref-typeface-weight-medium)}&.throttled{color:var(--sys-color-yellow)}}.redirects-row{margin-left:15px}}
/*# sourceURL=${import.meta.resolve("./networkRequestTooltip.css")} */`;var on={};$(on,{DEFAULT_VIEW:()=>sn,NetworkRequestTooltip:()=>de});import"./../../../ui/kit/kit.js";import*as ve from"./../../../core/i18n/i18n.js";import*as Qo from"./../../../core/platform/platform.js";import*as ye from"./../../../core/sdk/sdk.js";import*as en from"./../../../models/trace/trace.js";import*as ci from"./../../../ui/legacy/components/perf_ui/perf_ui.js";import*as Qi from"./../../../ui/legacy/legacy.js";import*as me from"./../../../ui/lit/lit.js";import*as tn from"./../utils/utils.js";var{html:W,nothing:ia,Directives:{classMap:sa,ifDefined:oa}}=me,{widget:na}=Qi.Widget,ra=60,te={priority:"Priority",duration:"Duration",queuingAndConnecting:"Queuing and connecting",requestSentAndWaiting:"Request sent and waiting",contentDownloading:"Content downloading",waitingOnMainThread:"Waiting on main thread",renderBlocking:"Render-blocking",redirects:"Redirects",wasThrottled:"Request was throttled ({PH1})"},aa=ve.i18n.registerUIStrings("panels/timeline/components/NetworkRequestTooltip.ts",te),ce=ve.i18n.getLocalizedString.bind(void 0,aa),sn=(i,e,t)=>{let{networkRequest:s,entityMapper:o,throttlingTitle:n}=i,r={backgroundColor:`${Ye(s)}`},a=new URL(s.args.data.url),l=o?o.entityForEvent(s):null,m=tn.Helpers.formatOriginWithEntity(a,l,!0),p=de.renderRedirects(s);me.render(W`
    <style>${li}</style>
    <div class="performance-card">
      <div class="url">${Qo.StringUtilities.trimMiddle(a.href.replace(a.origin,""),ra)}</div>
      <div class="url url--host">${m}</div>

      <div class="divider"></div>
      <div class="network-category">
        <span class="network-category-chip" style=${me.Directives.styleMap(r)}>
        </span>${Wt(s)}
      </div>
      <div class="priority-row">${ce(te.priority)}: ${de.renderPriorityValue(s)}</div>
      ${n?W`
        <div class="throttled-row">
          ${ce(te.wasThrottled,{PH1:n})}
        </div>`:ia}
      ${en.Helpers.Network.isSyntheticNetworkRequestEventRenderBlocking(s)?W`<div class="render-blocking"> ${ce(te.renderBlocking)} </div>`:me.nothing}
      <div class="divider"></div>

      ${de.renderTimings(s)}

      ${p?W`
        <div class="divider"></div>
        ${p}
      `:me.nothing}
    </div>
  `,t)},de=class i extends Qi.Widget.Widget{static createWidgetElement(e,t){return W`${na(i,{networkRequest:e,entityMapper:t})}`}#i;#e;#t;constructor(e,t=sn){super(e,{useShadowDom:!0}),this.#i=t}set networkRequest(e){this.#e=e,this.requestUpdate()}set entityMapper(e){this.#t=e,this.requestUpdate()}static renderPriorityValue(e){return e.args.data.priority===e.args.data.initialPriority?W`${ci.NetworkPriorities.uiLabelForNetworkPriority(e.args.data.priority)}`:W`${ci.NetworkPriorities.uiLabelForNetworkPriority(e.args.data.initialPriority)}
        <devtools-icon name="arrow-forward" class="priority"></devtools-icon>
        ${ci.NetworkPriorities.uiLabelForNetworkPriority(e.args.data.priority)}`}static renderTimings(e){let t=e.args.data.syntheticData,s=t.sendStartTime-e.ts,o=t.downloadStart-t.sendStartTime,n=t.finishTime-t.downloadStart,r=e.ts+e.dur-t.finishTime,a=Ye(e),l={backgroundColor:`color-mix(in srgb, ${a}, hsla(0, 100%, 100%, 0.8))`},m={backgroundColor:a},p=ye.TraceObject.RevealableNetworkRequest.create(ye.TargetManager.TargetManager.instance(),e),u=p&&ye.NetworkManager.MultitargetNetworkManager.instance().appliedRequestConditions(p.networkRequest),h=u?ce(te.wasThrottled,{PH1:typeof u.conditions.title=="string"?u.conditions.title:u.conditions.title()}):void 0,f=W`<span class="whisker-left"> <span class="horizontal"></span> </span>`,T=W`<span class="whisker-right"> <span class="horizontal"></span> </span>`,y=sa({"timings-row timings-row--duration":!0,throttled:!!u?.urlPattern});return W`
      <div
        class=${y}
        title=${oa(h)}>
        ${u?.urlPattern?W`<devtools-icon
          class=indicator
          name=watch
          ></devtools-icon>`:W`<span class="indicator"></span>`}
        ${ce(te.duration)}
         <span class="time"> ${ve.TimeUtilities.formatMicroSecondsTime(e.dur)} </span>
      </div>
      <div class="timings-row">
        ${f}
        ${ce(te.queuingAndConnecting)}
        <span class="time"> ${ve.TimeUtilities.formatMicroSecondsTime(s)} </span>
      </div>
      <div class="timings-row">
        <span class="indicator" style=${me.Directives.styleMap(l)}></span>
        ${ce(te.requestSentAndWaiting)}
        <span class="time"> ${ve.TimeUtilities.formatMicroSecondsTime(o)} </span>
      </div>
      <div class="timings-row">
        <span class="indicator" style=${me.Directives.styleMap(m)}></span>
        ${ce(te.contentDownloading)}
        <span class="time"> ${ve.TimeUtilities.formatMicroSecondsTime(n)} </span>
      </div>
      <div class="timings-row">
        ${T}
        ${ce(te.waitingOnMainThread)}
        <span class="time"> ${ve.TimeUtilities.formatMicroSecondsTime(r)} </span>
      </div>
    `}static renderRedirects(e){let t=[];if(e.args.data.redirects.length>0){t.push(W`
        <div class="redirects-row">
          ${ce(te.redirects)}
        </div>
      `);for(let s of e.args.data.redirects)t.push(W`<div class="redirects-row"> ${s.url}</div>`);return W`${t}`}return null}performUpdate(){if(!this.#e)return;let e=ye.TraceObject.RevealableNetworkRequest.create(ye.TargetManager.TargetManager.instance(),this.#e),t=e&&ye.NetworkManager.MultitargetNetworkManager.instance().appliedRequestConditions(e.networkRequest),s;t&&(s=typeof t.conditions.title=="string"?t.conditions.title:t.conditions.title());let o={networkRequest:this.#e,entityMapper:this.#t,throttlingTitle:s};this.#i(o,void 0,this.contentElement)}};var{html:ie,render:nn}=O,la=100,P={requestMethod:"Request method",protocol:"Protocol",priority:"Priority",encodedData:"Encoded data",decodedBody:"Decoded body",yes:"Yes",no:"No",networkRequest:"Network request",fromCache:"From cache",mimeType:"MIME type",FromMemoryCache:" (from memory cache)",FromCache:" (from cache)",FromPush:" (from push)",FromServiceWorker:" (from `service worker`)",initiatedBy:"Initiated by",blocking:"Blocking",inBodyParserBlocking:"In-body parser blocking",renderBlocking:"Render-blocking",entity:"3rd party",serverTiming:"Server timing",time:"Time",description:"Description"},ca=rt.i18n.registerUIStrings("panels/timeline/components/NetworkRequestDetails.ts",P),U=rt.i18n.getLocalizedString.bind(void 0,ca),es=class extends di.Widget.Widget{#i;#e=null;#t=new WeakMap;#s=null;#n=null;#o=null;#a=null;#l=null;constructor(e,t=ln){super(e),this.#i=t,this.requestUpdate()}set linkifier(e){this.#o=e,this.requestUpdate()}set parsedTrace(e){this.#l=e,this.requestUpdate()}set target(e){this.#n=e,this.requestUpdate()}set request(e){this.#e=e;for(let t of e.args.data.responseHeaders??[]){let s=t.name.toLocaleLowerCase();if(s==="server-timing"||s==="server-timing-test"){t.name="server-timing",this.#a=at.ServerTiming.ServerTiming.parseHeaders([t],rn.Console.Console.instance());break}}this.requestUpdate()}set entityMapper(e){this.#s=e,this.requestUpdate()}performUpdate(){this.#i({request:this.#e,previewElementsCache:this.#t,target:this.#n,entityMapper:this.#s,serverTimings:this.#a,linkifier:this.#o,parsedTrace:this.#l},{},this.contentElement)}},ln=(i,e,t)=>{if(!i.request){nn(O.nothing,t);return}let{request:s}=i,{data:o}=s.args,n=de.renderRedirects(s);nn(ie`
        <style>${Zo}</style>
        <style>${li}</style>

        <div class="network-request-details-content">
          ${da(i.request)}
          ${ma(i.request)}
          <div class="network-request-details-cols">
            ${O.Directives.until(pa(i.request,i.target,i.previewElementsCache))}
            <div class="network-request-details-col">
              ${be(U(P.requestMethod),o.requestMethod)}
              ${be(U(P.protocol),o.protocol)}
              ${be(U(P.priority),de.renderPriorityValue(s))}
              ${be(U(P.mimeType),o.mimeType)}
              ${ua(s)}
              ${be(U(P.decodedBody),rt.ByteUtilities.bytesToString(s.args.data.decodedBodyLength))}
              ${ga(s)}
              ${ha(s)}
              ${fa(s,i.entityMapper)}
            </div>
            <div class="column-divider"></div>
            <div class="network-request-details-col">
              <div class="timing-rows">
                ${de.renderTimings(s)}
              </div>
            </div>
            ${va(i.serverTimings)}
            ${n?ie`
              <div class="column-divider"></div>
              <div class="network-request-details-col redirect-details">
                ${n}
              </div>
            `:O.nothing}
            </div>
            ${ya(s,i.parsedTrace,i.target,i.linkifier)}
          </div>
        </div>
     `,t)};function da(i){let e={backgroundColor:`${Ye(i)}`};return ie`
    <div class="network-request-details-title">
      <div style=${O.Directives.styleMap(e)}></div>
      ${U(P.networkRequest)}
    </div>
  `}function ma(i){let e={tabStop:!0,showColumnNumber:!1,maxLength:la},t=$t.Linkifier.Linkifier.linkifyURL(i.args.data.url,e),s=at.TraceObject.RevealableNetworkRequest.create(at.TargetManager.TargetManager.instance(),i);if(s){t.addEventListener("contextmenu",n=>{let r=new di.ContextMenu.ContextMenu(n);r.appendApplicableItems(s),r.show()});let o=ie`
        ${t}
        <devtools-request-link-icon .data=${{request:s.networkRequest}}>
        </devtools-request-link-icon>
      `;return ie`<div class="network-request-details-item">${o}</div>`}return ie`<div class="network-request-details-item">${t}</div>`}async function pa(i,e,t){if(!i.args.data.url||!e)return O.nothing;let s=i.args.data.url;if(!t.get(i)){let n={imageAltText:$t.ImagePreview.ImagePreview.defaultAltTextForImageURL(s),align:"start",hideFileData:!0},r=await $t.ImagePreview.ImagePreview.build(s,!1,n);r&&t.set(i,r)}let o=t.get(i);return o?ie`
      <div class="network-request-details-col">${o}</div>
      <div class="column-divider"></div>`:O.nothing}function be(i,e){return e?ie`
      <div class="network-request-details-row">
        <div class="title">${i}</div>
        <div class="value">${e}</div>
      </div>`:O.nothing}function ua(i){let e="";return i.args.data.syntheticData.isMemoryCached?e+=U(P.FromMemoryCache):i.args.data.syntheticData.isDiskCached?e+=U(P.FromCache):i.args.data.timing?.pushStart&&(e+=U(P.FromPush)),i.args.data.fromServiceWorker&&(e+=U(P.FromServiceWorker)),(i.args.data.encodedDataLength||!e)&&(e=`${rt.ByteUtilities.bytesToString(i.args.data.encodedDataLength)}${e}`),be(U(P.encodedData),e)}function ga(i){if(!an.Network.isSyntheticNetworkRequestEventRenderBlocking(i))return O.nothing;let e;switch(i.args.data.renderBlocking){case"blocking":e=P.renderBlocking;break;case"in_body_parser_blocking":e=P.inBodyParserBlocking;break;default:return O.nothing}return be(U(P.blocking),e)}function ha(i){let e=i.args.data.syntheticData.isMemoryCached||i.args.data.syntheticData.isDiskCached;return be(U(P.fromCache),U(e?P.yes:P.no))}function fa(i,e){if(!e)return O.nothing;let t=e.entityForEvent(i);return t?be(U(P.entity),t.name):O.nothing}function va(i){return!i||i.length===0?O.nothing:ie`
    <div class="column-divider"></div>
    <div class="network-request-details-col server-timings">
      <div class="server-timing-column-header">${U(P.serverTiming)}</div>
      <div class="server-timing-column-header">${U(P.description)}</div>
      <div class="server-timing-column-header">${U(P.time)}</div>
      ${i.map(e=>{let t=e.metric.startsWith("(c")?"synthetic value":"value";return ie`
          <div class=${t}>${e.metric||"-"}</div>
          <div class=${t}>${e.description||"-"}</div>
          <div class=${t}>${e.value||"-"}</div>
        `})}
    </div>`}function ya(i,e,t,s){if(!s)return O.nothing;let o=Oe.Helpers.Trace.stackTraceInEvent(i)!==null,n=null,r={tabStop:!0,showColumnNumber:!0};if(o){let l=Oe.Helpers.Trace.getStackTraceTopCallFrameInEventPayload(i)??null;l&&(n=s.maybeLinkifyConsoleCallFrame(t,l,r))}let a=e?Oe.Extras.Initiators.getNetworkInitiator(e.data,i):void 0;return a&&Oe.Types.Events.isSyntheticNetworkRequest(a)&&(n=s.maybeLinkifyScriptLocation(t,null,a.args.data.url,void 0,r)),n?ie`
      <div class="network-request-details-item">
        <div class="title">${U(P.initiatedBy)}</div>
        <div class="value focusable-outline">${n}</div>
      </div>`:O.nothing}var pn={};$(pn,{NetworkTrackWidget:()=>mi});import*as $e from"./../../../models/trace/trace.js";import*as mn from"./../../../ui/legacy/components/perf_ui/perf_ui.js";import*as ts from"./../../../ui/lit/lit.js";var dn=`:host{display:flex}.container{display:flex;width:100%;height:150px;background-color:var(--sys-color-cdt-base-container);border-radius:8px;border:1px solid var(--sys-color-divider)}.container canvas{pointer-events:none!important}.flex-auto{flex:auto}.vbox{display:flex;flex-direction:column;position:relative}
/*# sourceURL=${import.meta.resolve("./networkTrackWidget.css")} */`;var{html:ba}=ts,mi=class extends HTMLElement{#i=this.attachShadow({mode:"open"});#e=document.createElement("div");#t=null;#s=null;#n=null;constructor(){super(),this.#e.classList.add("container")}set data(e){let t=e.parsedTrace,s=e.dataProvider;if(!t||!s)return;let o=s!==this.#s;this.#s=s,this.#n=t,this.#o(),(o||!this.#t)&&(this.#e.innerHTML="",this.#t=new mn.FlameChart.FlameChart(this.#s,this),this.#t.show(this.#e,void 0,!0));let n=$e.EntityMapper.EntityMapper.getOrCreate(t);this.#s.preparePopoverElement=()=>null,this.#s.setModel(t,n);let r=this.#s.timelineData();r.groups=[];let a=$e.Helpers.Timing.traceWindowMicroSecondsToMilliSeconds({min:$e.Types.Timing.Micro(e.bounds.min),max:$e.Types.Timing.Micro(e.bounds.max),range:$e.Types.Timing.Micro(e.bounds.range)});this.#s.setWindowTimes(a.min,a.max),this.#t.setWindowTimes(a.min,a.max),this.#o()}#o(){if(!this.#n)return;let e=ba`
        <style>${dn}</style>
        ${this.#e}
      `;ts.render(e,this.#i,{host:this}),this.#t&&this.#t.update()}windowChanged(e,t,s){}updateRangeSelection(e,t){}updateSelectedGroup(e,t){}};customElements.get("devtools-performance-agent-network-track")||customElements.define("devtools-performance-agent-network-track",mi);var yn={};$(yn,{DEFAULT_VIEW:()=>vn,RelatedInsightChips:()=>os});import*as ns from"./../../../core/i18n/i18n.js";import*as fn from"./../../../ui/legacy/legacy.js";import*as rs from"./../../../ui/lit/lit.js";var un=`@scope to (devtools-widget > *){:scope{display:block;border-bottom:1px solid var(--sys-color-divider);flex:none}ul{list-style:none;margin:0;display:flex;flex-wrap:wrap;gap:var(--sys-size-4);padding:0 var(--sys-size-4);justify-content:flex-start;align-items:center}.insight-chip button{background:none;user-select:none;font:var(--sys-typescale-body4-regular);border:var(--sys-size-1) solid var(--sys-color-primary);border-radius:var(--sys-shape-corner-extra-small);display:flex;margin:var(--sys-size-4) 0;padding:var(--sys-size-2) var(--sys-size-4) var(--sys-size-2) var(--sys-size-4);width:max-content;white-space:pre;.keyword{color:var(--sys-color-primary);padding-right:var(--sys-size-3)}}.insight-chip button:hover{background-color:var(--sys-color-state-hover-on-subtle);cursor:pointer;transition:opacity 0.2s ease}.insight-message-box{background:var(--sys-color-surface-yellow);border-radius:var(--sys-shape-corner-extra-small);font:var(--sys-typescale-body4-regular);margin:var(--sys-size-4) 0;button{color:var(--sys-color-on-surface-yellow);border:none;text-align:left;background:none;padding:var(--sys-size-4) var(--sys-size-5);width:100%;max-width:500px;.insight-label{color:var(--sys-color-orange-bright);padding-right:var(--sys-size-3);font-weight:var(--ref-typeface-weight-medium);margin-bottom:var(--sys-size-2)}&:hover{background-color:var(--sys-color-state-hover-on-subtle);cursor:pointer;transition:opacity 0.2s ease}}}}
/*# sourceURL=${import.meta.resolve("./relatedInsightChips.css")} */`;var{html:is,render:gn}=rs,ss={insightKeyword:"Insight",insightWithName:"Insight: {PH1}"},wa=ns.i18n.registerUIStrings("panels/timeline/components/RelatedInsightChips.ts",ss),hn=ns.i18n.getLocalizedString.bind(void 0,wa),os=class extends fn.Widget.Widget{#i;#e=null;#t=new Map;constructor(e,t=vn){super(e),this.#i=t}set activeEvent(e){e!==this.#e&&(this.#e=e,this.requestUpdate())}set eventToInsightsMap(e){this.#t=e??new Map,this.requestUpdate()}performUpdate(){let e={activeEvent:this.#e,eventToInsightsMap:this.#t,onInsightClick(t){t.activateInsight()}};this.#i(e,{},this.contentElement)}},vn=(i,e,t)=>{let{activeEvent:s,eventToInsightsMap:o}=i,n=s?o.get(s)??[]:[];if(!s||o.size===0||n.length===0){gn(rs.nothing,t);return}let r=n.flatMap(l=>l.messages.map(m=>is`
          <li class="insight-message-box">
            <button type="button" @click=${p=>{p.preventDefault(),i.onInsightClick(l)}}>
              <div class="insight-label">${hn(ss.insightWithName,{PH1:l.insightLabel})}</div>
              <div class="insight-message">${m}</div>
            </button>
          </li>
        `)),a=n.flatMap(l=>[is`
          <li class="insight-chip">
            <button type="button" @click=${m=>{m.preventDefault(),i.onInsightClick(l)}}>
              <span class="keyword">${hn(ss.insightKeyword)}</span>
              <span class="insight-label">${l.insightLabel}</span>
            </button>
          </li>
        `]);gn(is`<style>${un}</style>
        <ul>${r}</ul>
        <ul>${a}</ul>`,t)};var An={};$(An,{AnnotationHoverOut:()=>Rt,DEFAULT_SIDEBAR_TAB:()=>za,DEFAULT_SIDEBAR_WIDTH_PX:()=>Ba,HoverAnnotation:()=>Et,RemoveAnnotation:()=>Mt,RevealAnnotation:()=>Dt,SidebarWidget:()=>ms});import*as Nn from"./../../../core/common/common.js";import*as We from"./../../../ui/legacy/legacy.js";var pi=class i extends Event{model;insightSetKey;static eventName="insightactivated";constructor(e,t){super(i.eventName,{bubbles:!0,composed:!0}),this.model=e,this.insightSetKey=t}},ui=class i extends Event{static eventName="insightdeactivated";constructor(){super(i.eventName,{bubbles:!0,composed:!0})}};var kn={};$(kn,{DEFAULT_VIEW:()=>Tn,SidebarAnnotationsTab:()=>Ct});import"./../../../ui/components/settings/settings.js";import*as _e from"./../../../core/common/common.js";import*as lt from"./../../../core/i18n/i18n.js";import*as Pt from"./../../../core/platform/platform.js";import*as pe from"./../../../models/trace/trace.js";import*as wn from"./../../../services/trace_bounds/trace_bounds.js";import*as xn from"./../../../ui/legacy/legacy.js";import*as Sn from"./../../../ui/legacy/theme_support/theme_support.js";import*as Ve from"./../../../ui/lit/lit.js";import*as gi from"./../../../ui/visual_logging/visual_logging.js";var bn=`@scope to (devtools-widget > *){:scope{display:block;height:100%}.annotations{display:flex;flex-direction:column;height:100%;padding:0}.visibility-setting{margin-top:auto}.annotation-container{display:flex;justify-content:space-between;align-items:center;padding:0 var(--sys-size-4);.delete-button{visibility:hidden;border:none;background:none}&:hover,
    &:focus-within{background-color:var(--sys-color-neutral-container);button.delete-button{visibility:visible}}}.annotation{display:flex;flex-direction:column;align-items:flex-start;word-break:normal;overflow-wrap:anywhere;padding:var(--sys-size-8) 0;gap:6px}.annotation-identifier{padding:4px 8px;border-radius:10px;font-weight:bold;&.time-range{background-color:var(--app-color-performance-sidebar-time-range);color:var(--app-color-performance-sidebar-label-text-light)}}.entries-link{display:flex;flex-wrap:wrap;row-gap:2px;align-items:center}.label{font-size:larger}.annotation-tutorial-container{padding:10px}.tutorial-card{display:block;position:relative;margin:10px 0;padding:10px;border-radius:var(--sys-shape-corner-extra-small);overflow:hidden;border:1px solid var(--sys-color-divider);background-color:var(--sys-color-base)}.tutorial-image{display:flex;justify-content:center;& > img{max-width:100%;height:auto}}.tutorial-title,
  .tutorial-description{margin:5px 0}}
/*# sourceURL=${import.meta.resolve("./sidebarAnnotationsTab.css")} */`;var{html:Ce,render:xa}=Ve,Sa=new URL("../../../Images/performance-panel-diagram.svg",import.meta.url).toString(),Ta=new URL("../../../Images/performance-panel-entry-label.svg",import.meta.url).toString(),ka=new URL("../../../Images/performance-panel-time-range.svg",import.meta.url).toString(),La=new URL("../../../Images/performance-panel-delete-annotation.svg",import.meta.url).toString(),q={annotationGetStarted:"Annotate a trace for yourself and others",entryLabelTutorialTitle:"Label an item",entryLabelTutorialDescription:"Double-click or press Enter on an item and type to create an item label.",entryLinkTutorialTitle:"Connect two items",entryLinkTutorialDescription:"Double-click on an item, click on the adjacent rightward arrow, then select the destination item.",timeRangeTutorialTitle:"Define a time range",timeRangeTutorialDescription:"Shift-drag in the flamechart then type to create a time range annotation.",deleteAnnotationTutorialTitle:"Delete an annotation",deleteAnnotationTutorialDescription:"Hover over the list in the sidebar with Annotations tab selected to access the delete function.",deleteButton:"Delete annotation: {PH1}",entryLabelDescriptionLabel:'A "{PH1}" event annotated with the text "{PH2}"',timeRangeDescriptionLabel:"A time range starting at {PH1} and ending at {PH2}",entryLinkDescriptionLabel:'A link between a "{PH1}" event and a "{PH2}" event'},Ia=lt.i18n.registerUIStrings("panels/timeline/components/SidebarAnnotationsTab.ts",q),X=lt.i18n.getLocalizedString.bind(void 0,Ia),Ct=class extends xn.Widget.Widget{#i=[];#e=new Map;#t;#s;constructor(e=Tn){super(),this.#s=e,this.#t=_e.Settings.Settings.instance().moduleSetting("annotations-hidden")}deduplicatedAnnotations(){return this.#i}setData(e){this.#i=this.#n(e.annotations),this.#e=e.annotationEntryToColorMap,this.requestUpdate()}#n(e){let t=new Set,s=e.filter(o=>{if(this.#a(o))return!0;if(o.type==="ENTRIES_LINK"||o.type==="ENTRY_LABEL"){let n=o.type==="ENTRIES_LINK"?o.entryFrom:o.entry;if(t.has(n))return!1;t.add(n)}return!0});return s.sort((o,n)=>this.#o(o)-this.#o(n)),s}#o(e){switch(e.type){case"ENTRY_LABEL":return e.entry.ts;case"ENTRIES_LINK":return e.entryFrom.ts;case"TIME_RANGE":return e.bounds.min;default:Pt.assertNever(e,`Invalid annotation type ${e}`)}}#a(e){switch(e.type){case"ENTRY_LABEL":return e.label.length>0;case"ENTRIES_LINK":return!!e.entryTo;case"TIME_RANGE":return e.bounds.range>0}}performUpdate(){let e={annotations:this.#i,annotationsHiddenSetting:this.#t,annotationEntryToColorMap:this.#e,onAnnotationClick:t=>{this.contentElement.dispatchEvent(new Dt(t))},onAnnotationHover:t=>{this.contentElement.dispatchEvent(new Et(t))},onAnnotationHoverOut:()=>{this.contentElement.dispatchEvent(new Rt)},onAnnotationDelete:t=>{this.contentElement.dispatchEvent(new Mt(t))}};this.#s(e,{},this.contentElement)}};function $a(i){switch(i.type){case"ENTRY_LABEL":{let e=pe.Name.forEntry(i.entry);return X(q.entryLabelDescriptionLabel,{PH1:e,PH2:i.label})}case"TIME_RANGE":{let e=lt.TimeUtilities.formatMicroSecondsAsMillisFixedExpanded(i.bounds.min),t=lt.TimeUtilities.formatMicroSecondsAsMillisFixedExpanded(i.bounds.max);return X(q.timeRangeDescriptionLabel,{PH1:e,PH2:t})}case"ENTRIES_LINK":{if(!i.entryTo)return"";let e=pe.Name.forEntry(i.entryFrom),t=pe.Name.forEntry(i.entryTo);return X(q.entryLinkDescriptionLabel,{PH1:e,PH2:t})}default:Pt.assertNever(i,"Unsupported annotation")}}function as(i){let e=_e.Color.parse(i)?.asLegacyColor(),t="--app-color-performance-sidebar-label-text-dark",s=_e.Color.parse(Sn.ThemeSupport.instance().getComputedValue(t))?.asLegacyColor();return!e||!s?`var(${t})`:_e.ColorUtils.contrastRatio(e.rgba(),s.rgba())>=4.5?`var(${t})`:"var(--app-color-performance-sidebar-label-text-light)"}function Ca(i,e){switch(i.type){case"ENTRY_LABEL":{let t=pe.Name.forEntry(i.entry),s=e.get(i.entry)??"",o=as(s),n={backgroundColor:s,color:o};return Ce`
            <span class="annotation-identifier" style=${Ve.Directives.styleMap(n)}>
              ${t}
            </span>
      `}case"TIME_RANGE":{let t=wn.TraceBounds.BoundsManager.instance().state()?.milli.entireTraceBounds.min??0,s=Math.round(pe.Helpers.Timing.microToMilli(i.bounds.min)-t),o=Math.round(pe.Helpers.Timing.microToMilli(i.bounds.max)-t);return Ce`
            <span class="annotation-identifier time-range">
              ${s} - ${o} ms
            </span>
      `}case"ENTRIES_LINK":{let t=pe.Name.forEntry(i.entryFrom),s=e.get(i.entryFrom)??"",o=as(s),n={backgroundColor:s,color:o};return Ce`
        <div class="entries-link">
          <span class="annotation-identifier" style=${Ve.Directives.styleMap(n)}>
            ${t}
          </span>
          <devtools-icon name="arrow-forward" class="inline-icon large">
          </devtools-icon>
          ${Pa(i,e)}
        </div>
    `}default:Pt.assertNever(i,"Unsupported annotation type")}}function Pa(i,e){if(i.entryTo){let t=pe.Name.forEntry(i.entryTo),s=e.get(i.entryTo)??"",o=as(s),n={backgroundColor:s,color:o};return Ce`
      <span class="annotation-identifier" style=${Ve.Directives.styleMap(n)}>
        ${t}
      </span>`}return Ve.nothing}function Ma(i){switch(i.type){case"ENTRY_LABEL":return"entry-label";case"TIME_RANGE":return"time-range";case"ENTRIES_LINK":return"entries-link";default:Pt.assertNever(i,"unknown annotation type")}}function Da(){return Ce`<div class="annotation-tutorial-container">
    ${X(q.annotationGetStarted)}
      <div class="tutorial-card">
        <div class="tutorial-image"><img src=${Ta}></div>
        <div class="tutorial-title">${X(q.entryLabelTutorialTitle)}</div>
        <div class="tutorial-description">${X(q.entryLabelTutorialDescription)}</div>
      </div>
      <div class="tutorial-card">
        <div class="tutorial-image"><img src=${Sa}></div>
        <div class="tutorial-title">${X(q.entryLinkTutorialTitle)}</div>
        <div class="tutorial-description">${X(q.entryLinkTutorialDescription)}</div>
      </div>
      <div class="tutorial-card">
        <div class="tutorial-image"><img src=${ka}></div>
        <div class="tutorial-title">${X(q.timeRangeTutorialTitle)}</div>
        <div class="tutorial-description">${X(q.timeRangeTutorialDescription)}</div>
      </div>
      <div class="tutorial-card">
        <div class="tutorial-image"><img src=${La}></div>
        <div class="tutorial-title">${X(q.deleteAnnotationTutorialTitle)}</div>
        <div class="tutorial-description">${X(q.deleteAnnotationTutorialDescription)}</div>
      </div>
    </div>`}var Tn=(i,e,t)=>{xa(Ce`
      <style>${bn}</style>
      <span class="annotations">
        ${i.annotations.length===0?Da():Ce`
            ${i.annotations.map(s=>{let o=$a(s);return Ce`
                <div class="annotation-container"
                  @click=${()=>i.onAnnotationClick(s)}
                  @mouseover=${()=>s.type==="ENTRY_LABEL"?i.onAnnotationHover(s):null}
                  @mouseout=${()=>s.type==="ENTRY_LABEL"?i.onAnnotationHoverOut():null}
                  aria-label=${o}
                  tabindex="0"
                  jslog=${gi.item(`timeline.annotation-sidebar.annotation-${Ma(s)}`).track({click:!0,resize:!0})}
                >
                  <div class="annotation">
                    ${Ca(s,i.annotationEntryToColorMap)}
                    <span class="label">
                      ${s.type==="ENTRY_LABEL"||s.type==="TIME_RANGE"?s.label:""}
                    </span>
                  </div>
                  <button class="delete-button" aria-label=${X(q.deleteButton,{PH1:o})} @click=${n=>{n.stopPropagation(),i.onAnnotationDelete(s)}} jslog=${gi.action("timeline.annotation-sidebar.delete").track({click:!0})}>
                    <devtools-icon class="bin-icon extra-large" name="bin"></devtools-icon>
                  </button>
                </div>`})}
            <setting-checkbox class="visibility-setting" .data=${{setting:i.annotationsHiddenSetting,textOverride:"Hide annotations"}}>
            </setting-checkbox>`}
    </span>`,t)};var Hn={};$(Hn,{DEFAULT_VIEW:()=>Un,SidebarInsightsTab:()=>At});import*as En from"./../../../models/trace/trace.js";import"./../../../ui/components/buttons/buttons.js";import*as ds from"./../../../ui/legacy/legacy.js";import*as dt from"./../../../ui/lit/lit.js";import*as Rn from"./../utils/utils.js";import*as Ht from"./insights/insights.js";var Ln=`@scope to (devtools-widget > *){:host{display:flex;flex-flow:column nowrap;flex-grow:1}.insight-sets-wrapper{display:flex;flex-flow:column nowrap;flex-grow:1;details{flex-grow:0}details[open]{flex-grow:1;border-bottom:1px solid var(--sys-color-divider)}summary{background-color:var(--sys-color-surface2);border-bottom:1px solid var(--sys-color-divider);overflow:hidden;padding:2px 5px;text-overflow:ellipsis;white-space:nowrap;font:var(--sys-typescale-body4-medium);display:flex;align-items:center;&:focus{background-color:var(--sys-color-tonal-container)}&::marker{color:var(--sys-color-on-surface-subtle);font-size:11px;line-height:1}details:first-child &{border-top:1px solid var(--sys-color-divider)}}}.zoom-button{margin-left:auto}.zoom-icon{visibility:hidden;&.active devtools-button{visibility:visible}}.dropdown-icon{flex:none;&.active devtools-button{transform:rotate(90deg)}}}
/*# sourceURL=${import.meta.resolve("./sidebarInsightsTab.css")} */`;var Dn={};$(Dn,{SidebarSingleInsightSet:()=>Ut});import*as ls from"./../../../core/i18n/i18n.js";import*as $n from"./../../../models/ai_assistance/ai_assistance.js";import*as Cn from"./../../../models/trace/trace.js";import*as cs from"./../../../ui/legacy/legacy.js";import*as ue from"./../../../ui/lit/lit.js";import*as g from"./insights/insights.js";var In=`:host{display:block;padding:5px 8px}.passed-insights-section{margin-top:var(--sys-size-5);summary{font-weight:var(--ref-typeface-weight-medium)}}
/*# sourceURL=${import.meta.resolve("./sidebarSingleInsightSet.css")} */`;var{html:ct}=ue.StaticHtml,Ea={Cache:g.Cache.Cache,CharacterSet:g.CharacterSet.CharacterSet,CLSCulprits:g.CLSCulprits.CLSCulprits,DocumentLatency:g.DocumentLatency.DocumentLatency,DOMSize:g.DOMSize.DOMSize,DuplicatedJavaScript:g.DuplicatedJavaScript.DuplicatedJavaScript,FontDisplay:g.FontDisplay.FontDisplay,ForcedReflow:g.ForcedReflow.ForcedReflow,ImageDelivery:g.ImageDelivery.ImageDelivery,INPBreakdown:g.INPBreakdown.INPBreakdown,LCPDiscovery:g.LCPDiscovery.LCPDiscovery,LCPBreakdown:g.LCPBreakdown.LCPBreakdown,LegacyJavaScript:g.LegacyJavaScript.LegacyJavaScript,ModernHTTP:g.ModernHTTP.ModernHTTP,NetworkDependencyTree:g.NetworkDependencyTree.NetworkDependencyTree,RenderBlocking:g.RenderBlocking.RenderBlocking,SlowCSSSelector:g.SlowCSSSelector.SlowCSSSelector,ThirdParties:g.ThirdParties.ThirdParties,Viewport:g.Viewport.Viewport},Pn={passedInsights:"Passed insights ({PH1})"},Ra=ls.i18n.registerUIStrings("panels/timeline/components/SidebarSingleInsightSet.ts",Pn),Ua=ls.i18n.getLocalizedString.bind(void 0,Ra),{widget:Mn}=cs.Widget,Ha=(i,e,t)=>{let{shownInsights:s,passedInsights:o,insightSetKey:n,parsedTrace:r,renderInsightComponent:a}=i;function l(){return!n||!r?ue.nothing:ct`${Mn(ht,{data:{insightSetKey:n,parsedTrace:r}})}`}function m(){let p=s.map(a),u=o.map(a);return ct`
      ${p}
      ${u.length?ct`
        <details class="passed-insights-section">
          <summary>${Ua(Pn.passedInsights,{PH1:u.length})}</summary>
          ${u}
        </details>
      `:ue.nothing}
    `}ue.render(ct`
    <style>${In}</style>
    <div class="navigation">
      ${l()}
      ${m()}
    </div>
  `,t)},Ut=class i extends cs.Widget.Widget{#i;#e=!1;#t=-1;#s={insightSetKey:null,activeCategory:Cn.Insights.Types.InsightCategory.ALL,activeInsight:null,parsedTrace:null};constructor(e,t=Ha){super(e,{useShadowDom:!0}),this.#i=t}set data(e){this.#s=e,this.requestUpdate()}willHide(){super.willHide(),window.clearTimeout(this.#t)}async highlightActiveInsight(){window.clearTimeout(this.#t),this.#e=!1,this.requestUpdate(),await this.updateComplete,this.#e=!0,this.requestUpdate(),this.#t=window.setTimeout(()=>{this.#e=!1,this.requestUpdate()},2e3)}static categorizeInsights(e,t,s){if(!e||!(e instanceof Map))return{shownInsights:[],passedInsights:[]};let o=e.get(t);if(!o)return{shownInsights:[],passedInsights:[]};let n=[],r=[];for(let[a,l]of Object.entries(o.model))!l||!Rs({activeCategory:s,insightCategory:l.category})||(l.state==="pass"?r.push({insightName:a,model:l}):n.push({insightName:a,model:l}));return{shownInsights:n,passedInsights:r}}#n(e,t,s){if(!this.#s.parsedTrace)return ue.nothing;let{insightName:o,model:n}=t,r=this.#s.activeInsight,a=$n.AIContext.AgentFocus.fromInsight(this.#s.parsedTrace,n),l=r?.model===n,m=Ea[o],p={selected:l,model:n,bounds:e.bounds,insightSetKey:e.id,agentFocus:a,fieldMetrics:s},u=[{componentClass:m,widgetConfig:p}],h=ue.Directives.repeat(u,f=>f.widgetConfig.model,f=>ct`<devtools-widget class="insight-component-widget" ?highlight-insight=${l&&this.#e}
        ${Mn(f.componentClass,f.widgetConfig)}
      ></devtools-widget>`);return ct`${h}`}performUpdate(){let{parsedTrace:e,insightSetKey:t}=this.#s;if(!e?.insights||!t||!(e.insights instanceof Map))return;let s=e.insights.get(t);if(!s)return;let o=jt(e,t),{shownInsights:n,passedInsights:r}=i.categorizeInsights(e.insights,t,this.#s.activeCategory),a={shownInsights:n,passedInsights:r,insightSetKey:t,parsedTrace:e,renderInsightComponent:l=>this.#n(s,l,o)};this.#i(a,void 0,this.contentElement)}};var{html:Nt}=dt,{widget:Na}=ds.Widget,Un=(i,e,t)=>{let{parsedTrace:s,labels:o,activeInsightSet:n,activeInsight:r,selectedCategory:a,onInsightSetToggled:l,onInsightSetHovered:m,onInsightSetUnhovered:p,onZoomClick:u}=i,h=s.insights;if(!h)return;let f=h.size>1;dt.render(Nt`
    <style>${Ln}</style>
    <div class="insight-sets-wrapper">
      ${[...h.values()].map((T,y)=>{let{id:j,url:M}=T,N={insightSetKey:j,activeCategory:a,activeInsight:r,parsedTrace:s},b=T===n,G=Nt`
          <devtools-widget
            data-insight-set-key=${j}
            ${Na(Ut,{data:N})}
          ></devtools-widget>
        `;return f?Nt`<details ?open=${b}>
            <summary
              @click=${()=>l(T)}
              @mouseenter=${()=>m(T)}
              @mouseleave=${()=>p()}
              title=${M.href}>
              ${Fa(b)}
              <span>${o[y]}</span>
              <span class='zoom-button'
                @click=${mt=>{mt.stopPropagation(),u(T)}}
              >
                ${Aa(b)}
              </span>
            </summary>
            ${G}
          </details>`:G})}
    </div>
  `,t)};function Aa(i){let e=dt.Directives.classMap({"zoom-icon":!0,active:i});return Nt`
  <div class=${e}>
      <devtools-button .data=${{variant:"icon",iconName:"center-focus-weak",size:"SMALL"}}
    ></devtools-button></div>`}function Fa(i){let e=dt.Directives.classMap({"dropdown-icon":!0,active:i});return Nt`
    <div class=${e}>
      <devtools-button .data=${{variant:"icon",iconName:"chevron-right",size:"SMALL"}}
    ></devtools-button></div>
  `}var At=class i extends ds.Widget.Widget{static createWidgetElement(){let e=document.createElement("devtools-widget");return new i(e),e}#i;#e=null;#t=null;#s=En.Insights.Types.InsightCategory.ALL;#n=null;constructor(e,t=Un){super(e,{useShadowDom:!0}),this.#i=t}set parsedTrace(e){e!==this.#e&&(this.#e=e,this.#n=null,this.#e?.insights&&(this.#n=[...this.#e.insights.values()].at(0)??null),this.requestUpdate())}get activeInsight(){return this.#t}set activeInsight(e){e!==this.#t&&(this.#t=e,this.#t&&(this.#n=this.#e?.insights?.get(this.#t.insightSetKey)??null),this.requestUpdate())}setActiveInsightSet(e){if(this.#e?.insights){let t=this.#e.insights.get(e);t&&(this.#n=t,this.requestUpdate())}}#o(e){this.#n=this.#n===e?null:e,this.#n?.id!==this.#t?.insightSetKey&&this.element.dispatchEvent(new Ht.SidebarInsight.InsightDeactivated),this.requestUpdate()}#a(e){this.element.dispatchEvent(new Ht.SidebarInsight.InsightSetHovered(e.bounds))}#l(){this.element.dispatchEvent(new Ht.SidebarInsight.InsightSetHovered)}#d(e){this.element.dispatchEvent(new Ht.SidebarInsight.InsightSetZoom(e.bounds))}highlightActiveInsight(){if(!this.#t)return;this.element.shadowRoot?.querySelector(`[data-insight-set-key="${this.#t.insightSetKey}"]`)?.getWidget()?.highlightActiveInsight()}performUpdate(){if(!this.#e?.insights)return;let e=[...this.#e.insights.values()],t={parsedTrace:this.#e,labels:Rn.Helpers.createUrlLabels(e.map(({url:s})=>s)),activeInsightSet:this.#n,activeInsight:this.#t,selectedCategory:this.#s,onInsightSetToggled:this.#o.bind(this),onInsightSetHovered:this.#a.bind(this),onInsightSetUnhovered:this.#l.bind(this),onZoomClick:this.#d.bind(this)};this.#i(t,void 0,this.contentElement)}};var Mt=class i extends Event{removedAnnotation;static eventName="removeannotation";constructor(e){super(i.eventName,{bubbles:!0,composed:!0}),this.removedAnnotation=e}},Dt=class i extends Event{annotation;static eventName="revealannotation";constructor(e){super(i.eventName,{bubbles:!0,composed:!0}),this.annotation=e}},Et=class i extends Event{annotation;static eventName="hoverannotation";constructor(e){super(i.eventName,{bubbles:!0,composed:!0}),this.annotation=e}},Rt=class i extends Event{static eventName="annotationhoverout";constructor(){super(i.eventName,{bubbles:!0,composed:!0})}},za="insights",Ba=240,Oa=170,ms=class extends We.Widget.VBox{#i=new We.TabbedPane.TabbedPane;#e=new ps;#t=new us;#s=null;#n=Nn.Settings.Settings.instance().createSetting("timeline-sidebar-opened-at-least-once",!1);constructor(){super(),this.setMinimumSize(Oa,0),this.#i.appendTab("insights","Insights",this.#e,void 0,void 0,!1,!1,0,"timeline.insights-tab"),this.#i.appendTab("annotations","Annotations",this.#t,void 0,void 0,!1,!1,1,"timeline.annotations-tab"),this.#i.selectTab("insights")}wasShown(){super.wasShown(),this.#n.set(!0),this.#i.show(this.element),this.#o(),this.#s&&(this.element.dispatchEvent(new pi(this.#s.model,this.#s.insightSetKey)),this.#s=null),this.#i.selectedTabId==="insights"&&this.#i.tabIsDisabled("insights")&&this.#i.selectTab("annotations")}willHide(){super.willHide();let e=this.#e.getActiveInsight();this.#s=e,e&&this.element.dispatchEvent(new ui)}setAnnotations(e,t){this.#t.setAnnotations(e,t),this.#o()}#o(){let e=this.#t.deduplicatedAnnotations();this.#i.setBadge("annotations",e.length>0?e.length.toString():null)}setParsedTrace(e){this.#e.setParsedTrace(e),this.#i.setTabEnabled("insights",!!(e?.insights&&e.insights.size>0))}setActiveInsight(e,t){this.#e.setActiveInsight(e,t),e&&this.#i.selectTab("insights")}openInsightsTab(){this.#i.selectTab("insights")}setActiveInsightSet(e){this.#e.setActiveInsightSet(e)}sidebarHasBeenOpened(){return this.#n.get()}},ps=class extends We.Widget.VBox{#i=At.createWidgetElement();constructor(){super(),this.element.classList.add("sidebar-insights"),this.#e().show(this.element)}#e(){return We.Widget.Widget.get(this.#i)}setParsedTrace(e){let t=this.#e();t.parsedTrace=e}getActiveInsight(){return this.#e().activeInsight}setActiveInsight(e,t){let s=this.#e();s.activeInsight=e,t.highlight&&e&&s.updateComplete.then(()=>{s.highlightActiveInsight()})}setActiveInsightSet(e){this.#e().setActiveInsightSet(e)}},us=class extends We.Widget.VBox{#i=new Ct;constructor(){super(),this.element.classList.add("sidebar-annotations"),this.#i.show(this.element)}setAnnotations(e,t){this.#i.setData({annotations:e,annotationEntryToColorMap:t})}deduplicatedAnnotations(){return this.#i.deduplicatedAnnotations()}};var Xn={};$(Xn,{TIMELINE_RANGE_SUMMARY_VIEW_DEFAULT_VIEW:()=>jn,TimelineRangeSummaryView:()=>bs,statsForTimeRange:()=>Kn});import*as ys from"./../../../core/platform/platform.js";import*as se from"./../../../models/trace/trace.js";import*as ws from"./../../../ui/legacy/legacy.js";import*as xs from"./../../../ui/lit/lit.js";var Fn=`:host{display:block;height:100%;container-type:inline-size}.timeline-details-range-summary{display:flex;padding:var(--sys-size-4) 0 0;height:100%}.timeline-tree-view{border-left:var(--sys-size-1) solid var(--sys-color-divider)}@container (max-width: 450px){.timeline-details-range-summary{display:grid;grid-template-rows:1fr minmax(50px,1fr);gap:var(--sys-size-4)}.timeline-summary{width:100%}.timeline-tree-view{border-left:none}}.timeline-summary{flex-grow:0}
/*# sourceURL=${import.meta.resolve("./timelineRangeSummaryView.css")} */`;var fs={};$(fs,{CATEGORY_SUMMARY_DEFAULT_VIEW:()=>Vn,CategorySummary:()=>Ft});import*as Pe from"./../../../core/i18n/i18n.js";import*as _n from"./../../../ui/components/buttons/buttons.js";import*as hi from"./../../../ui/legacy/legacy.js";import*as hs from"./../../../ui/lit/lit.js";var zn=`@scope to (devtools-widget > *){.timeline-summary{max-height:100%;overflow:hidden auto;scrollbar-width:thin;font-size:var(--sys-typescale-body4-size);flex-direction:column;padding:0 var(--sys-size-6) var(--sys-size-4) var(--sys-size-8);min-width:192px;&.is-in-ai-widget{padding:0}}.summary-range{font-weight:var(--ref-typeface-weight-medium);height:24.5px;line-height:22px}.category-summary{gap:var(--sys-size-4);display:flex;flex-direction:column}.category-row{min-height:16px;line-height:16px}.category-swatch{display:inline-block;width:var(--sys-size-6);height:var(--sys-size-6);margin-right:var(--sys-size-4);top:var(--sys-size-1);position:relative;border:var(--sys-size-1) solid var(--sys-color-neutral-outline)}.category-name{display:inline;word-break:break-all}.category-value{text-align:right;position:relative;float:right;z-index:0;width:var(--sys-size-19)}.background-bar-container{position:absolute;inset:0 0 0 var(--sys-size-3);z-index:-1}.background-bar{width:100%;float:right;height:var(--sys-size-8);background-color:var(--sys-color-surface-yellow);border-bottom:var(--sys-size-1) solid var(--sys-color-yellow-outline)}}
/*# sourceURL=${import.meta.resolve("./timelineSummary.css")} */`;var{render:_a,html:Bn}=hs,gs={total:"Total",rangeSS:"Range:  {PH1} \u2013 {PH2}"},Va=Pe.i18n.registerUIStrings("panels/timeline/components/TimelineSummary.ts",gs),On=Pe.i18n.getLocalizedString.bind(void 0,Va),Vn=(i,e,t)=>{let s=hs.Directives.classMap({"timeline-summary":!0,"is-in-ai-widget":!!i.isInAIWidget});_a(Bn`
        <style>${zn}</style>
        <style>@scope to (devtools-widget > *) { ${hi.inspectorCommonStyles} }</style>
        <style>@scope to (devtools-widget > *) { ${_n.textButtonStyles} }</style>
        <div class=${s}>
            <div class="summary-range">${On(gs.rangeSS,{PH1:Pe.TimeUtilities.millisToString(i.rangeStart),PH2:Pe.TimeUtilities.millisToString(i.rangeEnd)})}</div>
            <div class="category-summary">
                ${i.categories.map(o=>Bn`
                        <div class="category-row">
                        <div class="category-swatch" style="background-color: ${o.color};"></div>
                        <div class="category-name">${o.title}</div>
                        <div class="category-value">
                            ${Pe.TimeUtilities.preciseMillisToString(o.value)}
                            <div class="background-bar-container">
                                <div class="background-bar" style='width: ${(o.value*100/i.total).toFixed(1)}%;'></div>
                            </div>
                        </div>
                        </div>`)}
                <div class="category-row">
                    <div class="category-swatch"></div>
                    <div class="category-name">${On(gs.total)}</div>
                    <div class="category-value">
                        ${Pe.TimeUtilities.preciseMillisToString(i.total)}
                        <div class="background-bar-container">
                            <div class="background-bar"></div>
                        </div>
                    </div>
                </div>
              </div>
        </div>
        </div>

      </div>`,t)},Ft=class extends hi.Widget.Widget{#i;#e=0;#t=0;#s=0;#n=[];#o=!1;constructor(e,t){super(e),this.#i=t??Vn,this.requestUpdate()}set data(e){this.#e=e.rangeStart,this.#t=e.rangeEnd,this.#s=e.total,this.#n=e.categories,this.#o=!!e.isInAIWidget,this.requestUpdate()}performUpdate(){let e={rangeStart:this.#e,rangeEnd:this.#t,total:this.#s,categories:this.#n,isInAIWidget:this.#o};this.#i(e,void 0,this.contentElement)}};var{render:Wn,html:qn}=xs,{widget:Wa}=ws.Widget,vs=Symbol("categoryBreakdownCache"),jn=(i,e,t)=>{let{parsedTrace:s,events:o,startTime:n,endTime:r}=i;if(!o||!s){Wn(qn`<div class="timeline-details-range-summary"></div>`,t);return}let a=se.Helpers.Timing.microToMilli(s.data.Meta.traceBounds.min),l=Kn(o,n,r),m=n-a,p=r-a,u=0;for(let f in l)u+=l[f];let h=[];for(let f in se.Styles.getCategoryStyles()){let T=se.Styles.getCategoryStyles()[f];if(T.name===se.Styles.EventCategory.IDLE)continue;let y=l[T.name];y&&h.push({value:y,color:T.getCSSValue(),title:T.title})}h.sort((f,T)=>T.value-f.value),Wn(qn`
    <style>${Fn}</style>
    <div class="timeline-details-range-summary">
      <devtools-widget class="timeline-summary"
        ${Wa(Ft,{data:{rangeStart:m,rangeEnd:p,categories:h,total:u,isInAIWidget:i.isInAIWidget}})}
      ></devtools-widget>
      ${i.thirdPartyTreeTemplate??xs.nothing}
    </div>
  `,t)},bs=class extends ws.Widget.Widget{#i;#e;constructor(e,t=jn){super(e,{useShadowDom:!0}),this.#i=t,this.requestUpdate()}set data(e){this.#e=e,this.requestUpdate()}performUpdate(){this.#e&&this.#i(this.#e,void 0,this.contentElement)}};function Kn(i,e,t){if(!i.length)return{idle:t-e};a(i);let s=r(n(t),n(e)),o=Object.values(s).reduce((l,m)=>l+m,0);return s.idle=Math.max(0,t-e-o),s;function n(l){let m={},p=i[vs];for(let u in p){let h=p[u],f=ys.ArrayUtilities.upperBound(h.time,l,ys.ArrayUtilities.DEFAULT_COMPARATOR),T;if(f===0)T=0;else if(f===h.time.length)T=h.value[h.value.length-1];else{let y=h.time[f-1],j=h.time[f],M=h.value[f-1],N=h.value[f];T=M+(N-M)*(l-y)/(j-y)}m[u]=T}return m}function r(l,m){let p=Object.assign({},l);for(let u in m)p[u]-=m[u];return p}function a(l){if(l[vs])return;let m={},p=[],u=0;se.Helpers.Trace.forEachEvent(l,{onStartEvent:T,onEndEvent:y});function h(M,N){let b=m[M];if(b||(b={time:[],value:[]},m[M]=b),b.time.length&&b.time[b.time.length-1]===N||u>N)return;let G=b.value.length>0?b.value[b.value.length-1]:0;b.value.push(G+N-u),b.time.push(N)}function f(M,N,b){M&&h(M,b),u=b,N&&h(N,b)}function T(M){let{startTime:N}=se.Helpers.Timing.eventTimingsMilliSeconds(M),b=se.Styles.getEventStyle(M.name)?.category.name||se.Styles.getCategoryStyles().other.name,G=p.length?p[p.length-1]:null;b!==G&&f(G||null,b,N),p.push(b)}function y(M){let{endTime:N}=se.Helpers.Timing.eventTimingsMilliSeconds(M),b=p.pop(),G=p.length?p[p.length-1]:null;b!==G&&f(b||null,G||null,N||0)}let j=l;j[vs]=m}}export{Ts as Breadcrumbs,Ps as BreadcrumbsUI,Ws as CWVMetrics,js as DetailsView,Gs as ExportTraceOptions,ao as FieldSettingsDialog,go as IgnoreListSetting,yo as InteractionBreakdown,Ro as LayoutShiftDetails,Jo as LiveMetricsView,Bo as MetricCard,cn as NetworkRequestDetails,on as NetworkRequestTooltip,pn as NetworkTrackWidget,so as OriginMap,yn as RelatedInsightChips,An as Sidebar,kn as SidebarAnnotationsTab,Hn as SidebarInsightsTab,Dn as SidebarSingleInsightSet,Xn as TimelineRangeSummaryView,fs as TimelineSummary,Fs as Utils};
//# sourceMappingURL=components.js.map
