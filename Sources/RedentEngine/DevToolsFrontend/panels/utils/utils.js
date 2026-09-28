import"./../../ui/kit/kit.js";import"./../../ui/components/icon_button/icon_button.js";import*as i from"./../../core/common/common.js";import*as w from"./../../core/i18n/i18n.js";import*as b from"./../../core/sdk/sdk.js";import*as H from"./../../models/formatter/formatter.js";import*as C from"./../../models/persistence/persistence.js";import*as M from"./../../ui/components/diff_view/diff_view.js";import{Directives as U,html as d}from"./../../ui/lit/lit.js";import*as $ from"./../common/common.js";import*as P from"./../snippets/snippets.js";var{ref:W,styleMap:E,ifDefined:B}=U,f={requestContentHeadersOverridden:"Both request content and headers are overridden",requestContentOverridden:"Request content is overridden",requestHeadersOverridden:"Request headers are overridden",thirdPartyPhaseout:"Cookies for this request are blocked either because of Chrome flags or browser configuration. Learn more in the Issues panel.",resourceTypeWithThrottling:"{PH1} (throttled to {PH2})",requestFailed:"{PH1} request failed",prefetchFailed:"{PH1} prefetch request failed"},V=w.i18n.registerUIStrings("panels/utils/utils.ts",f),u=w.i18n.getLocalizedString.bind(void 0,V),N=class h{static isFailedNetworkRequest(e){if(!e)return!1;if(e.failed&&!e.statusCode||e.statusCode>=400)return!0;let t=e.signedExchangeInfo();return!!(t!==null&&t.errors||e.corsErrorStatus())}static getIconForNetworkRequest(e){let t=e.resourceType();if(h.isFailedNetworkRequest(e)){let s,c;return e.resourceType()===i.ResourceType.resourceTypes.Prefetch||e.isPreloadRequest()?(s="warning-filled",e.resourceType()===i.ResourceType.resourceTypes.Prefetch?c=u(f.prefetchFailed,{PH1:t.title()}):c=u(f.requestFailed,{PH1:t.title()})):(c=u(f.requestFailed,{PH1:t.title()}),s="cross-circle-filled"),d`<devtools-icon
          class="icon"
          name=${s}
          title=${c}
          role=img
        ></devtools-icon>`}if(e.hasThirdPartyCookiePhaseoutIssue())return d`<devtools-icon
        class="icon"
        name="warning-filled"
        role=img
        title=${u(f.thirdPartyPhaseout)}
      ></devtools-icon>`;let l=e.hasOverriddenHeaders(),o=e.hasOverriddenContent,r;(l||o)&&(l&&o?r=u(f.requestContentHeadersOverridden):o?r=u(f.requestContentOverridden):r=u(f.requestHeadersOverridden));let n=i.ResourceType.ResourceType.fromMimeType(e.mimeType);n!==t&&n!==i.ResourceType.resourceTypes.Other&&(t===i.ResourceType.resourceTypes.Fetch||n===i.ResourceType.resourceTypes.Image||t===i.ResourceType.resourceTypes.Other&&n===i.ResourceType.resourceTypes.Script)&&(t=n);let a;if(t===i.ResourceType.resourceTypes.Image)a=d`<div class="image icon">
        <img
          class="image-network-icon-preview"
          title=${m(e)}
          alt=${m(e)}
          ${W(s=>{s&&e.populateImageSource(s)})}
        />
      </div>`;else if(t!==i.ResourceType.resourceTypes.Manifest&&i.ResourceType.ResourceType.simplifyContentType(e.mimeType)==="application/json")a=d`<devtools-icon
          class="icon" name="file-json" title=${m(e)} role=img
          style="color:var(--icon-file-script)">
        </devtools-icon>`;else{let{iconName:s,color:c}=h.iconDataForResourceType(t);a=d`<devtools-icon
          class="icon" name=${s} title=${m(e)}
          style=${E({color:c})}>
        </devtools-icon>`}if(r)return d`<div class="network-override-marker">${a}</div>`;return a;function m(s){if(r)return r;let c=b.NetworkManager.MultitargetNetworkManager.instance().appliedRequestConditions(s);if(!c?.urlPattern)return s.resourceType().title();let p=typeof c?.conditions.title=="string"?c?.conditions.title:c?.conditions.title();return u(f.resourceTypeWithThrottling,{PH1:s.resourceType().title(),PH2:p})}}static iconDataForResourceType(e){return e.isDocument()?{iconName:"file-document"}:e.isImage()?{iconName:"file-image",color:"var(--icon-file-image)"}:e.isFont()?{iconName:"file-font"}:e.isScript()?{iconName:"file-script"}:e.isStyleSheet()?{iconName:"file-stylesheet"}:e.name()===i.ResourceType.resourceTypes.Manifest.name()?{iconName:"file-manifest"}:e.name()===i.ResourceType.resourceTypes.Wasm.name()?{iconName:"file-wasm"}:e.name()===i.ResourceType.resourceTypes.WebSocket.name()||e.name()===i.ResourceType.resourceTypes.DirectSocket.name()?{iconName:"file-websocket"}:e.name()===i.ResourceType.resourceTypes.Media.name()?{iconName:"file-media"}:e.name()===i.ResourceType.resourceTypes.Fetch.name()||e.name()===i.ResourceType.resourceTypes.XHR.name()?{iconName:"file-fetch-xhr"}:{iconName:"file-generic"}}static getIconForSourceFile(e){let t=C.Persistence.PersistenceImpl.instance().binding(e),l=C.NetworkPersistenceManager.NetworkPersistenceManager.instance(),o="document",r=!1,n=!1;t?(P.ScriptSnippetFileSystem.isSnippetsUISourceCode(t.fileSystem)&&(o="snippet"),r=!0,n=l.project()===t.fileSystem.project()):l.isActiveHeaderOverrides(e)?(r=!0,n=!0):P.ScriptSnippetFileSystem.isSnippetsUISourceCode(e)&&(o="snippet");let a=t?$.PersistenceUtils.PersistenceUtils.tooltipForUISourceCode(e):void 0;return d`<devtools-file-source-icon
        class="icon"
        name=${o} 
        title=${B(a)} 
        .data=${{contentType:e.contentType().name(),hasDotBadge:r,isDotPurple:n,iconType:o}}></devtools-file-source-icon>`}static async formatCSSChangesFromDiff(e){let t="  ",{originalLines:l,currentLines:o,rows:r}=M.DiffView.buildDiffRows(e),n=await D(l.join(`
`)),a=await D(o.join(`
`)),m="",s,c,p=!1;for(let{currentLineNumber:O,originalLineNumber:L,type:S}of r){if(S!=="deletion"&&S!=="addition")continue;let y=S==="deletion",x=y?l:o,g=y?L-1:O-1,F=x[g].trim(),{declarationIDToStyleRule:k,styleRuleIDToStyleRule:I}=y?n:a,T,R="";if(k.has(g)){T=k.get(g);let v=T.selector;v!==s&&v!==c&&(R+=`${v} {
`),R+=t,p=!0}else p&&(R=`}

`,p=!1),I.has(g)&&(T=I.get(g));let j=y?`/* ${F} */`:F;m+=R+j+`
`,y?s=T?.selector:c=T?.selector}return m.length>0&&(m+="}"),m}static highlightElement(e){e.scrollIntoViewIfNeeded(),e.animate([{offset:0,backgroundColor:"rgba(255, 255, 0, 0.2)"},{offset:.1,backgroundColor:"rgba(255, 255, 0, 0.7)"},{offset:1,backgroundColor:"transparent"}],{duration:2e3,easing:"cubic-bezier(0, 0, 0.2, 1)"})}};async function D(h){let e=await new Promise(o=>{let r=[];H.FormatterWorkerPool.formatterWorkerPool().parseCSS(h,(n,a)=>{r.push(...a),n&&o(r)})}),t=new Map,l=new Map;for(let o of e)if("styleRange"in o){let r=o.selectorText.split(`
`).pop()?.trim();if(!r)continue;let n={rule:o,selector:r};l.set(o.styleRange.startLine,n);for(let a of o.properties)t.set(a.range.startLine,n)}return{declarationIDToStyleRule:t,styleRuleIDToStyleRule:l}}export{N as PanelUtils};
//# sourceMappingURL=utils.js.map
