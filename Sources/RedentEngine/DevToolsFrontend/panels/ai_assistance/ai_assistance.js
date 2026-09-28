var Ci=Object.defineProperty;var j=(t,e)=>{for(var s in e)Ci(t,s,{get:e[s],enumerable:!0})};import"./../../ui/kit/kit.js";import*as U from"./../../core/common/common.js";import*as f from"./../../core/host/host.js";import*as rt from"./../../core/i18n/i18n.js";import*as bi from"./../../core/platform/platform.js";import*as R from"./../../core/root/root.js";import*as y from"./../../core/sdk/sdk.js";import*as g from"./../../models/ai_assistance/ai_assistance.js";import*as lt from"./../../models/badges/badges.js";import*as nt from"./../../models/workspace/workspace.js";import"./../../ui/components/buttons/buttons.js";import*as wi from"./../../ui/components/snackbars/snackbars.js";import*as xi from"./../../ui/helpers/helpers.js";import*as u from"./../../ui/legacy/legacy.js";import*as G from"./../../ui/lit/lit.js";import*as Ee from"./../../ui/visual_logging/visual_logging.js";import*as Re from"./../lighthouse/lighthouse.js";import*as ki from"./../network/forward/forward.js";import*as me from"./../network/network.js";import*as ue from"./../timeline/timeline.js";var Vt=`.toolbar-container{display:flex;flex-wrap:wrap;background-color:var(--sys-color-cdt-base-container);border-bottom:1px solid var(--sys-color-divider);flex:0 0 auto;justify-content:space-between}.ai-assistance-view-container{display:flex;flex-direction:column;width:100%;height:100%;align-items:center;overflow:hidden;& .fill-panel{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center}devtools-split-view{width:100%;height:100%}}.toolbar-feedback-link{color:var(--sys-color-primary);margin:0 var(--sys-size-3);height:auto;font-size:var(--sys-typescale-body4-size)}
/*# sourceURL=${import.meta.resolve("././aiAssistancePanel.css")} */`;import*as ne from"./../../core/sdk/sdk.js";import*as qt from"./../../models/ai_assistance/ai_assistance.js";import*as Ue from"./../../ui/lit/lit.js";import*as gt from"./../common/common.js";import*as Wt from"./../../core/common/common.js";import*as jt from"./../../core/platform/platform.js";import*as dt from"./../../models/ai_assistance/ai_assistance.js";import*as Bt from"./../../models/logs/logs.js";import*as _t from"./../../ui/components/markdown_view/markdown_view.js";import*as Ti from"./../../ui/lit/lit.js";var{html:ct}=Ti,Y=class extends _t.MarkdownView.MarkdownInsightRenderer{#s(e,s){return ct`<devtools-link @click=${i=>{i.preventDefault(),i.stopPropagation(),Wt.Revealer.reveal(e)}}>${jt.StringUtilities.trimEndWithMaxLength(s,100)}</devtools-link>`}#t(e,s){if(e.startsWith("#req-")){let i=Bt.NetworkLog.NetworkLog.instance().requests().find(o=>o.requestId()===e.substring(5));return i?this.#s(i,i.url()):ct`${s}`}if(e.startsWith("#file-")){let i=dt.ContextSelectionAgent.ContextSelectionAgent.getUISourceCodes().find(o=>dt.ContextSelectionAgent.ContextSelectionAgent.uiSourceCodeId.get(o)===Number(e.substring(6)));return i?this.#s(i,i.name()):ct`${s}`}return null}templateForToken(e){if(e.type==="link"){let s=this.#t(e.href,e.text);if(s)return s}if(e.type==="code"){let s=e.text.split(`
`);s[0]?.trim()==="css"&&(e.lang="css",e.text=s.slice(1).join(`
`))}if(e.type==="codespan"){let s=e.text.match(/^\[(.*)\]\((.+)\)$/);if(s?.[2]){let i=this.#t(s[2],s[1]);if(i)return i}}return super.templateForToken(e)}};var{html:Si}=Ue.StaticHtml,{until:Ii}=Ue.Directives,ze=class extends Y{mainDocumentURL;constructor(e=""){super(),this.mainDocumentURL=e}#s(e){let s=e.ownerDocument?.documentURL??"";return qt.AiUtils.isSameOrigin(this.mainDocumentURL,s)}templateForToken(e){if(e.type==="link"&&e.href.startsWith("#")){let s=this.#t(e.href);if(s){let i=s.type==="path"?this.#o(s.path,e.text):this.#i(s.nodeId,e.text);return Si`<span>${Ii(i.then(o=>o||e.text),e.text)}</span>`}}return super.templateForToken(e)}#t(e){if(e.startsWith("#path-"))return{type:"path",path:e.replace("#path-","")};if(e.startsWith("#1,HTML"))return{type:"path",path:e.slice(1)};let s="";if(e.startsWith("#node-")?s=e.replace("#node-",""):e.startsWith("#")&&(s=e.slice(1)),s.trim()!==""){let i=Number(s);if(Number.isInteger(i))return{type:"node",nodeId:i}}return null}async#i(e,s){if(e===void 0)return;let o=ne.TargetManager.TargetManager.instance().primaryPageTarget()?.model(ne.DOMModel.DOMModel);if(!o)return;let a=(await o.pushNodesByBackendIdsToFrontend(new Set([e])))?.get(e);return!a||!this.#s(a)?void 0:gt.DOMLinkifier.Linkifier.instance().linkify(a,{textContent:s})}async#o(e,s){let o=ne.TargetManager.TargetManager.instance().primaryPageTarget()?.model(ne.DOMModel.DOMModel);if(!o)return;let n=await o.pushNodeByPathToFrontend(e);if(!n)return;let a=o.nodeForId(n);return!a||!this.#s(a)?void 0:gt.DOMLinkifier.Linkifier.instance().linkify(a,{textContent:s})}};import*as ht from"./../../core/common/common.js";import*as Ht from"./../../core/platform/platform.js";import*as J from"./../../core/sdk/sdk.js";import*as ve from"./../../models/ai_assistance/ai_assistance.js";import*as Kt from"./../../models/logs/logs.js";import*as Gt from"./../../models/trace/trace.js";import*as Yt from"./../../ui/components/markdown_view/markdown_view.js";import*as Fe from"./../../ui/lit/lit.js";import*as ut from"./../common/common.js";var{html:pe}=Fe.StaticHtml,{until:Ai}=Fe.Directives,Ne=class extends Yt.MarkdownView.MarkdownInsightRenderer{options;constructor(e={}){super(),this.options=e}#s(e){if(!this.options.mainDocumentURL)return!0;let s=e.ownerDocument?.documentURL??"";return ve.AiUtils.isSameOrigin(this.options.mainDocumentURL,s)}#t(e,s){return pe`<devtools-link @click=${i=>{i.preventDefault(),i.stopPropagation(),ht.Revealer.reveal(e)}}>${Ht.StringUtilities.trimEndWithMaxLength(s,100)}</devtools-link>`}#i(e,s){let i=this.#o(e,s);if(i)return i;if(e.startsWith("#")){let o=this.#a(e);if(o){let n=o.type==="path"?this.#c(o.path,s):this.#r(o.nodeId,s);return pe`<span>${Ai(n.then(a=>a||s),s)}</span>`}if(this.options.lookupTraceEvent){let n=this.options.lookupTraceEvent(e.slice(1));if(n){let a=s,d="";return Gt.Types.Events.isSyntheticNetworkRequest(n)?d=n.args.data.url:a+=` (${n.name})`,pe`<a href="#" draggable=false .title=${d} @click=${l=>{l.stopPropagation(),ht.Revealer.reveal(new J.TraceObject.RevealableEvent(n))}}>${a}</a>`}}}return null}#o(e,s){if(e.startsWith("#req-")){let i=Kt.NetworkLog.NetworkLog.instance().requests().find(o=>o.requestId()===e.substring(5));return i?this.#t(i,i.url()):pe`${s}`}if(e.startsWith("#file-")){let i=ve.ListSources.ListSourcesTool.getUISourceCodes().find(o=>ve.ListSources.ListSourcesTool.uiSourceCodeId.get(o)===Number(e.substring(6)));return i?this.#t(i,i.name()):pe`${s}`}return null}#a(e){if(e.startsWith("#path-"))return{type:"path",path:e.replace("#path-","")};if(e.startsWith("#1,HTML"))return{type:"path",path:e.slice(1)};let s="";if(e.startsWith("#node-")?s=e.replace("#node-",""):e.startsWith("#")&&(s=e.slice(1)),s.trim()!==""){let i=Number(s);if(Number.isInteger(i))return{type:"node",nodeId:i}}return null}async#r(e,s){let o=J.TargetManager.TargetManager.instance().primaryPageTarget()?.model(J.DOMModel.DOMModel);if(!o)return;let a=(await o.pushNodesByBackendIdsToFrontend(new Set([e])))?.get(e);return!a||this.options.mainFrameId&&a.frameId()!==this.options.mainFrameId||!this.#s(a)?void 0:ut.DOMLinkifier.Linkifier.instance().linkify(a,{textContent:s})}async#c(e,s){let o=J.TargetManager.TargetManager.instance().primaryPageTarget()?.model(J.DOMModel.DOMModel);if(!o)return;let n=await o.pushNodeByPathToFrontend(e);if(!n)return;let a=o.nodeForId(n);return!a||!this.#s(a)?void 0:ut.DOMLinkifier.Linkifier.instance().linkify(a,{textContent:s})}templateForToken(e){if(e.type==="link"){let s=this.#i(e.href,e.text);if(s)return s}if(e.type==="code"){let s=e.text.split(`
`);s[0]?.trim()==="css"&&(e.lang="css",e.text=s.slice(1).join(`
`))}if(e.type==="codespan"){let s=e.text.match(/^\[(.*)\]\((.+)\)$/);if(s?.[2]){let i=this.#i(s[2],s[1]);if(i)return i}}return super.templateForToken(e)}};import"./../../ui/components/spinners/spinners.js";import*as et from"./../../core/host/host.js";import*as qs from"./../../core/i18n/i18n.js";import*as At from"./../../models/ai_assistance/ai_assistance.js";import"./../../ui/components/buttons/buttons.js";import*as Hs from"./../../ui/legacy/legacy.js";import{Directives as Io,html as le,render as Ao}from"./../../ui/lit/lit.js";var ns={};j(ns,{ChatInput:()=>ae,DEFAULT_VIEW:()=>os,MAX_IMAGE_FILE_SIZE_BYTES:()=>is});import"./../../ui/components/tooltips/tooltips.js";import*as We from"./../../core/i18n/i18n.js";import*as V from"./../../core/sdk/sdk.js";import*as I from"./../../models/ai_assistance/ai_assistance.js";import*as ts from"./../common/common.js";import*as vt from"./../utils/utils.js";import"./../../ui/components/buttons/buttons.js";import*as ss from"./../../ui/components/input/input.js";import*as Ve from"./../../ui/components/snackbars/snackbars.js";import*as X from"./../../ui/legacy/legacy.js";import*as M from"./../../ui/lit/lit.js";import*as Q from"./../../ui/visual_logging/visual_logging.js";var Jt=`*{box-sizing:border-box;margin:0;padding:0}:host{display:flex;flex-direction:column}.input-form{display:flex;flex-direction:column;padding:0 var(--sys-size-5) var(--sys-size-5) var(--sys-size-5);max-width:var(--sys-size-36);background-color:var(--sys-color-cdt-base-container);width:100%}.chat-readonly-container{display:flex;width:100%;max-width:var(--sys-size-36);justify-content:center;align-items:center;background-color:var(--sys-color-surface3);font:var(--sys-typescale-body4-regular);padding:var(--sys-size-5) 0;border-radius:var(--sys-shape-corner-medium-small);margin-bottom:var(--sys-size-5);color:var(--sys-color-on-surface-subtle)}.chat-input-container{width:100%;display:flex;position:relative;flex-direction:column;border:1px solid var(--sys-color-neutral-outline);border-radius:var(--sys-shape-corner-small);&:focus-within{outline:1px solid var(--sys-color-primary);border-color:var(--sys-color-primary)}&.disabled{background-color:var(--sys-color-state-disabled-container);border-color:transparent;& .chat-input-disclaimer{border-color:var(--sys-color-state-disabled)}}&.single-line-layout{flex-direction:row;justify-content:space-between;.chat-input{flex-shrink:1;padding:var(--sys-size-4)}.chat-input-actions{flex-shrink:0;padding-block:0;align-items:flex-end;padding-bottom:var(--sys-size-1)}}& .image-input-container{margin:var(--sys-size-3) var(--sys-size-4) 0;max-width:100%;width:fit-content;position:relative;devtools-button{position:absolute;top:calc(-1 * var(--sys-size-2));right:calc(-1 * var(--sys-size-3));border-radius:var(--sys-shape-corner-full);border:1px solid var(--sys-color-neutral-outline);background-color:var(--sys-color-cdt-base-container)}img{max-height:var(--sys-size-18);max-width:100%;border:1px solid var(--sys-color-neutral-outline);border-radius:var(--sys-shape-corner-small)}.loading{margin:var(--sys-size-4) 0;display:inline-flex;justify-content:center;align-items:center;height:var(--sys-size-18);width:var(--sys-size-19);background-color:var(--sys-color-surface3);border-radius:var(--sys-shape-corner-small);border:1px solid var(--sys-color-neutral-outline);devtools-spinner{color:var(--sys-color-state-disabled)}}}& .chat-input-disclaimer-container{display:flex;align-items:center;padding-right:var(--sys-size-3);flex-shrink:0}& .chat-input-disclaimer{display:flex;justify-content:center;align-items:center;font:var(--sys-typescale-body5-regular);border-right:1px solid var(--sys-color-divider);padding-right:8px;&.hide-divider{border-right:none}}@container --chat-ui-container (width < 400px){& .chat-input-disclaimer-container{display:none}}}.chat-input{scrollbar-width:none;field-sizing:content;resize:none;width:100%;max-height:84px;border:0;border-radius:var(--sys-shape-corner-small);font:var(--sys-typescale-body4-regular);line-height:18px;min-height:var(--sys-size-11);color:var(--sys-color-on-surface);background-color:var(--sys-color-cdt-base-container);padding:var(--sys-size-4) var(--sys-size-4) var(--sys-size-3) var(--sys-size-4);&::placeholder{opacity:60%}&:focus-visible{outline:0}&:disabled{color:var(--sys-color-state-disabled);background-color:transparent;border-color:transparent;&::placeholder{color:var(--sys-color-on-surface-subtle);opacity:100%}}}.chat-input-actions{display:flex;flex-direction:row;align-items:center;justify-content:space-between;padding-left:var(--sys-size-4);padding-right:var(--sys-size-2);gap:var(--sys-size-6);padding-bottom:var(--sys-size-2);& .chat-input-actions-left{flex:1 1 0;min-width:0}& .chat-input-actions-right{flex-shrink:0;display:flex;& .start-new-chat-button{padding-bottom:var(--sys-size-2);padding-right:var(--sys-size-3)}}}.chat-inline-button{padding-left:3px}.select-element{display:flex;gap:var(--sys-size-3);align-items:center;.resource-link{display:flex;background-color:var(--sys-color-cdt-base-container);align-items:center;cursor:pointer;padding:var(--sys-size-2) var(--sys-size-3);font:var(--sys-typescale-body5-regular);border:var(--sys-size-1) solid var(--sys-color-divider);border-radius:var(--sys-shape-corner-extra-small);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;min-width:0;line-height:1;& .title{vertical-align:middle;padding-right:var(--sys-size-2);font:var(--sys-typescale-body5-regular);overflow:hidden;text-overflow:ellipsis}& .remove-context,
    & .add-context{vertical-align:middle}&:focus-visible{outline:2px solid var(--sys-color-state-focus-ring)}devtools-icon,
    devtools-file-source-icon{display:inline-flex;vertical-align:middle;min-width:var(--sys-size-7);min-height:var(--sys-size-7)}&.disabled{border-style:dashed;border-color:var(--sys-color-neutral-outline);color:var(--sys-color-on-surface-light);devtools-icon,
      devtools-file-source-icon{--override-file-source-icon-color:var(
          --sys-color-on-surface-light-graphics
        );color:var(--sys-color-on-surface-light-graphics)!important}.title{color:var(--sys-color-on-surface-light);font-style:italic}}.network-override-marker{position:relative;float:left}.network-override-marker::before{content:var(--image-file-empty);width:var(--sys-size-4);height:var(--sys-size-4);border-radius:50%;outline:var(--sys-size-1) solid var(--icon-gap-focus-selected);left:11px;position:absolute;top:13px;z-index:1;background-color:var(--sys-color-purple-bright)}.image.icon{display:inline-flex;justify-content:center;align-items:center;vertical-align:middle;margin-right:var(--sys-size-3);img{max-width:var(--sys-size-7);max-height:var(--sys-size-7)}}}}.link{color:var(--text-link);text-decoration:underline;cursor:pointer}button.link{border:none;background:none;font:inherit;&:focus-visible{outline:var(--sys-size-2) solid var(--sys-color-state-focus-ring);outline-offset:0;border-radius:var(--sys-shape-corner-extra-small)}}.floaty{font:var(--sys-typescale-body4);color:var(--sys-color-on-surface);user-select:none;padding:0;margin:0;list-style-type:none;display:flex;flex-flow:row wrap;align-items:flex-end;gap:var(--sys-size-2);margin-bottom:var(--sys-size-2);li{background:var(--sys-color-surface3);border-radius:var(--sys-shape-corner-small);border:1px solid var(--sys-color-neutral-outline);padding:var(--sys-size-2) var(--sys-size-3);display:flex;flex-direction:row;align-items:center;gap:var(--sys-size-2);min-height:var(--sys-size-8)}.context-item{display:flex;flex-direction:row;align-items:center;gap:var(--sys-size-2)}.open-floaty{padding:0;border:none;margin-bottom:1px}}.chat-input-footer{display:flex;justify-content:center;padding-block:var(--sys-size-3);font:var(--sys-typescale-body5-regular);border-top:1px solid var(--sys-color-divider);text-wrap:balance;text-align:center;width:100%;&:not(.is-read-only){display:none;border:none;@container --chat-ui-container (width < 400px){display:flex}}}
/*# sourceURL=${import.meta.resolve("././components/chatInput.css")} */`;var pt={};j(pt,{compress:()=>mt,setCompressImplementationForTest:()=>Li});var Xt=Qt;function Li(t){Xt=t??Qt}async function mt(t){return await Xt(t)}async function Qt(t){let e=await createImageBitmap(t);try{let s=e.width,i=e.height;(s>1024||i>1024)&&(s>i?(i=Math.round(i*1024/s),s=1024):(s=Math.round(s*1024/i),i=1024));let o=new OffscreenCanvas(s,i),n=o.getContext("2d");if(!n)throw new Error("Failed to get 2d context");n.drawImage(e,0,0,s,i);let a=await o.convertToBlob({type:"image/jpeg",quality:.8});return{data:await new Promise((l,p)=>{let k=new FileReader;k.onloadend=()=>{let Pe=k.result.split(",")[1];l(Pe)},k.onerror=()=>p(new Error("Failed to read compressed blob")),k.readAsDataURL(a)}),mimeType:"image/jpeg"}}finally{e.close()}}var{html:S,Directives:{createRef:Mi,ref:$i}}=M,{widget:Ri}=X.Widget,fe={inputTextAriaDescription:"You can also use one of the suggested prompts above to start your conversation",revealContextDescription:"Reveal the selected context item in DevTools",learnAbout:"Learn about AI in DevTools"},w={sendButtonTitle:"Send",startNewChat:"Start new chat",cancelButtonTitle:"Cancel",selectAnElement:"Select an element",takeScreenshotButtonTitle:"Take screenshot",removeImageInputButtonTitle:"Remove image input",addImageButtonTitle:"Add image",pastConversation:"You\u2019re viewing a past conversation.",screenshotFailureMessage:"Failed to take a screenshot. Please try again.",uploadImageFailureMessage:"Failed to upload image. Please try again.",fileTooLargeMessage:"File is too large. Please select an image under 10MB.",addContext:"Add item for context",removeContextElement:"Remove element from context",removeContextRequest:"Remove request from context",removeContextFile:"Remove file from context",removeContextPerfInsight:"Remove performance insight from context",removeContextStorage:"Remove storage from context",removeContext:"Remove from context"},Ei=We.i18n.registerUIStrings("panels/ai_assistance/components/ChatInput.ts",fe),Oe=We.i18n.getLocalizedString.bind(void 0,Ei),b=We.i18n.lockedString,Di=80,Pi="image/jpeg",Zt=100,is=10*1024*1024,zi="relevant-data-link-chat",Ui="relevant-data-link-footer";function es(t){return t instanceof I.FileContext.FileContext?b(w.removeContextFile):t instanceof I.DOMNodeContext.DOMNodeContext?b(w.removeContextElement):t instanceof I.RequestContext.RequestContext?b(w.removeContextRequest):t instanceof I.PerformanceTraceContext.PerformanceTraceContext?b(w.removeContextPerfInsight):t instanceof I.StorageContext.StorageContext?b(w.removeContextStorage):b(w.removeContext)}var os=(t,e,s)=>{let i=M.Directives.classMap({"chat-input-container":!0,"single-line-layout":!t.context,disabled:t.isTextInputDisabled}),o=n=>{let a=M.Directives.classMap({"chat-input-disclaimer":!0,"hide-divider":!t.isLoading&&t.blockedByCrossOrigin});return S`
      <div class=${a}>
        <button
          class="link"
          role="link"
          aria-details=${n}
          jslog=${Q.link("open-ai-settings").track({click:!0})}
          @click=${d=>{d.preventDefault(),X.ViewManager.ViewManager.instance().showView("chrome-ai")}}
        >${b("Relevant data")}</button>&nbsp;${b("is sent to Google")}
        <devtools-tooltip
          id=${n}
          variant="rich"
        ><div class="info-tooltip-container">
          ${t.disclaimerText}
          <button
            class="link tooltip-link"
            role="link"
            jslog=${Q.link("open-ai-settings").track({click:!0})}
            @click=${()=>{X.ViewManager.ViewManager.instance().showView("chrome-ai")}}>${Oe(fe.learnAbout)}
          </button>
        </div></devtools-tooltip>
      </div>
    `};M.render(S`
    <style>${ss.textInputStyles}</style>
    <style>${Jt}</style>
    ${t.isReadOnly?S`
        <div
          class="chat-readonly-container"
          jslog=${Q.section("read-only")}
        >
          <span>${b(w.pastConversation)}</span>
          <devtools-button
            aria-label=${b(w.startNewChat)}
            class="chat-inline-button"
            @click=${t.onNewConversation}
            .data=${{variant:"text",title:b(w.startNewChat),jslogContext:"start-new-chat"}}
          >${b(w.startNewChat)}</devtools-button>
        </div>`:S`
        <form class="input-form" @submit=${t.onSubmit}>
          <div class=${i}>
            ${t.multimodalInputEnabled&&t.imageInput&&!t.isTextInputDisabled?S`
                <div class="image-input-container">
                  <devtools-button
                    aria-label=${b(w.removeImageInputButtonTitle)}
                    @click=${t.onRemoveImageInput}
                    .data=${{variant:"icon",size:"MICRO",iconName:"cross",title:b(w.removeImageInputButtonTitle)}}
                  ></devtools-button>
                  ${t.imageInput.isLoading?S`
                      <div class="loading">
                        <devtools-spinner></devtools-spinner>
                      </div>`:S`
                      <img src="data:${t.imageInput.mimeType};base64, ${t.imageInput.data}" alt="Image input" />`}
                </div>`:M.nothing}
            <textarea
              class="chat-input"
              .disabled=${t.isTextInputDisabled}
              wrap="hard"
              maxlength="10000"
              .value=${t.textInputValue}
              @keydown=${t.onTextAreaKeyDown}
              @paste=${t.onImagePaste}
              @dragover=${t.onImageDragOver}
              @drop=${t.onImageDrop}
              @input=${n=>{t.onTextInputChange(n.target.value)}}
              placeholder=${t.inputPlaceholder}
              jslog=${Q.textField("query").track({change:!0,keydown:"Enter"})}
              aria-description=${Oe(fe.inputTextAriaDescription)}
              ${$i(t.textAreaRef)}
            ></textarea>
            <div class="chat-input-actions">
              <div class="chat-input-actions-left">
                ${t.context?S`
                    <div class="select-element">
                      ${t.conversationType==="freestyler"?S`
                          <devtools-button
                            .data=${{variant:"icon_toggle",size:"SMALL",iconName:"select-element",toggledIconName:"select-element",toggleType:"primary-toggle",toggled:t.inspectElementToggled,title:b(w.selectAnElement),jslogContext:"select-element",disabled:t.isTextInputDisabled}}
                            @click=${t.onInspectElementClick}
                          ></devtools-button>`:M.nothing}
                      <div
                        class=${M.Directives.classMap({"resource-link":!0,disabled:!t.isContextSelected})}
                      >
                        ${t.context instanceof I.DOMNodeContext.DOMNodeContext?S`
                              <devtools-widget
                                class="title"
                                ${Ri(ts.DOMLinkifier.DOMNodeLink,{node:t.context.getItem(),options:{disabled:!t.isContextSelected,hiddenClassList:t.context.getItem().classNames().filter(n=>n.startsWith(I.Injected.AI_ASSISTANCE_CSS_CLASS_NAME)),ariaDescription:Oe(fe.revealContextDescription)}})}
                              ></devtools-widget>`:S`
                          ${t.context instanceof I.RequestContext.RequestContext?vt.PanelUtils.getIconForNetworkRequest(t.context.getItem()):t.context instanceof I.FileContext.FileContext?vt.PanelUtils.getIconForSourceFile(t.context.getItem()):t.context instanceof I.AccessibilityContext.AccessibilityContext?S`<devtools-icon class="icon" name="performance" title="Lighthouse"></devtools-icon>`:t.context instanceof I.PerformanceTraceContext.PerformanceTraceContext?S`<devtools-icon class="icon" name="performance" title="Performance"></devtools-icon>`:t.context instanceof I.StorageContext.StorageContext?S`<devtools-icon class="icon" name="table" title="Storage"></devtools-icon>`:M.nothing}
                            <span
                              role="button"
                              class="title"
                              tabindex="0"
                              @click=${t.onContextClick}
                              @keydown=${n=>{(n.key==="Enter"||n.key===" ")&&t.onContextClick()}}
                              aria-description=${Oe(fe.revealContextDescription)}
                            >${t.context.getTitle()}</span>`}
                        ${t.isContextSelected&&t.onContextRemoved?S`
                                  <devtools-button
                                    title=${es(t.context)}
                                    aria-label=${es(t.context)}
                                    class="remove-context"
                                    .iconName=${"cross"}
                                    .size=${"MICRO"}
                                    .jslogContext=${"context-removed"}
                                    .variant=${"icon"}
                                    @click=${t.onContextRemoved}></devtools-button>`:M.nothing}
                      ${!t.isContextSelected&&t.onContextAdd?S`
                                    <devtools-button
                                      title=${b(w.addContext)}
                                      aria-label=${b(w.addContext)}
                                      class="add-context"
                                      .iconName=${"plus"}
                                      .size=${"MICRO"}
                                      .jslogContext=${"context-added"}
                                      .variant=${"icon"}
                                      @click=${t.onContextAdd}></devtools-button>`:M.nothing}
                      </div>
                    </div>`:M.nothing}
              </div>
              <div class="chat-input-actions-right">
                <div class="chat-input-disclaimer-container">
                  ${o(zi)}
                </div>
                ${t.multimodalInputEnabled&&!t.blockedByCrossOrigin?S`
                    ${t.uploadImageInputEnabled?S`
                        <devtools-button
                          class="chat-input-button"
                          aria-label=${b(w.addImageButtonTitle)}
                          @click=${t.onImageUpload}
                          .data=${{variant:"icon",size:"REGULAR",disabled:t.isTextInputDisabled||t.imageInput?.isLoading,iconName:"add-photo",title:b(w.addImageButtonTitle),jslogContext:"upload-image"}}
                        ></devtools-button>`:M.nothing}
                    <devtools-button
                      class="chat-input-button"
                      aria-label=${b(w.takeScreenshotButtonTitle)}
                      @click=${t.onTakeScreenshot}
                      .data=${{variant:"icon",size:"REGULAR",disabled:t.isTextInputDisabled||t.imageInput?.isLoading,iconName:"photo-camera",title:b(w.takeScreenshotButtonTitle),jslogContext:"take-screenshot"}}
                    ></devtools-button>`:M.nothing}
                ${t.isLoading?S`
                    <devtools-button
                      class="chat-input-button"
                      aria-label=${b(w.cancelButtonTitle)}
                      @click=${t.onCancel}
                      .data=${{variant:"icon",size:"REGULAR",iconName:"record-stop",title:b(w.cancelButtonTitle),jslogContext:"stop"}}
                    ></devtools-button>`:t.blockedByCrossOrigin?S`
                      <devtools-button
                        class="start-new-chat-button"
                        aria-label=${b(w.startNewChat)}
                        @click=${t.onNewConversation}
                        .data=${{variant:"outlined",size:"SMALL",title:b(w.startNewChat),jslogContext:"start-new-chat"}}
                      >${b(w.startNewChat)}</devtools-button>`:S`
                      <devtools-button
                        class="chat-input-button"
                        aria-label=${b(w.sendButtonTitle)}
                        .data=${{type:"submit",variant:"icon",size:"REGULAR",disabled:t.isTextInputDisabled||t.isTextInputEmpty||t.imageInput?.isLoading,iconName:"send",title:b(w.sendButtonTitle),jslogContext:"send"}}
                      ></devtools-button>`}
              </div>
            </div>
          </div>
        </form>`}
    <footer
      class=${M.Directives.classMap({"chat-input-footer":!0,"is-read-only":t.isReadOnly})}
      jslog=${Q.section("footer")}
    >
      ${o(Ui)}
    </footer>
  `,s)},ae=class extends X.Widget.Widget{isLoading=!1;blockedByCrossOrigin=!1;isTextInputDisabled=!1;inputPlaceholder="";context=null;isContextSelected=!1;inspectElementToggled=!1;disclaimerText="";conversationType="freestyler";multimodalInputEnabled=!1;uploadImageInputEnabled=!1;isReadOnly=!1;textInputValue="";#s=Mi();#t;#i=-1;#o="";setInputValue(e){if(this.#s.value){let s=this.#s.value.maxLength,i=s>=0?e.substring(0,s):e;this.#s.value.value=i,this.#s.value.setSelectionRange(i.length,i.length),this.textInputValue=i,this.onTextChange(i)}this.performUpdate()}#a(){return!(this.#s?.value?.value??this.textInputValue).trim()}onTextSubmit=()=>{};onTextChange=()=>{};onContextClick=()=>{};onInspectElementClick=()=>{};onCancelClick=()=>{};onNewConversation=()=>{};onContextRemoved=null;onContextAdd=null;#r(e){let s=I.AiHistoryStorage.AiHistoryStorage.instance().getRecentPrompts();s.length&&(e===-1?(this.#i===-1&&(this.#o=this.#s.value?.value||""),this.#i<s.length-1&&(this.#i++,this.setInputValue(s[this.#i]))):this.#i>0?(this.#i--,this.setInputValue(s[this.#i])):this.#i===0&&(this.#i=-1,this.setInputValue(this.#o)))}async#c(){let e=V.TargetManager.TargetManager.instance().primaryPageTarget();if(!e)throw new Error("Could not find main target");let s=e.model(V.ScreenCaptureModel.ScreenCaptureModel);if(!s)throw new Error("Could not find model");let i=setTimeout(()=>{this.#t={isLoading:!0},this.performUpdate()},Zt),o=await s.captureScreenshot("jpeg",Di,"fromViewport");clearTimeout(i),o?(this.#t={isLoading:!1,data:o,mimeType:Pi,inputType:"screenshot"},this.performUpdate(),this.updateComplete.then(()=>{this.focusTextInput()})):(this.#t=void 0,this.performUpdate(),Ve.Snackbar.Snackbar.show({message:b(w.screenshotFailureMessage)}))}targetAdded(e){}targetRemoved(e){}#d(){this.#t=void 0,this.performUpdate(),this.updateComplete.then(()=>{this.focusTextInput()})}#e(e,s){if(this.conversationType!=="freestyler")return;let i=e?.files;if(!i||i.length===0)return;let o=Array.from(i).find(n=>n.type.startsWith("image/"));o&&(s.preventDefault(),this.#u(o))}#g=e=>{this.#e(e.clipboardData,e)};#h=e=>{this.conversationType==="freestyler"&&e.preventDefault()};#l=e=>{this.#e(e.dataTransfer,e)};async#u(e){if(e.size>is){Ve.Snackbar.Snackbar.show({message:b(w.fileTooLargeMessage)});return}let s=setTimeout(()=>{this.#t={isLoading:!0},this.performUpdate()},Zt);try{let i=await mt(e);this.#t={isLoading:!1,data:i.data,mimeType:i.mimeType,inputType:"uploaded-image"}}catch(i){console.error("Failed to compress image:",i),this.#t=void 0,Ve.Snackbar.Snackbar.show({message:b(w.uploadImageFailureMessage)})}clearTimeout(s),this.performUpdate(),this.updateComplete.then(()=>{this.focusTextInput()})}#m;constructor(e,s){super(e),this.#m=s??os}wasShown(){super.wasShown(),V.TargetManager.TargetManager.instance().addModelListener(V.ResourceTreeModel.ResourceTreeModel,V.ResourceTreeModel.Events.PrimaryPageChanged,this.#p,this)}willHide(){super.willHide(),V.TargetManager.TargetManager.instance().removeModelListener(V.ResourceTreeModel.ResourceTreeModel,V.ResourceTreeModel.Events.PrimaryPageChanged,this.#p,this)}#p(){this.#t=void 0,this.performUpdate()}performUpdate(){this.#m({inputPlaceholder:this.inputPlaceholder,isLoading:this.isLoading,blockedByCrossOrigin:this.blockedByCrossOrigin,isTextInputDisabled:this.isTextInputDisabled,context:this.context,isContextSelected:this.isContextSelected,inspectElementToggled:this.inspectElementToggled,isTextInputEmpty:this.#a(),disclaimerText:this.disclaimerText,conversationType:this.conversationType,multimodalInputEnabled:this.multimodalInputEnabled,imageInput:this.#t,uploadImageInputEnabled:this.uploadImageInputEnabled,isReadOnly:this.isReadOnly,textInputValue:this.textInputValue,textAreaRef:this.#s,onContextClick:this.onContextClick,onInspectElementClick:this.onInspectElementClick,onImagePaste:this.#g,onNewConversation:this.onNewConversation,onTextInputChange:e=>{this.textInputValue=e,this.onTextChange(e),this.requestUpdate()},onTakeScreenshot:this.#c.bind(this),onRemoveImageInput:this.#d.bind(this),onSubmit:this.onSubmit,onTextAreaKeyDown:this.onTextAreaKeyDown,onCancel:this.onCancel,onImageUpload:this.onImageUpload,onImageDragOver:this.#h,onImageDrop:this.#l,onContextRemoved:this.onContextRemoved,onContextAdd:this.onContextAdd},void 0,this.contentElement)}focusTextInput(){this.#s.value?.focus()}onSubmit=e=>{if(e.preventDefault(),this.#t?.isLoading)return;let s=!this.#t?.isLoading&&this.#t?.data?{inlineData:{data:this.#t.data,mimeType:this.#t.mimeType}}:void 0;!(this.#s.value?.value?.trim()??"")&&!s||(this.onTextSubmit(this.#s.value?.value??"",s,this.#t?.inputType),this.#t=void 0,this.#i=-1,this.#o="",this.setInputValue(""))};onTextAreaKeyDown=e=>{if(!(!e.target||!(e.target instanceof HTMLTextAreaElement))){if(e.key==="ArrowUp"){let{value:s,selectionStart:i,selectionEnd:o}=e.target;i===o&&s.lastIndexOf(`
`,i-1)===-1&&(e.preventDefault(),this.#r(-1));return}if(e.key==="ArrowDown"){let{selectionEnd:s,selectionStart:i,value:o}=e.target;i===s&&o.indexOf(`
`,s)===-1&&(e.preventDefault(),this.#r(1));return}if(e.key==="Enter"&&!e.shiftKey&&!e.isComposing){if(e.preventDefault(),!e.target?.value||this.#t?.isLoading)return;let s=!this.#t?.isLoading&&this.#t?.data?{inlineData:{data:this.#t.data,mimeType:this.#t.mimeType}}:void 0;this.onTextSubmit(e.target.value,s,this.#t?.inputType),this.#t=void 0,this.#i=-1,this.#o="",this.setInputValue("")}}};onCancel=e=>{e.preventDefault(),this.isLoading&&this.onCancelClick()};onImageUpload=e=>{e.stopPropagation(),X.UIUtils.createFileSelectorElement(this.#u.bind(this),".jpeg,.jpg,.png").click()}};var Es={};j(Es,{ChatMessage:()=>ke,DEFAULT_VIEW:()=>Ls,getDeduplicatedWidgetsMessage:()=>He,getWidgetSignature:()=>$s,renderStep:()=>qe,titleForStep:()=>ee});import"./../../ui/components/markdown_view/markdown_view.js";import"./../../ui/kit/kit.js";import*as B from"./../../core/common/common.js";import"./../../core/host/host.js";import*as $ from"./../../core/i18n/i18n.js";import*as kt from"./../../core/platform/platform.js";import*as H from"./../../core/sdk/sdk.js";import*as ys from"./../../core/text_utils/text_utils.js";import*as N from"./../../models/ai_assistance/ai_assistance.js";import*as bs from"./../../models/computed_style/computed_style.js";import*as ws from"./../../models/formatter/formatter.js";import*as x from"./../../models/trace/trace.js";import*as xs from"./../../models/workspace/workspace.js";import*as Ct from"./../common/common.js";import*as ks from"./../../services/trace_bounds/trace_bounds.js";import*as Cs from"./../../third_party/marked/marked.js";import"./../../ui/components/buttons/buttons.js";import*as bt from"./../../ui/components/input/input.js";import*as Ts from"./../../ui/components/snackbars/snackbars.js";import*as Ss from"./../../ui/helpers/helpers.js";import*as Ye from"./../../ui/legacy/legacy.js";import*as m from"./../../ui/lit/lit.js";import*as E from"./../../ui/visual_logging/visual_logging.js";import*as Ke from"./../application/application.js";import*as te from"./../elements/elements.js";import*as Je from"./../lighthouse/lighthouse.js";import*as Is from"./../network/forward/forward.js";import*as As from"./../network/network.js";import*as Xe from"./../timeline/components/components.js";import*as v from"./../timeline/components/insights/insights.js";import*as D from"./../timeline/timeline.js";import*as oe from"./../timeline/utils/utils.js";import{PanelUtils as Bi}from"./../utils/utils.js";var ye=`@scope to (devtools-widget > *){.ai-assistance-feedback-row{font-family:var(--default-font-family);width:100%;display:flex;justify-content:flex-start;align-items:center;margin-block:calc(-1 * var(--sys-size-3));margin-top:var(--sys-size-5);overflow:hidden;mask-image:linear-gradient(to right,var(--ref-palette-neutral0) calc(100% - var(--sys-size-15)),transparent 100%);.action-buttons{display:flex;align-items:center;gap:var(--sys-size-2);padding:var(--sys-size-4) 0}.vertical-separator{height:16px;width:1px;vertical-align:top;margin:0 var(--sys-size-2);background:var(--sys-color-divider);display:inline-block}.suggestions-container{overflow:hidden;position:relative;display:flex;.suggestions-scroll-container{display:flex;overflow:auto hidden;scrollbar-width:none;gap:var(--sys-size-3);padding:var(--sys-size-3)}.scroll-button-container{position:absolute;top:0;height:100%;display:flex;align-items:center;width:var(--sys-size-15);z-index:999}.scroll-button-container.hidden{display:none}.scroll-button-container.left{left:0;background:linear-gradient(90deg,var(--sys-color-cdt-base-container) 0%,var(--sys-color-cdt-base-container) 50%,transparent)}.scroll-button-container.right{right:0;background:linear-gradient(90deg,transparent,var(--sys-color-cdt-base-container) 50%);justify-content:flex-end}}}.feedback-form{display:flex;flex-direction:column;gap:var(--sys-size-5);margin-top:var(--sys-size-4);background-color:var(--sys-color-surface3);padding:var(--sys-size-6);border-radius:var(--sys-shape-corner-medium-small);max-width:var(--sys-size-32);.feedback-input{height:var(--sys-size-11);padding:0 var(--sys-size-5);background-color:var(--sys-color-surface3);width:auto}.feedback-input::placeholder{color:var(--sys-color-on-surface-subtle);font:var(--sys-typescale-body4-regular)}.feedback-header{display:flex;justify-content:space-between;align-items:center}.feedback-title{margin:0;font:var(--sys-typescale-body3-medium)}.feedback-disclaimer{padding:0 var(--sys-size-4)}}.user-query-wrapper{display:flex;justify-content:flex-end;padding:0 var(--sys-size-5);align-items:center}.chat-message{user-select:text;cursor:initial;display:flex;flex-direction:column;gap:var(--sys-size-5);width:100%;padding:var(--sys-size-7) var(--sys-size-5);font-size:12px;word-break:normal;overflow-wrap:anywhere;&.query{width:fit-content;max-width:80%;text-align:left;padding:var(--sys-size-4) var(--sys-size-6);font:var(--sys-typescale-body4-regular);border-radius:var(--sys-shape-corner-medium) var(--sys-shape-corner-extra-small) var(--sys-shape-corner-medium) var(--sys-shape-corner-medium);background-color:var(--sys-color-surface5);color:var(--sys-color-on-surface);&.is-first-message{margin-top:var(--sys-size-6)}}.ai-css-change{margin:var(--sys-size-6) 0}.answer-body-wrapper{@container(min-width: 700px){padding-left:35px}}&.is-last-message{border-bottom:0}.message-info{display:flex;align-items:center;height:var(--sys-size-11);gap:var(--sys-size-4);font:var(--sys-typescale-body4-bold);h2{font:var(--sys-typescale-body4-bold)}}.actions{display:flex;flex-direction:column;gap:var(--sys-size-8);max-width:100%}.aborted{color:var(--sys-color-on-surface-subtle)}.image-link{width:fit-content;border-radius:var(--sys-shape-corner-small);outline-offset:var(--sys-size-2);img{max-height:var(--sys-size-20);max-width:100%;border-radius:var(--sys-shape-corner-small);border:1px solid var(--sys-color-neutral-outline);width:fit-content;vertical-align:bottom}}.unavailable-image{margin:var(--sys-size-4) 0;display:inline-flex;justify-content:center;align-items:center;height:var(--sys-size-17);width:var(--sys-size-18);background-color:var(--sys-color-surface3);border-radius:var(--sys-shape-corner-small);border:1px solid var(--sys-color-neutral-outline);devtools-icon{color:var(--sys-color-state-disabled)}}}.indicator{color:var(--sys-color-green-bright)}.summary{display:grid;grid-template-columns:auto 1fr auto;padding:var(--sys-size-3);line-height:var(--sys-size-9);cursor:default;gap:var(--sys-size-3);justify-content:center;align-items:center;.title{margin:0;text-overflow:ellipsis;white-space:nowrap;overflow:hidden;font:var(--sys-typescale-body4-regular);.paused{font:var(--sys-typescale-body4-bold)}}}.step-code{display:flex;flex-direction:column;gap:var(--sys-size-2)}.show-all-container{padding-bottom:0}.js-code-output{devtools-code-block{--code-block-max-code-height:50px}}.context-details{devtools-code-block{--code-block-max-code-height:80px}}.step{width:fit-content;background-color:var(--sys-color-surface3);border-radius:16px;position:relative;&.empty{pointer-events:none;.arrow{display:none}}&:not(&[open]):hover::after{content:'';height:100%;width:100%;border-radius:inherit;position:absolute;top:0;left:0;pointer-events:none;background-color:var(--sys-color-state-hover-on-subtle)}&.paused{.indicator{color:var(--sys-color-on-surface-subtle)}}&.canceled{.summary{color:var(--sys-color-state-disabled);text-decoration:line-through}.indicator{color:var(--sys-color-state-disabled)}}devtools-markdown-view{--code-background-color:var(--sys-color-surface1)}devtools-icon{vertical-align:bottom}devtools-spinner{width:var(--sys-size-9);height:var(--sys-size-9);padding:var(--sys-size-2)}&[open]{width:auto;summary{margin-bottom:var(--sys-size-2)}.summary .title{white-space:normal;overflow:unset}.summary .arrow{transform:rotate(180deg)}}summary::marker{content:''}summary{border-radius:16px;&:focus-visible{outline:var(--sys-size-2) solid var(--sys-color-state-focus-ring);outline-offset:var(--sys-size-2)}}.step-details{padding:0 var(--sys-size-5) var(--sys-size-4) var(--sys-size-12);display:flex;flex-direction:column;gap:var(--sys-size-6);devtools-code-block{--code-block-background-color:var(--sys-color-surface1)}}}.error-step{color:var(--sys-color-error)}.side-effect-confirmation{display:flex;flex-direction:column;gap:var(--sys-size-5);padding-bottom:var(--sys-size-4)}.side-effect-buttons-container{display:flex;gap:var(--sys-size-4)}.walkthrough-toggle-container{display:flex;gap:var(--sys-size-2);align-items:center;&.has-widgets{gap:var(--sys-size-6)}.chevron{color:var(--sys-color-primary);width:var(--sys-size-8);height:var(--sys-size-8);margin-left:var(--sys-size-2)}}.computed-styles-widget{display:block;width:fit-content}.styling-preview-widget{width:100%;min-height:100px}.main-widgets-wrapper{display:flex;flex-direction:column;gap:var(--sys-size-5)}.step-widgets-wrapper{display:flex;flex-direction:column;align-items:flex-start;gap:var(--sys-size-5)}.widget-header{display:flex;justify-content:space-between;height:var(--sys-size-11);align-items:center;background:var(--sys-color-surface5);padding:var(--sys-size-2) var(--sys-size-4);border-top-left-radius:var(--sys-shape-corner-small);border-top-right-radius:var(--sys-shape-corner-small);.widget-name{font:var(--sys-typescale-body4-regular);margin:0;max-width:80%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.computed-style-title-wrapper{display:flex;align-items:center;justify-content:flex-start;gap:var(--sys-size-3)}.computed-style-title-prefix{flex-shrink:0}.widget-reveal-container{padding:0;background:none;border-radius:0}}.widget-reveal-button{display:flex;align-items:center;devtools-icon{margin-left:var(--sys-size-3);color:var(--sys-color-primary);width:var(--sys-size-8);height:var(--sys-size-8)}}.widget-and-revealer-container{width:100%;min-width:var(--sys-size-30);max-width:var(--sys-size-33)}.widget-reveal-container{background:var(--sys-color-surface5);border-bottom-right-radius:var(--sys-shape-corner-small);border-bottom-left-radius:var(--sys-shape-corner-small);padding:0 var(--sys-size-4) var(--sys-size-4) 0}.revealer-only .widget-reveal-container{background:none;border-radius:unset}.widget-content-container{padding:var(--sys-size-4) var(--sys-size-5);border-top-left-radius:var(--sys-shape-corner-medium);border-top-right-radius:var(--sys-shape-corner-medium);overflow-x:auto;background-color:var(--sys-color-surface3);--override-computed-style-property-white-space:normal;.widget-header+&{border-top-left-radius:0;border-top-right-radius:0}.widget-header+&:last-child{border-bottom-left-radius:var(--sys-shape-corner-medium);border-bottom-right-radius:var(--sys-shape-corner-medium)}}.network-request-preview{display:flex;flex-direction:column;gap:var(--sys-size-4);margin-bottom:var(--sys-size-5);padding-bottom:var(--sys-size-5);border-bottom:1px solid var(--sys-color-divider);.network-request-header{display:flex;align-items:center;gap:var(--sys-size-5);.network-request-icon{width:32px;height:32px;display:flex;align-items:center;justify-content:center;background-color:var(--sys-color-surface1);border-radius:var(--sys-shape-corner-small);border:1px solid var(--sys-color-divider);overflow:hidden;img{max-width:100%;max-height:100%;object-fit:contain}devtools-icon{width:20px;height:20px}}.network-request-details{display:flex;flex-direction:column;overflow:hidden;.network-request-name{font:var(--sys-typescale-body4-bold);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.network-request-size{font:var(--sys-typescale-body4-regular);color:var(--sys-color-on-surface-subtle)}}}}.source-files-details{display:contents;summary{list-style:none;cursor:pointer;padding:4px 12px;border:1px solid var(--sys-color-neutral-outline);border-radius:var(--sys-shape-corner-small);color:var(--sys-color-primary);width:fit-content;&:hover{background-color:var(--sys-color-state-hover-on-subtle)}}&[open] summary{display:none}}.network-requests-widget{display:flex;flex-direction:column;gap:var(--sys-size-4)}.storage-breakdown-widget{display:flex;justify-content:center;padding:var(--sys-size-4)}}
/*# sourceURL=${import.meta.resolve("././components/chatMessage.css")} */`;var as={};j(as,{getButtonLabel:()=>be});function Ni(t,e){if(t.length<=e)return{truncatedText:t,moreCharacters:0};let s=t.lastIndexOf(" ",e),i=t.indexOf(" ",e),o=e;if(s===-1&&i===-1)o=e;else if(s===-1)o=i;else if(i===-1)o=s;else{let d=e-s,l=i-e;o=d<=l?s:i}let n=t,a=0;return o<t.length&&(n=t.slice(0,o),a=t.length-o),{truncatedText:n,moreCharacters:a}}function be(t){let e="";if(t.isLoading&&!t.isExpanded&&t.stepTitle)e=t.stepTitle;else{let a=t.isExpanded?"Hide":"Show",d=t.hasWidgets?"AI walkthrough":"thinking";e=`${a} ${d}`}if(t.isLoading)return`Loading: ${e}`;let s=50,{truncatedText:i,moreCharacters:o}=Ni(t.prompt,s),n=o>0?` (and ${o} more characters)`:"";return`${e} for prompt ${i}${n}`}var ms={};j(ms,{DEFAULT_VIEW:()=>us,WalkthroughView:()=>ie,walkthroughCloseTitle:()=>_e,walkthroughTitle:()=>Be});import*as je from"./../../core/i18n/i18n.js";import*as ds from"./../../models/ai_assistance/ai_assistance.js";import"./../../ui/components/buttons/buttons.js";import*as gs from"./../../ui/components/input/input.js";import*as hs from"./../../ui/legacy/legacy.js";import*as re from"./../../ui/lit/lit.js";import*as xe from"./../../ui/visual_logging/visual_logging.js";var rs=`@scope (devtools-widget){.walkthrough-view{height:100%;background-color:var(--sys-color-cdt-base-container);overflow:hidden;display:flex;flex-direction:column}}@scope (devtools-widget > *){.walkthrough-header{display:flex;justify-content:space-between;align-items:center;padding:0 8px;height:35px;border-bottom:1px solid var(--sys-color-divider);flex-shrink:0}.walkthrough-title{font-size:11px;font-weight:500;color:var(--sys-color-on-surface)}.steps-container{flex:1;overflow-y:auto}.steps-scroll-content{padding:var(--sys-size-6);display:flex;flex-direction:column;gap:var(--sys-size-6)}.walkthrough-step{display:flex;gap:var(--sys-size-6);align-items:flex-start;justify-content:flex-start;flex-shrink:0;.step-number{font:var(--sys-typescale-body4-regular);color:var(--sys-color-on-surface-subtle);padding-top:var(--sys-size-4);flex-grow:0;flex-shrink:0}}.step-wrapper{display:flex;flex-direction:column;gap:var(--sys-size-5);min-width:0;width:100%}.step-container{display:flex;gap:var(--sys-size-5);align-items:flex-start}.step-icon{color:var(--sys-color-on-surface-subtle);width:var(--sys-size-8);height:var(--sys-size-8);flex-shrink:0;margin-top:var(--sys-size-2)}.step-content{flex:1;font-size:11px;color:var(--sys-color-on-surface);line-height:1.4}.empty-state{display:flex;align-items:center;justify-content:center;flex:1;color:var(--sys-color-on-surface-subtle);font-size:11px}.inline-wrapper{display:flex;align-items:center;gap:var(--sys-size-2);justify-content:flex-start;.inline-icon{display:block;margin-top:var(--sys-size-2)}}.walkthrough-inline{border-radius:var(--sys-shape-corner-full);overflow:hidden;width:fit-content;max-width:100%;&[open]{border-radius:var(--sys-size-5);width:auto;background-color:var(--sys-color-surface2);margin-left:calc(var(--sys-size-6) / 2);flex-grow:1}}.walkthrough-inline > summary{display:flex;align-items:center;cursor:pointer;background-color:transparent;height:var(--sys-size-11);font:var(--sys-typescale-body4-regular);font-weight:var(--ref-typeface-weight-medium);user-select:none;list-style:none;justify-content:flex-start;gap:var(--sys-size-4);color:var(--sys-color-primary);padding:0 var(--sys-size-6);overflow:hidden;devtools-icon{color:var(--sys-color-primary)}&[data-has-widgets]{background:var(--sys-color-tonal-container);color:var(--sys-color-on-tonal-container);border-radius:var(--sys-shape-corner-full);margin-left:var(--sys-size-6);devtools-icon{color:var(--sys-color-on-tonal-container)}}> .walkthrough-inline-title{font:var(--sys-typescale-body4-regular);font-weight:var(--ref-typeface-weight-medium);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;min-width:0}&:focus-visible{outline:var(--sys-size-2) solid var(--sys-color-state-focus-ring);outline-offset:calc(-1 * var(--sys-size-2))}}.walkthrough-inline[open] > summary{border-radius:var(--sys-shape-corner-medium-small);border-bottom-right-radius:0;border-bottom-left-radius:0;background:var(--sys-color-surface5);color:var(--sys-color-on-surface);&[data-has-widgets]{margin-left:0}> devtools-icon[name='chevron-right']{transform:rotate(270deg)}}.walkthrough-inline > summary::-webkit-details-marker{display:none}.walkthrough-inline > summary:hover{background-color:var(--sys-color-state-hover-on-subtle)}.walkthrough-inline .steps-container{padding:var(--sys-size-6);border-top:1px solid var(--sys-color-divider);background-color:transparent}.walkthrough-inline > summary > devtools-icon[name='chevron-right']{width:var(--sys-size-8);height:var(--sys-size-8);transition:transform 0.2s;margin-left:auto}.walkthrough-inline .step{background-color:var(--sys-color-surface5)}}
/*# sourceURL=${import.meta.resolve("././components/walkthroughView.css")} */`;var we=je.i18n.lockedString,{html:Z,render:Fi,Directives:Oi}=re,{ref:ls}=Oi,cs=2,q={close:"Close",title:"Agent walkthrough",showThinking:"Show thinking",showAgentWalkthrough:"Show agent walkthrough",hideThinking:"Hide thinking",hideAgentWalkthrough:"Hide agent walkthrough",inProgress:"In progress"},Vi=je.i18n.registerUIStrings("panels/ai_assistance/components/WalkthroughView.ts",q),ft=je.i18n.getLocalizedString.bind(void 0,Vi);function Be(t){return t.isLoading?ee(t.lastStep):t.hasWidgets?we(q.showAgentWalkthrough):we(q.showThinking)}function _e(t){return t.isInlined?ft(q.title):t.hasWidgets?we(q.hideAgentWalkthrough):we(q.hideThinking)}function Wi(t,e,s){let i=s.at(-1);if(!t.isInlined||!i)return re.nothing;function o(d){let l=d.target.open;t.message&&(l?t.onOpen(t.message):t.onToggle(l,t.message))}let n=s.some(d=>d.widgets?.length),a=ds.AiUtils.getIconName();return Z`
    <div class="inline-wrapper" ?data-open=${t.isExpanded} jslog=${xe.section("walkthrough-container")}>
      <span class="inline-icon">
        ${t.isLoading?Z`<devtools-spinner aria-label=${we(q.inProgress)}></devtools-spinner>`:Z`<devtools-icon name=${a}></devtools-icon>`}
      </span>
      <details class="walkthrough-inline" ?open=${t.isExpanded} @toggle=${o} jslog=${xe.expand("walkthrough").track({click:!0})}>
        <summary
          ?data-has-widgets=${!t.isLoading&&n}
          aria-label=${be({isExpanded:t.isExpanded,isLoading:t.isLoading,hasWidgets:n,prompt:t.prompt,stepTitle:ee(i)})}
        >
          <h2 class="walkthrough-inline-title">
            ${t.isExpanded?_e({hasWidgets:n,isInlined:!0}):Be({isLoading:t.isLoading,lastStep:i,hasWidgets:n})}
          </h2>
          <devtools-icon name="chevron-right"></devtools-icon>
        </summary>

        ${e}
      </details>
    </div>
  `}function ji(t,e,s){return t.isInlined?re.nothing:Z`
    <div class="walkthrough-view" jslog=${xe.section("walkthrough-container")}>
      <div class="walkthrough-header">
         <h2 class="walkthrough-title">${ft(q.title)}</h2>
         <devtools-button
          .data=${{variant:"toolbar",iconName:"cross",title:ft(q.close),jslogContext:"close-walkthrough"}}
          @click=${()=>{t.message&&t.onToggle(!1,t.message)}}
        ></devtools-button>
      </div>
      ${e}
      ${s===0?Z`
        <div class="empty-state">
          <p>No walkthrough steps available yet.</p>
        </div>
      `:re.nothing}
    </div>
  `}var us=(t,e,s)=>{let i=t.message?.parts.filter(a=>a.type==="step")?.map(a=>a.step)??[],o=i.filter(a=>a.state.type!=="needs_approval"),n=o.length>0?Z`
    <div class="steps-container" @scroll=${t.handleScroll} ${ls(a=>{e.scrollContainer=a})}>
      <div class="steps-scroll-content" ${ls(a=>{e.stepsContainer=a})}>
        ${o.map((a,d)=>Z`
          <div class="walkthrough-step">
            <span class="step-number">${d+1}</span>
            <div class="step-wrapper">
              ${qe({step:a,markdownRenderer:t.markdownRenderer,isLast:d===o.length-1})}
            </div>
          </div>
        `)}
      </div>
    </div>
  `:re.nothing;Fi(Z`
    <style>
      ${gs.textInputStyles}
      ${ye}
      ${rs}
    </style>
    ${t.isInlined?Wi(t,n,i):ji(t,n,o.length)}`,s)},ie=class extends hs.Widget.Widget{#s;#t=null;#i=!1;#o=null;#a=()=>{};#r=()=>{};#c=!1;#d=!1;#e="";#g=!0;#h=!1;#l={};#u=new ResizeObserver(()=>this.#b());#m=0;constructor(e,s=us){super(e),this.#s=s,this.setMinimumSize(330,0)}wasShown(){super.wasShown(),this.#p()}willHide(){super.willHide(),this.#u.disconnect()}#p(){this.#l.stepsContainer&&this.#u.observe(this.#l.stepsContainer)}#b(){let e=this.#l.stepsContainer?.offsetWidth??0;if(e!==this.#m){this.#m=e;return}!this.#g||!this.#i||this.scrollToBottom()}scrollToBottom(){this.#l.stepsContainer&&(this.#h=!0,window.requestAnimationFrame(()=>{let e=this.#l.stepsContainer?.lastElementChild;e&&e.scrollIntoView({behavior:"smooth",block:"end"})}))}#y=e=>{if(!(!e.target||!(e.target instanceof HTMLElement))){if(this.#h){e.target.scrollTop+e.target.clientHeight+cs>=e.target.scrollHeight&&(this.#h=!1);return}this.#g=e.target.scrollTop+e.target.clientHeight+cs>=e.target.scrollHeight}};set isLoading(e){this.#i=e,this.requestUpdate()}get isLoading(){return this.#i}get markdownRenderer(){return this.#o}set markdownRenderer(e){this.#o=e,this.requestUpdate()}get message(){return this.#t}get onOpen(){return this.#r}set onOpen(e){this.#r=e,this.requestUpdate()}set message(e){this.#t=e,this.requestUpdate()}set onToggle(e){this.#a=e,this.requestUpdate()}set isInlined(e){this.#c=e,this.requestUpdate()}set isExpanded(e){this.#d=e,this.requestUpdate()}get prompt(){return this.#e}set prompt(e){this.#e=e,this.requestUpdate()}performUpdate(){if(!this.#o)return;let e=this.#t?He(this.#t):null;this.#s({isLoading:this.#i,markdownRenderer:this.#o,onToggle:this.#a,onOpen:this.#r,isInlined:this.#c,isExpanded:this.#d,prompt:this.#e,message:e,handleScroll:this.#y},this.#l,this.contentElement),this.#p(),this.#g&&this.#i&&this.scrollToBottom()}};var{html:c,Directives:{ref:Ge,ifDefined:wt}}=m,h=$.i18n.lockedString,{widget:P}=Ye.Widget,_i="https://crbug.com/508304827",ps=1,r={thumbsUp:"Good response",thumbsDown:"Bad response",provideFeedbackPlaceholder:"Provide additional feedback",disclaimer:"Submitted feedback will also include your conversation",submit:"Submit",whyThisRating:"Why did you choose this rating? (optional)",close:"Close",report:"Report legal issue",scrollToNext:"Scroll to next suggestions",scrollToPrevious:"Scroll to previous suggestions",systemError:"Something unforeseen happened and I can no longer continue. Try your request again and see if that resolves the issue. If this keeps happening, update Chrome to the latest version.",quotaError:"You reached your limit for AI assistance requests. Try again later.",maxStepsError:"Seems like I am stuck with the investigation. It would be better if you start over.",crossOriginError:"I have selected the new context but you will have to start a new chat.",payloadTooLargeError:"The request payload is too large. Please try a smaller image or a screenshot.",stoppedResponse:"You stopped this response",confirmActionRequestApproval:"Continue",declineActionRequestApproval:"Cancel",investigating:"Investigating",paused:"Paused",codeExecuted:"Code executed",codeToExecute:"Code to execute",dataReturned:"Data returned",completed:"Completed",inProgress:"In progress",aborted:"Aborted",imageInputSentToTheModel:"Image input sent to the model",openImageInNewTab:"Open image in a new tab",imageUnavailable:"Image unavailable",reveal:"Reveal",revealTrace:"Reveal trace",revealComputedStyles:"Reveal computed styles",revealCoreWebVitals:"Reveal Core Web Vitals",revealStyleProperties:"Reveal style properties",revealLcpBreakdown:"Reveal LCP breakdown",revealLcpDiscovery:"Reveal LCP discovery",revealClsCulprits:"Reveal layout shift culprits",revealRenderBlockingBreakdown:"Reveal render-blocking requests",revealPerformanceSummary:"Reveal performance summary",revealNetworkActivity:"Reveal network activity",revealBottomUpTree:"Reveal bottom-up thread activity",revealNetworkDependencyTree:"Reveal network dependency tree",revealThirdParties:"Reveal 3rd parties",coreVitals:"Core Web Vitals",lighthouseReport:"Lighthouse report",revealLighthouse:"Reveal Lighthouse report",timelineEventSummary:"Event summary",revealTimelineEventSummary:"Reveal event",lcpBreakdown:"LCP breakdown",lcpDiscovery:"LCP discovery",clsCulprits:"Layout shift culprits",renderBlockingBreakdown:"Render-blocking requests",networkDependencyTree:"Network dependency tree",thirdParties:"3rd parties",performanceSummary:"Performance summary",networkActivitySummary:"Network activity",exportForAgents:"Copy to coding agent",bottomUpTree:"Bottom-up thread activity",revealForcedReflow:"Reveal forced reflow",forcedReflow:"Forced reflow",revealCache:"Reveal efficient cache lifetimes",cache:"Efficient cache lifetimes",revealInpBreakdown:"Reveal INP breakdown",inpBreakdown:"INP breakdown",revealDocumentLatency:"Reveal document latency",documentLatency:"Document latency",revealDomSize:"Reveal DOM size",domSize:"DOM size",revealDuplicateJavaScript:"Reveal duplicated JavaScript",duplicateJavaScript:"Duplicated JavaScript",revealImageDelivery:"Reveal image delivery",imageDelivery:"Image delivery",revealFontDisplay:"Reveal font display",fontDisplay:"Font display",revealSlowCssSelector:"Reveal slow CSS selectors",slowCssSelector:"Slow CSS selectors",revealLegacyJavaScript:"Reveal legacy JavaScript",legacyJavaScript:"Legacy JavaScript",revealViewport:"Reveal viewport optimization",viewport:"Viewport optimization",revealNetworkRequest:"Reveal network request",networkRequest:"Network request",revealModernHttp:"Reveal modern HTTP usage",modernHttp:"Modern HTTP usage",revealCharacterSet:"Reveal character set declaration",characterSet:"Character set declaration",networkRequests:"Network requests",revealFirstNetworkRequest:"Reveal first network request in Network panel",inspectedFileNames:"Inspected file names",storageBreakdown:"Storage breakdown",revealStorageBreakdown:"Reveal storage breakdown in Application panel"},Ls=(t,e,s)=>{let i=t.message;if(i.entity==="user"){let a=i.imageInput&&"inlineData"in i.imageInput?fo(i.imageInput.inlineData):m.nothing,d=m.Directives.classMap({"chat-message":!0,query:!0,"is-last-message":t.isLastMessage,"is-first-message":t.isFirstMessage});m.render(c`
      <style>${bt.textInputStyles}</style>
      <style>${ye}</style>
      <div class="user-query-wrapper">
        <section class=${d} jslog=${E.section("question")}>
          ${a}
          <div class="message-content">${xt(i.text,t.markdownRenderer)}</div>
        </section>
      </div>
    `,s);return}let o=i.parts.filter(a=>a.type==="step").map(a=>a.step),n=m.Directives.classMap({"chat-message":!0,answer:!0,"is-last-message":t.isLastMessage,"is-first-message":t.isFirstMessage});m.render(c`
    <style>${bt.textInputStyles}</style>
    <style>${ye}</style>
    <section class=${n} jslog=${E.section("answer")}>
      ${Yi(t,o)}
      <div class="answer-body-wrapper">
        ${m.Directives.repeat(i.parts,(a,d)=>d,(a,d)=>{let l=d===i.parts.length-1;return a.type==="answer"?c`<p>${xt(a.text,t.markdownRenderer,{animate:!t.isReadOnly&&t.isLoading&&l&&t.isLastMessage})}</p>`:a.type==="widget"?c`${m.Directives.until(Rs(a.widgets,{wrapperClass:"main-widgets-wrapper"}))}`:m.nothing})}
        ${vo(i)}
        ${t.showActions?yo(t,e):m.nothing}
      </div>
      ${Ji(t,o)}
    </section>
  `,s)};function xt(t,e,{animate:s,ref:i}={}){let o=[];try{o=Cs.Marked.lexer(t);for(let n of o)e.renderToken(n)}catch{return c`${t}`}return c`<devtools-markdown-view
    .data=${{tokens:o,renderer:e,animationEnabled:s}}
    ${i?Ge(i):m.nothing}>
  </devtools-markdown-view>`}function ee(t){return t.title??`${h(r.investigating)}\u2026`}function qi(t){let e=t.state.type==="needs_approval"?c`<span class="paused">${h(r.paused)}: </span>`:m.nothing;return c`<h3 class="title" aria-label=${ee(t)}>${e}${ee(t)}</h3>`}function Hi(t){if(!t.code&&!t.output)return m.nothing;let e=t.output&&t.state.type!=="canceled"?h(r.codeExecuted):h(r.codeToExecute),s=t.code?c`<div class="action-result">
      <devtools-code-block
        .code=${t.code.trim()}
        .codeLang=${"js"}
        .displayNotice=${!t.output}
        .header=${e}
        .showCopyButton=${!0}
      ></devtools-code-block>
  </div>`:m.nothing,i=t.output?c`<div class="js-code-output">
    <devtools-code-block
      .code=${t.output}
      .codeLang=${"js"}
      .displayNotice=${!0}
      .header=${h(r.dataReturned)}
      .showCopyButton=${!1}
    ></devtools-code-block>
  </div>`:m.nothing;return c`<div class="step-code">${s}${i}</div>`}function Ki({step:t,markdownRenderer:e,isLast:s}){let i=s&&t.state.type==="needs_approval"?po(t):m.nothing,o=t.thought?c`<p>${xt(t.thought,e)}</p>`:m.nothing,n=t.contextDetails?c`${m.Directives.repeat(t.contextDetails,a=>c`<div class="context-details">
      <devtools-code-block
        .code=${a.text}
        .codeLang=${a.codeLang||""}
        .displayNotice=${!1}
        .header=${a.title}
        .showCopyButton=${!0}
      ></devtools-code-block>
    </div>`)}`:m.nothing;return c`<div class="step-details">
    ${o}
    ${Hi(t)}
    ${i}
    ${n}
  </div>`}function Gi(t,e){let{message:s,walkthrough:i}=t,o=e.at(-1);if(i.isInlined||!o)return m.nothing;let n=e.some(Pe=>Pe.widgets?.length),a=i.isExpanded&&t.message.id===t.walkthrough.activeSidebarMessage?.id,d=a?_e({hasWidgets:n}):Be({isLoading:t.isLoading,hasWidgets:n,lastStep:o}),l=n&&!t.isLoading?"tonal":"text",p=N.AiUtils.getIconName(),k=m.Directives.classMap({"walkthrough-toggle-container":!0,"has-widgets":n&&!t.isLoading}),De=be({isExpanded:a,isLoading:t.isLoading,hasWidgets:n,prompt:t.prompt,stepTitle:ee(o)});return c`
    <div class=${k}>
      ${t.isLoading?c`<devtools-spinner></devtools-spinner>`:c`<devtools-icon name=${p}></devtools-icon>`}
      <devtools-button
        .variant=${l}
        .size=${"SMALL"}
        .title=${o.state.type==="in_progress"?ee(o):d}
        .accessibleLabel=${De}
        .jslogContext=${i.isExpanded?"ai-hide-walkthrough-sidebar":"ai-show-walkthrough-sidebar"}
        data-show-walkthrough
        @click=${()=>{i.activeSidebarMessage?.id===t.message.id&&i.isExpanded?i.onToggle(!1,s):i.onOpen(s)}}>${d}<devtools-icon class="chevron" .name=${a?"cross":"chevron-right"}></devtools-icon>
      </devtools-button>
    </div>
  `}function Yi(t,e){if(!e.at(-1))return m.nothing;let i=t.walkthrough.isInlined?m.nothing:Gi(t,e),o=t.walkthrough.isInlined?t.walkthrough.inlineExpandedMessages.some(a=>a.id===t.message.id):t.walkthrough.isExpanded&&t.walkthrough.activeSidebarMessage?.id===t.message.id,n=t.walkthrough.isInlined?c`
    <div class="walkthrough-container">
      ${P(ie,{message:t.message,isLoading:t.isLoading&&t.isLastMessage,markdownRenderer:t.markdownRenderer,isInlined:!0,isExpanded:o,prompt:t.prompt,onToggle:t.walkthrough.onToggle,onOpen:t.walkthrough.onOpen})}
    </div>
  `:m.nothing;return c`
    ${i}
    ${n}
  `}function Ji(t,e){let s=e.filter(i=>i.state.type==="needs_approval"||i.state.type==="canceled");return s.length===0?m.nothing:c`
    ${s.map(i=>c`
      <div class="side-effect-container">
        ${qe({step:i,markdownRenderer:t.markdownRenderer,isLast:!0})}
      </div> `)}
  `}function Xi({step:t,isLast:e}){if(e&&t.state.type==="in_progress")return c`<devtools-spinner aria-label=${h(r.inProgress)}></devtools-spinner>`;let s="checkmark",i=h(r.completed),o="button";return t.state.type==="needs_approval"?(e||console.error("A step in needs_approval state must be the last step."),o=void 0,i=h(r.paused),s="pause-circle"):t.state.type==="canceled"&&(i=h(r.aborted),s="cross"),c`<devtools-icon
      class="indicator"
      role=${wt(o)}
      aria-label=${wt(i)}
      .name=${s}
    ></devtools-icon>`}function qe({step:t,markdownRenderer:e,isLast:s}){let i=m.Directives.classMap({step:!0,empty:!t.thought&&!t.code&&!t.contextDetails&&t.state.type!=="needs_approval",paused:t.state.type==="needs_approval",canceled:t.state.type==="canceled"});return c`
    <details class=${i}
      jslog=${E.expand("step").track({click:!0})}
      .open=${t.state.type==="needs_approval"}>
      <summary>
        <div class="summary">
          ${Xi({step:t,isLast:s})}
          ${qi(t)}
          <devtools-icon
            class="arrow"
            name="chevron-down"
          ></devtools-icon>
        </div>
      </summary>
      ${Ki({step:t,markdownRenderer:e,isLast:s})}
    </details>
    ${m.Directives.until(Rs(t.widgets,{wrapperClass:"step-widgets-wrapper"}))}
    `}var vs=new Map;async function Ms(t){let e=vs.get(t);if(e)return e;let s=H.TargetManager.TargetManager.instance().primaryPageTarget();if(!s)return null;let o=await new H.DOMModel.DeferredDOMNode(s,t).resolvePromise();return o&&vs.set(t,o),o}async function Qi(t){let e=H.TargetManager.TargetManager.instance().primaryPageTarget();if(!e)return null;let s=t.data.usageBreakdown,i=s.reduce((d,l)=>d+l.bytes,0),o=s.map(d=>{let l=Ke.StorageView.storagePieColors.get(d.storageType)||"rgb(180, 180, 180)",p=Ke.StorageView.StorageView.getStorageTypeNameForWidget(d.storageType);return{value:d.bytes,color:l,title:p}}),n={chartName:h(r.storageBreakdown),size:110,formatter:d=>N.UnitFormatters.bytes(d),showLegend:!0,total:i,slices:o};return{renderedWidget:c`
    <div class="storage-breakdown-widget">
      <devtools-perf-piechart .data=${n}></devtools-perf-piechart>
    </div>
  `,title:h(r.storageBreakdown),revealable:new Ke.StorageView.StorageRevealable(e),accessibleRevealLabel:h(r.revealStorageBreakdown),jslogContext:"storage-breakdown-widget"}}async function Zi(t){let e=await Ms(t.data.backendNodeId);if(!e)return null;let s=new bs.ComputedStyleModel.ComputedStyle(e,t.data.computedStyles),i=null;try{i=new RegExp(t.data.properties.join("|"),"i")}catch{return null}return{renderedWidget:c`<devtools-widget
      class="computed-styles-widget" ${P(te.ComputedStyleWidget.ComputedStyleWidget,{nodeStyle:s,matchedStyles:t.data.matchedCascade,propertyTraces:null,allowUserControl:!1,filterText:i,enableNarrowViewResizing:!1})}></devtools-widget>`,revealable:new te.ElementsPanel.NodeComputedStyles(e),accessibleRevealLabel:h(r.revealComputedStyles),title:c`
      <span class="computed-style-title-wrapper">
        <span class="computed-style-title-prefix">Computed styles</span>
        <span class="style-class-wrapper">
          (<devtools-widget
            ${P(Ct.DOMLinkifier.DOMNodeLink,{node:e})}
          ></devtools-widget>)
        </span>
      </span>`,jslogContext:"computed-styles"}}async function eo(t){return{renderedWidget:c`<devtools-widget class="core-vitals-widget" ${P(Xe.CWVMetrics.CWVMetrics,{data:t.data,skipBottomBorder:!0})}>
  </devtools-widget>`,revealable:new oe.Helpers.RevealableCoreVitals(t.data.insightSetKey),accessibleRevealLabel:h(r.revealCoreWebVitals),title:h(r.coreVitals),jslogContext:"core-web-vitals"}}async function to(t){let e=await Ms(t.data.backendNodeId);if(!e)return null;let s=null;try{s=t.data.selector?new RegExp(t.data.selector):null}catch{return null}return{renderedWidget:c`<devtools-widget
      class="styling-preview-widget"
      ${P(te.StandaloneStylesContainer.StandaloneStylesContainer,{domNode:e,filter:s})}>
  </devtools-widget>`,revealable:e,accessibleRevealLabel:h(r.revealStyleProperties),title:c`<devtools-widget
      ${P(Ct.DOMLinkifier.DOMNodeLink,{node:e})}
    ></devtools-widget>`,jslogContext:"standalone-styles"}}var so={[x.Insights.Types.InsightKeys.LCP_BREAKDOWN]:{component:v.LCPBreakdown.LCPBreakdown,accessibleLabel:r.revealLcpBreakdown,title:r.lcpBreakdown,jslog:"lcp-breakdown-widget"},[x.Insights.Types.InsightKeys.RENDER_BLOCKING]:{component:v.RenderBlocking.RenderBlocking,accessibleLabel:r.revealRenderBlockingBreakdown,title:r.renderBlockingBreakdown,jslog:"render-blocking-widget"},[x.Insights.Types.InsightKeys.LCP_DISCOVERY]:{component:v.LCPDiscovery.LCPDiscovery,accessibleLabel:r.revealLcpDiscovery,title:r.lcpDiscovery,jslog:"lcp-discovery-widget"},[x.Insights.Types.InsightKeys.CLS_CULPRITS]:{component:v.CLSCulprits.CLSCulprits,accessibleLabel:r.revealClsCulprits,title:r.clsCulprits,jslog:"cls-culprits-widget"},[x.Insights.Types.InsightKeys.NETWORK_DEPENDENCY_TREE]:{component:v.NetworkDependencyTree.NetworkDependencyTree,accessibleLabel:r.revealNetworkDependencyTree,title:r.networkDependencyTree,jslog:"network-dependency-tree-widget"},[x.Insights.Types.InsightKeys.THIRD_PARTIES]:{component:v.ThirdParties.ThirdParties,accessibleLabel:r.revealThirdParties,title:r.thirdParties,jslog:"third-parties-widget"},[x.Insights.Types.InsightKeys.FORCED_REFLOW]:{component:v.ForcedReflow.ForcedReflow,accessibleLabel:r.revealForcedReflow,title:r.forcedReflow,jslog:"forced-reflow-widget"},[x.Insights.Types.InsightKeys.CACHE]:{component:v.Cache.Cache,accessibleLabel:r.revealCache,title:r.cache,jslog:"cache-widget"},[x.Insights.Types.InsightKeys.INP_BREAKDOWN]:{component:v.INPBreakdown.INPBreakdown,accessibleLabel:r.revealInpBreakdown,title:r.inpBreakdown,jslog:"inp-breakdown-widget"},[x.Insights.Types.InsightKeys.DOCUMENT_LATENCY]:{component:v.DocumentLatency.DocumentLatency,accessibleLabel:r.revealDocumentLatency,title:r.documentLatency,jslog:"document-latency-widget"},[x.Insights.Types.InsightKeys.DOM_SIZE]:{component:v.DOMSize.DOMSize,accessibleLabel:r.revealDomSize,title:r.domSize,jslog:"dom-size-widget"},[x.Insights.Types.InsightKeys.DUPLICATE_JAVASCRIPT]:{component:v.DuplicatedJavaScript.DuplicatedJavaScript,accessibleLabel:r.revealDuplicateJavaScript,title:r.duplicateJavaScript,jslog:"duplicate-javascript-widget"},[x.Insights.Types.InsightKeys.IMAGE_DELIVERY]:{component:v.ImageDelivery.ImageDelivery,accessibleLabel:r.revealImageDelivery,title:r.imageDelivery,jslog:"image-delivery-widget"},[x.Insights.Types.InsightKeys.FONT_DISPLAY]:{component:v.FontDisplay.FontDisplay,accessibleLabel:r.revealFontDisplay,title:r.fontDisplay,jslog:"font-display-widget"},[x.Insights.Types.InsightKeys.SLOW_CSS_SELECTOR]:{component:v.SlowCSSSelector.SlowCSSSelector,accessibleLabel:r.revealSlowCssSelector,title:r.slowCssSelector,jslog:"slow-css-selector-widget"},[x.Insights.Types.InsightKeys.LEGACY_JAVASCRIPT]:{component:v.LegacyJavaScript.LegacyJavaScript,accessibleLabel:r.revealLegacyJavaScript,title:r.legacyJavaScript,jslog:"legacy-javascript-widget"},[x.Insights.Types.InsightKeys.VIEWPORT]:{component:v.Viewport.Viewport,accessibleLabel:r.revealViewport,title:r.viewport,jslog:"viewport-widget"},[x.Insights.Types.InsightKeys.MODERN_HTTP]:{component:v.ModernHTTP.ModernHTTP,accessibleLabel:r.revealModernHttp,title:r.modernHttp,jslog:"modern-http-widget"},[x.Insights.Types.InsightKeys.CHARACTER_SET]:{component:v.CharacterSet.CharacterSet,accessibleLabel:r.revealCharacterSet,title:r.characterSet,jslog:"character-set-widget"}};function io(t,e,s,i,o,n){return{renderedWidget:c`<devtools-widget
    class=${s}
    ${P(t,{model:e,minimal:!0,bounds:n??null})}></devtools-widget>`,revealable:new oe.Helpers.RevealableInsight(e),accessibleRevealLabel:h(i),title:h(o),jslogContext:s}}async function oo(t){let e=t.data.insight,s=t.data.insightData,i=so[e];if(!i)return null;let o;if(e===x.Insights.Types.InsightKeys.CLS_CULPRITS){let n=ks.TraceBounds.BoundsManager.instance().state()?.micro.entireTraceBounds;if(!n)return null;o=n}return io(i.component,s,i.jslog,i.accessibleLabel,i.title,o)}async function no(t){let e=N.AIQueries.AIQueries.mainThreadActivityBottomUp(t.data.bounds,t.data.parsedTrace);if(!e)return null;let s=e.events,i=x.Helpers.Timing.microToMilli(t.data.bounds.min),o=x.Helpers.Timing.microToMilli(t.data.bounds.max);return{renderedWidget:c`<devtools-widget
      class="bottom-up-timeline-tree-widget"
      ${P(D.TimelineTreeView.BottomUpTimelineTreeView,{selectedEvents:s,parsedTrace:t.data.parsedTrace,startTime:i,endTime:o,compactMode:!0,maxLinkLength:15,maxRows:10})}></devtools-widget>`,revealable:new oe.Helpers.RevealableBottomUpProfile(t.data.bounds),accessibleRevealLabel:h(r.revealBottomUpTree),title:h(r.bottomUpTree),jslogContext:"bottom-up"}}function ao(t){if(t===null)return m.nothing;function e(){t!==null&&B.Revealer.reveal(t?.revealable).catch(o=>{o.message&&Ts.Snackbar.Snackbar.show({message:o.message})})}let s=m.Directives.classMap({"widget-and-revealer-container":!0,"revealer-only":t.renderedWidget===null}),i=c`
    <devtools-button class="widget-reveal-button"
      .variant=${"text"}
      .accessibleLabel=${t.accessibleRevealLabel}
      .jslogContext=${"reveal"}
      @click=${e}
    >
      ${t.customRevealTitle??h(r.reveal)}
      <devtools-icon name='tab-move'></devtools-icon>
    </devtools-button>
  `;return c`
    <div class=${s} jslog=${wt(t.jslogContext?E.section(t.jslogContext):void 0)}>
      ${t.title?c`
        <div class="widget-header">
          <h4 class="widget-name">${t.title}</h4>
          <div class="widget-reveal-container">
            ${i}
          </div>
        </div>
      `:m.nothing}
      ${t.renderedWidget?c`
        <div class="widget-content-container">
          ${t.renderedWidget}
        </div>`:m.nothing}
      ${t.title?m.nothing:c`
        <div class="widget-reveal-container">
          ${i}
        </div>
      `}
    </div>
    `}async function ro(t){let e=h(r.revealTrace);return{renderedWidget:null,title:null,revealable:new D.TimelinePanel.ParsedTraceRevealable(t.data.parsedTrace),customRevealTitle:e,accessibleRevealLabel:e,jslogContext:"performance-trace"}}async function lo(t){let e=t.data.uiSourceCode,s=$.i18n.lockedString(`Show ${e.name()}`);return{renderedWidget:null,title:null,revealable:e,customRevealTitle:s,accessibleRevealLabel:s,jslogContext:"source-file-widget"}}async function co(t){let e=t.data.url,s=e.split("/").pop()||e,i=t.data.line,o=t.data.column,n=i!==void 0&&o!==void 0?`${s}:${i}:${o}`:s,a=xs.Workspace.WorkspaceImpl.instance().uiSourceCodeForURL(e),d=s.lastIndexOf("."),l=d!==-1?s.substring(d+1):"",p=t.data.code;if(ys.TextUtils.isMinified(p)){let De=a?.contentType().canonicalMimeType()||"text/javascript";p=(await ws.ScriptFormatter.formatScriptContent(B.Settings.Settings.instance(),De,p,"  ")).formattedContent}return{renderedWidget:c`
    <devtools-code-block
      class="source-code-widget"
      .displayLimit=${20}
      .code=${p}
      .codeLang=${l}
      .displayToolbar=${!1}
      .displayNotice=${!1}
    ></devtools-code-block>
  `,title:h(n),revealable:a,accessibleRevealLabel:$.i18n.lockedString(`Show ${s} in Sources`),jslogContext:"source-code-widget"}}function fs(t,e){let s=()=>{B.Revealer.reveal(t)},i=$.i18n.lockedString(`Show ${t.fullDisplayName()}`);return c`
    <devtools-button class=${`widget-reveal-button ${e?"collapsed-file":"visible-file"}`}
      .variant=${"text"}
      .accessibleLabel=${i}
      .jslogContext=${"reveal"}
      @click=${s}>
      ${t.fullDisplayName()}
      <devtools-icon name='tab-move'></devtools-icon>
    </devtools-button>
  `}async function go(t){let e=t.data.uiSourceCodes;if(e.length===0)return null;let s=c`
    <div class="source-files-widget">
      ${e.slice(0,10).map(o=>fs(o,!1))}
      ${e.length>10?c`
        <details class="source-files-details">
          <summary class="show-more-summary">${$.i18n.lockedString(`Show all ${e.length} files`)}</summary>
          ${e.slice(10).map(o=>fs(o,!0))}
        </details> `:m.nothing}
    </div>`,i=h(r.inspectedFileNames);return{renderedWidget:s,title:i,revealable:e[0],accessibleRevealLabel:$.i18n.lockedString("Reveal first file in Sources panel"),jslogContext:"source-files-list-widget"}}var yt=new WeakSet;async function ho(t){let e=t.data.requests;if(e.length===0)return null;let s=yt.has(t);s&&yt.delete(t);let i=s?e:e.slice(0,15);return{renderedWidget:c`
    <div class="network-requests-widget">
      <devtools-data-grid striped inline>
        <table>
          <tr>
            <th id="name" weight="4">${$.i18n.lockedString("Name")}</th>
            <th id="status" weight="1">${$.i18n.lockedString("Status")}</th>
            <th id="size" weight="1">${$.i18n.lockedString("Size")}</th>
            <th id="time" weight="1">${$.i18n.lockedString("Time")}</th>
          </tr>
          ${i.map(n=>c`
            <tr>
              <td>${n.name()}</td>
              <td>${n.statusCode}</td>
              <td>${$.ByteUtilities.formatBytesToKb(n.transferSize)}</td>
              <td>${$.TimeUtilities.secondsToString(n.duration)}</td>
            </tr>
          `)}
        </table>
      </devtools-data-grid>
      ${!s&&e.length>15?c`
        <div class="show-all-container">
          <button class="show-all-widget-requests-button text-button"
            jslog=${E.action("show-all-widget-requests-button").track({click:!0})}
            @click=${n=>{yt.add(t);let a=n.target.closest(".widget");if(a){let d=Ye.Widget.Widget.get(a);d&&d.performUpdate&&d.performUpdate()}}}>
            ${$.i18n.lockedString(`Show all ${e.length} network requests`)}
          </button>
        </div>
      `:m.nothing}
    </div>
  `,title:h(r.networkRequests),revealable:e[0],accessibleRevealLabel:h(r.revealFirstNetworkRequest),jslogContext:"network-requests-list-widget"}}function uo(t){let e=t.url.split("/").pop()||t.url,s=$.ByteUtilities.bytesToString(t.size),i=B.ResourceType.resourceTypes[t.resourceType],{iconName:o,color:n}=Bi.iconDataForResourceType(i),a=t.imageContent?.asImagePreviewUrl();return c`
    <div class="network-request-preview">
      <div class="network-request-header">
        <div class="network-request-icon">
          ${i.isImage()&&a?c`<img src=${a} alt=${e} />`:c`<devtools-icon name=${o} style=${m.Directives.styleMap({color:n??""})}></devtools-icon>`}
        </div>
        <div class="network-request-details">
          <div class="network-request-name" title=${t.url}>${e}</div>
          <div class="network-request-size">${s}</div>
        </div>
      </div>
    </div>
  `}async function mo(t){let e=t.data.root;if(!(e instanceof H.DOMModel.DOMNodeSnapshot))return null;let s=t.data.networkRequest;return{renderedWidget:c`
    ${s?uo(s):m.nothing}
    <devtools-widget class="dom-tree-widget" ${P(te.ElementsTreeOutline.DOMTreeWidget,{maxTreeDepth:2,enableContextMenu:!1,showComments:!1,showAIButton:!1,disableEdits:!0,expandRoot:!0,rootDOMNode:e,visibleWidth:400,wrap:!0,maxRows:10})}></devtools-widget>
  `,revealable:new H.DOMModel.DeferredDOMNode(e.domModel().target(),e.backendNodeId()),accessibleRevealLabel:t.data.accessibleRevealLabel,title:t.data.title,jslogContext:"dom-snapshot"}}function $s(t){switch(t.name){case"COMPUTED_STYLES":return`${t.name}:${t.data.backendNodeId}`;case"CORE_VITALS":return`${t.name}:${t.data.insightSetKey}`;case"STYLE_PROPERTIES":return`${t.name}:${t.data.backendNodeId}:${t.data.selector??""}`;case"DOM_TREE":return`${t.name}:${t.data.root.backendNodeId()}`;case"PERFORMANCE_TRACE":return`${t.name}`;case"PERF_INSIGHT":return`${t.name}:${t.data.insight}:${t.data.insightData.insightKey}:${t.data.insightData.navigation?.args?.data?.navigationId??"no-nav-id"}`;case"TIMELINE_RANGE_SUMMARY":return`${t.name}:${t.data.track}:${t.data.bounds.min}-${t.data.bounds.max}`;case"BOTTOM_UP_TREE":return`${t.name}:${t.data.bounds.min}-${t.data.bounds.max}`;case"NETWORK_TRACK":return`${t.name}:${t.data.bounds.min}-${t.data.bounds.max}`;case"SOURCE_FILE":return`${t.name}:${t.data.uiSourceCode.url()}`;case"SOURCE_FILES_LIST":return`${t.name}:${t.data.uiSourceCodes.map(e=>e.url()).join(",")}`;case"LIGHTHOUSE_REPORT":return`${t.name}:${t.data.report.fetchTime}`;case"TIMELINE_EVENT_SUMMARY":return`${t.name}:${t.data.event.ts}:${t.data.event.name}`;case"NETWORK_REQUEST_GENERAL_HEADERS":return`${t.name}:${t.data.request.requestId()}`;case"SOURCE_CODE":return`${t.name}:${t.data.url}:${t.data.line??""}:${t.data.column??""}`;case"NETWORK_REQUESTS_LIST":return`${t.name}:${t.data.requests.map(e=>e.requestId()).join(",")}`;case"STORAGE_BREAKDOWN":return`${t.name}:${t.data.totalUsageBytes}:${t.data.usageBreakdown.map(e=>`${e.storageType}_${e.bytes}`).join(",")}`;default:kt.assertNever(t,"Unknown AiWidget name")}}function He(t){let e=new Set,s=o=>o.filter(n=>{let a=$s(n);return e.has(a)?!1:(e.add(a),!0)}),i=t.parts.map(o=>o.type==="widget"?{...o,widgets:s(o.widgets)}:o.type==="step"&&o.step.widgets?{...o,step:{...o.step,widgets:s(o.step.widgets)}}:o);return{...t,parts:i}}async function Rs(t,e={}){if(!t||t.length===0)return m.nothing;let i=(await Promise.all(t.map(async o=>{let n=null;switch(o.name){case"COMPUTED_STYLES":n=await Zi(o);break;case"CORE_VITALS":n=await eo(o);break;case"STYLE_PROPERTIES":n=await to(o);break;case"DOM_TREE":n=await mo(o);break;case"PERFORMANCE_TRACE":n=await ro(o);break;case"PERF_INSIGHT":n=await oo(o);break;case"TIMELINE_RANGE_SUMMARY":n=await bo(o);break;case"BOTTOM_UP_TREE":n=await no(o);break;case"NETWORK_TRACK":n=await wo(o);break;case"SOURCE_FILE":n=await lo(o);break;case"SOURCE_FILES_LIST":n=await go(o);break;case"NETWORK_REQUESTS_LIST":n=await ho(o);break;case"LIGHTHOUSE_REPORT":n=await xo(o);break;case"TIMELINE_EVENT_SUMMARY":n=await ko(o);break;case"NETWORK_REQUEST_GENERAL_HEADERS":n=await Co(o);break;case"SOURCE_CODE":n=await co(o);break;case"STORAGE_BREAKDOWN":n=await Qi(o);break;default:kt.assertNever(o,"Unknown AiWidget name")}return ao(n)}))).filter(o=>o!==m.nothing);return i.length===0?m.nothing:e.wrapperClass?c`<div class=${e.wrapperClass}>${i}</div>`:c`${i}`}function po(t){if(t.state.type!=="needs_approval")return m.nothing;let e=t.state.sideEffectDialog;return c`<div
    class="side-effect-confirmation"
    jslog=${E.section("side-effect-confirmation")}
  >
    ${e.description?c`<p>${e.description}</p>`:m.nothing}
    <div class="side-effect-buttons-container">
      <devtools-button
        .data=${{variant:"outlined",jslogContext:"decline-execute-code"}}
        @click=${()=>e.onAnswer(!1)}
      >${h(r.declineActionRequestApproval)}</devtools-button>
      <devtools-button
        .data=${{variant:"primary",jslogContext:"accept-execute-code",iconName:"play"}}
        @click=${()=>e.onAnswer(!0)}
      >${h(r.confirmActionRequestApproval)}</devtools-button>
    </div>
  </div>`}function vo(t){if(t.error){let e;switch(t.error){case"unknown":case"block":e=r.systemError;break;case"quota":e=r.quotaError;break;case"max-steps":e=r.maxStepsError;break;case"cross-origin":e=r.crossOriginError;break;case"payload-too-large":e=r.payloadTooLargeError;break;case"abort":return c`<p class="aborted" jslog=${E.section("aborted")}>${h(r.stoppedResponse)}</p>`}return c`<p class="error" jslog=${E.section("error")}>${h(e)}</p>`}return m.nothing}function fo(t){if(t.data===N.AiConversation.NOT_FOUND_IMAGE_DATA)return c`<div class="unavailable-image" title=${r.imageUnavailable}>
      <devtools-icon name='file-image'></devtools-icon>
    </div>`;let e=`data:${t.mimeType};base64,${t.data}`;return c`<devtools-link
      class="image-link" title=${r.openImageInNewTab}
      href=${e}
    >
      <img src=${e} alt=${r.imageInputSentToTheModel} />
    </devtools-link>`}function yo(t,e){return c`
    <div class="ai-assistance-feedback-row">
      <div class="action-buttons">
        ${t.showRateButtons?c`
          <devtools-button
            .data=${{variant:"icon",size:"SMALL",iconName:"thumb-up",toggledIconName:"thumb-up-filled",toggled:t.currentRating==="POSITIVE",toggleType:"primary-toggle",title:h(r.thumbsUp),jslogContext:"thumbs-up"}}
            @click=${()=>t.onRatingClick("POSITIVE")}
          ></devtools-button>
          <devtools-button
            .data=${{variant:"icon",size:"SMALL",iconName:"thumb-down",toggledIconName:"thumb-down-filled",toggled:t.currentRating==="NEGATIVE",toggleType:"primary-toggle",title:h(r.thumbsDown),jslogContext:"thumbs-down"}}
            @click=${()=>t.onRatingClick("NEGATIVE")}
          ></devtools-button>
        `:m.nothing}
        <devtools-button
          .data=${{variant:"icon",size:"SMALL",title:h(r.report),iconName:"report",jslogContext:"report"}}
          @click=${t.onReportClick}
        ></devtools-button>
        ${t.onExportClick&&t.isLastMessage?c`
          <devtools-button
            class="export-for-agents-button"
            .jslogContext=${"ai-export-for-agents"}
            .variant=${"outlined"}
            .iconName=${"copy"}
            aria-label=${h(r.exportForAgents)}
            @click=${t.onExportClick}
          >${h(r.exportForAgents)}</devtools-button>
          ${t.suggestions?c`<div class="vertical-separator"></div>`:m.nothing}
        `:m.nothing}
      </div>
      ${t.suggestions?c`<div class="suggestions-container">
        <div class="scroll-button-container left hidden" ${Ge(s=>{e.suggestionsLeftScrollButtonContainer=s})}>
          <devtools-button
            class='scroll-button'
            .data=${{variant:"icon",size:"SMALL",iconName:"chevron-left",title:h(r.scrollToPrevious),jslogContext:"chevron-left"}}
            @click=${()=>t.scrollSuggestionsScrollContainer("left")}
          ></devtools-button>
        </div>
        <div class="suggestions-scroll-container" @scroll=${t.onSuggestionsScrollOrResize} ${Ge(s=>{e.suggestionsScrollContainer=s})}>
          ${t.suggestions.map(s=>c`<devtools-button
            class='suggestion'
            .data=${{variant:"outlined",title:s,jslogContext:"suggestion"}}
            @click=${()=>t.onSuggestionClick(s)}
          >${s}</devtools-button>`)}
        </div>
        <div class="scroll-button-container right hidden" ${Ge(s=>{e.suggestionsRightScrollButtonContainer=s})}>
          <devtools-button
            class='scroll-button'
            .data=${{variant:"icon",size:"SMALL",iconName:"chevron-right",title:h(r.scrollToNext),jslogContext:"chevron-right"}}
            @click=${()=>t.scrollSuggestionsScrollContainer("right")}
          ></devtools-button>
        </div>
      </div>`:m.nothing}
    </div>
    ${t.isShowingFeedbackForm?c`
      <form class="feedback-form" @submit=${t.onSubmit}>
        <div class="feedback-header">
          <h4 class="feedback-title">${h(r.whyThisRating)}</h4>
          <devtools-button
            aria-label=${h(r.close)}
            @click=${t.onClose}
            .data=${{variant:"icon",iconName:"cross",size:"SMALL",title:h(r.close),jslogContext:"close"}}
          ></devtools-button>
        </div>
        <input
          type="text"
          class="devtools-text-input feedback-input"
          @input=${s=>t.onInputChange(s.target.value)}
          placeholder=${h(r.provideFeedbackPlaceholder)}
          jslog=${E.textField("feedback").track({keydown:"Enter"})}
        >
        <span class="feedback-disclaimer">${h(r.disclaimer)}</span>
        <div>
          <devtools-button
          aria-label=${h(r.submit)}
          .data=${{type:"submit",disabled:t.isSubmitButtonDisabled,variant:"outlined",size:"SMALL",title:h(r.submit),jslogContext:"send"}}
          >${h(r.submit)}</devtools-button>
        </div>
      </div>
    </form>
    `:m.nothing}
  `}var ke=class extends Ye.Widget.Widget{message={entity:"user",text:"",id:""};isLoading=!1;isReadOnly=!1;prompt="";canShowFeedbackForm=!1;isLastMessage=!1;isFirstMessage=!1;markdownRenderer;onSuggestionClick=()=>{};onFeedbackSubmit=()=>{};onCopyResponseClick=()=>{};onExportClick=()=>{};walkthrough={onOpen:()=>{},onToggle:()=>{},isInlined:!1,isExpanded:!1,activeSidebarMessage:null,inlineExpandedMessages:[]};#s=new ResizeObserver(()=>this.#l());#t=new B.Throttler.Throttler(100);#i="";#o;#a=!1;#r=!0;#c;#d={};#e=!1;constructor(e,s){super(e),this.#c=s??Ls}wasShown(){super.wasShown(),this.performUpdate(),this.#h()}performUpdate(){let e=this.message.entity==="model"?He(this.message):this.message;this.#c({message:e,isLoading:this.isLoading,isReadOnly:this.isReadOnly,canShowFeedbackForm:this.canShowFeedbackForm,markdownRenderer:this.markdownRenderer,isLastMessage:this.isLastMessage,isFirstMessage:this.isFirstMessage,prompt:this.prompt,onSuggestionClick:this.onSuggestionClick,onRatingClick:this.#m.bind(this),onReportClick:()=>Ss.openInNewTab(_i),onCopyResponseClick:()=>{this.message.entity==="model"&&this.onCopyResponseClick(this.message)},onExportClick:this.onExportClick,scrollSuggestionsScrollContainer:this.#u.bind(this),onSuggestionsScrollOrResize:this.#l.bind(this),onSubmit:this.#b.bind(this),onClose:this.#p.bind(this),onInputChange:this.#g.bind(this),isSubmitButtonDisabled:this.#r,showActions:!(this.isLastMessage&&this.isLoading),showRateButtons:this.message.entity==="model"&&!!this.message.rpcId,suggestions:this.isLastMessage&&this.message.entity==="model"&&!this.isReadOnly&&this.message.parts.at(-1)?.type==="answer"?this.message.parts.at(-1).suggestions:void 0,currentRating:this.#o,isShowingFeedbackForm:this.#a,onFeedbackSubmit:this.onFeedbackSubmit,walkthrough:this.walkthrough},this.#d,this.contentElement),this.#d.suggestionsScrollContainer&&!this.#e&&(this.#s.observe(this.#d.suggestionsScrollContainer),this.#e=!0)}#g(e){this.#i=e;let s=!e;s!==this.#r&&(this.#r=s,this.performUpdate())}#h=()=>{let e=this.#d.suggestionsScrollContainer,s=this.#d.suggestionsLeftScrollButtonContainer,i=this.#d.suggestionsRightScrollButtonContainer;if(!e||!s||!i)return;let o=e.scrollLeft>ps,n=e.scrollLeft+e.offsetWidth+ps<e.scrollWidth;s.classList.toggle("hidden",!o),i.classList.toggle("hidden",!n)};willHide(){super.willHide(),this.#s.disconnect(),this.#e=!1}#l(){this.#t.schedule(()=>(this.#h(),Promise.resolve()))}#u(e){let s=this.#d.suggestionsScrollContainer;s&&s.scroll({top:0,left:e==="left"?s.scrollLeft-s.clientWidth:s.scrollLeft+s.clientWidth,behavior:"smooth"})}#m(e){if(this.#o===e){this.#o=void 0,this.#a=!1,this.#r=!0,this.message.entity==="model"&&this.message.rpcId&&this.onFeedbackSubmit(this.message.rpcId,"SENTIMENT_UNSPECIFIED"),this.performUpdate();return}this.#o=e,this.#a=this.canShowFeedbackForm,this.message.entity==="model"&&this.message.rpcId&&this.onFeedbackSubmit(this.message.rpcId,e),this.performUpdate()}#p(){this.#a=!1,this.#r=!0,this.performUpdate()}#b(e){e.preventDefault();let s=this.#i;!this.#o||!s||(this.message.entity==="model"&&this.message.rpcId&&this.onFeedbackSubmit(this.message.rpcId,this.#o,s),this.#a=!1,this.#r=!0,this.performUpdate())}};async function bo(t){let{bounds:e,parsedTrace:s,track:i}=t.data,o=[];if(i==="main"){let l;for(let k of s.data.Meta.mainFrameNavigations)if(k.ts<=e.min)l=k.args.data?.navigationId;else break;let p=N.AIQueries.AIQueries.findMainThread(l,s);p&&(o=p.entries,N.Debug.debugLog("TimelineRangeSummaryAiWidget found main thread. PID:",p.pid,"TID:",p.tid,"Number of entries:",p.entries.length))}if(!o)return N.Debug.debugLog("Warning: could not find events for TimelineRangeSummaryAiWidget",t),null;let n=new D.ThirdPartyTreeView.ThirdPartyTreeViewWidget,a=x.EntityMapper.EntityMapper.getOrCreate(s);return n.model={selectedEvents:o,parsedTrace:s,entityMapper:a},n.activeSelection=D.TimelineSelection.selectionFromRangeMicroSeconds(e.min,e.max),n.refreshTree(!0),{renderedWidget:c`
    <devtools-widget
      ${P(Xe.TimelineRangeSummaryView.TimelineRangeSummaryView,{data:{parsedTrace:s,events:o,isInAIWidget:!0,startTime:x.Helpers.Timing.microToMilli(e.min),endTime:x.Helpers.Timing.microToMilli(e.max),thirdPartyTreeTemplate:c`${P(D.ThirdPartyTreeView.ThirdPartyTreeViewWidget,{maxRows:10,isInAIWidget:!0,model:{selectedEvents:n.selectedEvents??null,parsedTrace:s,entityMapper:n.entityMapper()},activeSelection:{bounds:e},onBottomUpButtonClicked:l=>{B.Revealer.reveal(new oe.Helpers.RevealableBottomUpProfile(e,l??void 0))}})}`}})}
    ></devtools-widget>`,revealable:new oe.Helpers.RevealableTimeRange(e),accessibleRevealLabel:h(r.revealPerformanceSummary),title:h(r.performanceSummary),jslogContext:"timeline-range-summary"}}async function wo(t){let{parsedTrace:e,bounds:s}=t.data,i=new D.TimelineFlameChartNetworkDataProvider.TimelineFlameChartNetworkDataProvider;return{renderedWidget:c`
    <devtools-performance-agent-network-track
      .data=${{parsedTrace:e,bounds:s,dataProvider:i}}
    ></devtools-performance-agent-network-track>`,revealable:new oe.Helpers.RevealableTimeRange(s),accessibleRevealLabel:h(r.revealNetworkActivity),title:h(r.networkActivitySummary),jslogContext:"network-track-widget"}}async function xo(t){let e=null;try{e=Je.LighthouseReportRenderer.LighthouseReportRenderer.renderLighthouseScores(t.data.report)}catch{e=null}let s=t.data.snapshotReport,i=h(r.revealLighthouse),o=e?h(r.lighthouseReport):null,n=e?void 0:i;return{renderedWidget:e?c`<div class="lighthouse-report-widget">${e}</div>`:null,revealable:new Je.LighthousePanel.ActiveLighthouseReport(t.data.report),accessibleRevealLabel:i,customRevealTitle:n,title:o,jslogContext:s?"lighthouse-snapshot-report-widget":"lighthouse-report-widget"}}async function ko(t){return{renderedWidget:c`<devtools-widget class="timeline-event-summary-widget" ${P(()=>D.TimelineDetailsView.TimelineDetailsPane.makeEventWidget(t.data.event,t.data.parsedTrace))}></devtools-widget>`,revealable:new H.TraceObject.RevealableEvent(t.data.event),accessibleRevealLabel:h(r.revealTimelineEventSummary),title:h(r.timelineEventSummary),jslogContext:"timeline-event-summary-widget"}}async function Co(t){return{renderedWidget:c`<devtools-widget class="network-request-general-headers-widget" ${P(()=>As.RequestHeadersView.RequestHeadersView.createGeneralHeadersView(t.data.request))}></devtools-widget>`,revealable:Is.UIRequestLocation.UIRequestLocation.tab(t.data.request,"headers-component"),accessibleRevealLabel:h(r.revealNetworkRequest),title:h(r.networkRequest),jslogContext:"network-request-general-headers-widget"}}var Ds=`*{box-sizing:border-box;margin:0;padding:0}:host{width:100%;height:100%;user-select:text;display:flex;flex-direction:column;background-color:var(--sys-color-cdt-base-container)}.chat-ui{width:100%;height:100%;max-height:100%;display:flex;flex-direction:column;container-type:size;container-name:--chat-ui-container}.info-tooltip-container{max-width:var(--sys-size-28);padding:var(--sys-size-4) var(--sys-size-5)}.tooltip-link{display:block;margin-top:var(--sys-size-4);color:var(--sys-color-primary);padding-left:0}.chat-cancel-context-button{padding-bottom:3px;padding-right:var(--sys-size-3)}.messages-container{flex-grow:1;width:100%;max-width:var(--sys-size-36);@container (width > 688px){--half-scrollbar-width:calc((100cqw - 100%) / 2);margin-left:var(--half-scrollbar-width);margin-right:calc(-1 * var(--half-scrollbar-width))}}.link{color:var(--text-link);text-decoration:underline;cursor:pointer}button.link{border:none;background:none;font:inherit;&:focus-visible{outline:var(--sys-size-2) solid var(--sys-color-state-focus-ring);outline-offset:0;border-radius:var(--sys-shape-corner-extra-small)}}.select-an-element-text{margin-left:2px}main{overflow:hidden auto;display:flex;flex-direction:column;align-items:center;height:100%;container-type:size;scrollbar-width:thin;transform:translateZ(1px);scroll-timeline:--scroll-timeline y}.empty-state-container{flex-grow:1;display:grid;align-items:center;justify-content:center;font:var(--sys-typescale-headline4);gap:var(--sys-size-8);padding:var(--sys-size-4);max-width:var(--sys-size-33);@container (width > 688px){--half-scrollbar-width:calc((100cqw - 100%) / 2);margin-left:var(--half-scrollbar-width);margin-right:calc(-1 * var(--half-scrollbar-width))}.header{display:flex;flex-direction:column;width:100%;align-items:center;justify-content:center;align-self:end;gap:var(--sys-size-5);.icon{display:flex;justify-content:center;align-items:center;height:var(--sys-size-14);width:var(--sys-size-14);border-radius:var(--sys-shape-corner-small);background:linear-gradient(135deg,var(--sys-color-gradient-primary),var(--sys-color-gradient-tertiary))}h1{font:var(--sys-typescale-headline4)}p{text-align:center;font:var(--sys-typescale-body4-regular)}}.empty-state-content{display:flex;flex-direction:column;gap:var(--sys-size-5);align-items:center;justify-content:center;align-self:start}}.gemini{.empty-state-container{padding:var(--sys-size-8)}.empty-state-container .icon{display:none}.empty-state-container .header{align-items:flex-start;line-height:var(--sys-size-4)}.empty-state-content{align-items:flex-start}.empty-state-container .greeting{font-size:var(--sys-size-10);color:var(--sys-color-primary)}.empty-state-container .cta{font-size:var(--sys-size-10)}main{align-items:flex-start}}.change-summary{background-color:var(--sys-color-surface3);border-radius:var(--sys-shape-corner-medium-small);position:relative;margin:0 var(--sys-size-5) var(--sys-size-7) var(--sys-size-5);padding:0 var(--sys-size-5);&.saved-to-disk{pointer-events:none}& .header-container{display:flex;align-items:center;gap:var(--sys-size-3);height:var(--sys-size-14);padding-left:var(--sys-size-3);devtools-spinner{width:var(--sys-size-6);height:var(--sys-size-6);margin-left:var(--sys-size-3);margin-right:var(--sys-size-3)}& devtools-icon.summary-badge{width:var(--sys-size-8);height:var(--sys-size-8)}& .green-bright-icon{color:var(--sys-color-green-bright)}& .on-tonal-icon{color:var(--sys-color-on-tonal-container)}& .header-text{font:var(--sys-typescale-body4);color:var(--sys-color-on-surface);white-space:nowrap;overflow-x:hidden;text-overflow:ellipsis}& .arrow{margin-left:auto}&::marker{content:''}}&:not(.saved-to-disk, &[open]):hover::after{content:'';height:100%;width:100%;border-radius:inherit;position:absolute;top:0;left:0;pointer-events:none;background-color:var(--sys-color-state-hover-on-subtle)}&[open]:not(.saved-to-disk){&::details-content{height:fit-content;padding:var(--sys-size-2) 0;border-radius:inherit}summary .arrow{transform:rotate(180deg)}}devtools-code-block{margin-bottom:var(--sys-size-5);--code-block-background-color:var(--sys-color-surface1)}.error-container{display:flex;align-items:center;gap:var(--sys-size-3);color:var(--sys-color-error)}.footer{display:flex;flex-flow:row wrap;justify-content:space-between;margin:var(--sys-size-5) 0 var(--sys-size-5) var(--sys-size-2);gap:var(--sys-size-6) var(--sys-size-5);.disclaimer-link{align-self:center}.left-side{flex-grow:1;display:flex;align-self:center;gap:var(--sys-size-3)}.save-or-discard-buttons{flex-grow:1;display:flex;justify-content:flex-end;gap:var(--sys-size-3)}.change-workspace{display:flex;flex-direction:row;align-items:center;gap:var(--sys-size-3);min-width:var(--sys-size-22);flex:1 1 40%;.folder-name{white-space:nowrap;overflow-x:hidden;text-overflow:ellipsis}}.loading-text-container{margin-right:var(--sys-size-3);display:flex;justify-content:center;align-items:center;gap:var(--sys-size-3)}.apply-to-workspace-container{display:flex;align-items:center;gap:var(--sys-size-3);min-width:fit-content;justify-content:flex-end;flex-grow:1;flex-shrink:1;devtools-icon{width:18px;height:18px;margin-left:var(--sys-size-2)}}}}@keyframes reveal{0%,
  99%{opacity:100%}100%{opacity:0%}}.sticky{position:sticky;bottom:0;z-index:9999}.chat-input-widget{width:100%;max-width:var(--sys-size-36);background-color:var(--sys-color-cdt-base-container);box-shadow:0 1px var(--sys-color-cdt-base-container);@container (width > 688px){--half-scrollbar-width:calc((100cqw - 100%) / 2);margin-left:var(--half-scrollbar-width);margin-right:calc(-1 * var(--half-scrollbar-width))}@container (height < 224px){margin-top:var(--sys-size-4);margin-bottom:var(--sys-size-4);position:static}@container --chat-ui-container (width < 400px){padding-bottom:var(--sys-size-1)}}
/*# sourceURL=${import.meta.resolve("././components/chatView.css")} */`;var Vs={};j(Vs,{DEFAULT_VIEW:()=>Os,ExportForAgentsDialog:()=>Ce});import"./../../ui/components/spinners/spinners.js";import*as Us from"./../../core/host/host.js";import*as Tt from"./../../core/i18n/i18n.js";import"./../../ui/components/buttons/buttons.js";import*as Ns from"./../../ui/components/snackbars/snackbars.js";import*as Ze from"./../../ui/legacy/legacy.js";import*as St from"./../../ui/lit/lit.js";import*as Fs from"./../../ui/visual_logging/visual_logging.js";var Ps=`@scope to (devtools-widget > *){:scope{width:100%;box-shadow:none;padding:var(--sys-size-8);background-color:var(--sys-color-surface);border-radius:var(--sys-shape-corner-medium)}.export-for-agents-dialog{width:var(--sys-size-33);max-width:100%}.export-for-agents-dialog header{margin-bottom:var(--sys-size-6);h1{font:var(--sys-typescale-headline5);margin:0;color:var(--sys-color-on-surface)}}.export-for-agents-dialog .state-selection{display:flex;gap:var(--sys-size-5);margin:var(--sys-size-7) 0}.export-for-agents-dialog .state-selection label{display:flex;align-items:center;gap:var(--sys-size-2);cursor:pointer;font:var(--sys-typescale-body3-regular);input{margin-bottom:0}}.export-for-agents-dialog textarea{width:100%;min-height:var(--sys-size-30);max-height:var(--sys-size-34);resize:none;padding:var(--sys-size-5);box-sizing:border-box;font-family:var(--monospace-font-family);font-size:var(--monospace-font-size);background-color:var(--sys-color-surface5);color:var(--sys-color-on-surface);border-radius:var(--sys-shape-corner-small);border:none}main{position:relative}.prompt-loading{position:absolute;padding:var(--sys-size-5);display:flex;align-items:center;justify-content:flex-start;gap:var(--sys-size-5)}.export-for-agents-dialog .disclaimer{margin-top:var(--sys-size-5);font:var(--sys-typescale-body4-regular);color:var(--sys-color-on-surface-subtle)}.export-for-agents-dialog footer{display:flex;justify-content:flex-end;margin-top:var(--sys-size-6)}.export-for-agents-dialog .right-buttons{display:flex;gap:var(--sys-size-5)}}
/*# sourceURL=${import.meta.resolve("././components/exportForAgentsDialog.css")} */`;var{html:Qe,render:To}=St,z={exportForAgents:"Copy to coding agent",copyToClipboard:"Copy to clipboard",copiedToClipboard:"Copied to clipboard",asPrompt:"Summary prompt",asMarkdown:"Full conversation",saveAsMarkdown:"Save as\u2026",generatingSummary:"Generating summary\u2026",disclaimer:"This is an experimental AI feature and won\u2019t always get it right. Double check this text before pasting into another tool."},So=Tt.i18n.registerUIStrings("panels/ai_assistance/components/ExportForAgentsDialog.ts",z),F=Tt.i18n.getLocalizedString.bind(void 0,So),zs="prompt",Os=(t,e,s)=>{let i=t.state.activeType==="prompt",o=F(i?z.copyToClipboard:z.saveAsMarkdown),n=i?t.state.promptText:t.state.conversationText;To(Qe`
    <style>${Ps}</style>
    <div class="export-for-agents-dialog" jslog=${Fs.dialog("ai-export-for-agents")}>
      <header>
        <h1 id="export-for-agents-dialog-title" tabindex="-1">
          ${F(z.exportForAgents)}
        </h1>
      </header>
      <div class="state-selection" role="radiogroup" aria-labelledby="export-for-agents-dialog-title">
        <label>
          <input
            type="radio"
            value="prompt"
            name="export-state"
            .checked=${i}
            autofocus
            aria-label=${F(z.asPrompt)}
            @change=${()=>t.onStateChange("prompt")}
          >
          ${F(z.asPrompt)}
        </label>
        <label>
          <input
            type="radio"
            value="conversation"
            name="export-state"
            .checked=${!i}
            aria-label=${F(z.asMarkdown)}
            @change=${()=>t.onStateChange("conversation")}
          >
          ${F(z.asMarkdown)}
        </label>
      </div>
      <main>
        ${i&&t.state.isPromptLoading?Qe`
          <span class="prompt-loading">
            <devtools-spinner></devtools-spinner>
            ${F(z.generatingSummary)}
          </span>
          `:St.nothing}
        ${i?Qe`<textarea class="prompt" readonly .value=${t.state.isPromptLoading?"":n}></textarea>`:Qe`<textarea class="conversation" readonly .value=${n}></textarea>`}
      </main>
      <div class="disclaimer">${F(z.disclaimer)}</div>
      <footer>
        <div class="right-buttons">
          <devtools-button
            @click=${t.onButtonClick}
            .jslogContext=${t.jslogContext}
            .variant=${"primary"}
            .disabled=${i&&t.state.isPromptLoading}
            .accessibleLabel=${o}
          >
            ${o}
          </devtools-button>
        </div>
      </footer>
    </div>
  `,s)},Ce=class t extends Ze.Widget.VBox{static#s=zs;#t;#i;#o;#a;constructor(e,s=Os){super(),this.#i=e.dialog,this.#o={activeType:t.#s,promptText:typeof e.promptText=="string"?e.promptText:"",conversationText:e.markdownText,isPromptLoading:typeof e.promptText!="string"},this.#a=e.onConversationSaveAs,this.#t=s,typeof e.promptText!="string"&&e.promptText.then(i=>{this.#o.promptText=i,this.#o.isPromptLoading=!1,this.requestUpdate()}),this.requestUpdate()}static clearPersistedViewState(){t.#s=zs}#r=e=>{this.#o.activeType=e,t.#s=e,this.requestUpdate()};performUpdate(){let e,s="";switch(this.#o.activeType){case"prompt":s="ai-export-for-agents.copy-to-clipboard",e=o=>{o.preventDefault(),Us.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(this.#o.promptText),Ns.Snackbar.Snackbar.show({message:F(z.copiedToClipboard)}).setAttribute("aria-label",F(z.copiedToClipboard)),this.#i.hide()};break;case"conversation":s="ai-export-for-agents.save-as-markdown",e=()=>{this.#i.hide(),this.#a()};break}let i={onButtonClick:e,state:this.#o,onStateChange:this.#r,jslogContext:s};this.#t(i,void 0,this.contentElement)}static show({promptText:e,markdownText:s,onConversationSaveAs:i}){let o=new Ze.Dialog.Dialog;o.setAriaLabel(F(z.exportForAgents)),o.setOutsideClickCallback(a=>{a.consume(!0),o.hide()}),o.addCloseButton(),o.setSizeBehavior("MeasureContent"),o.setDimmed(!0);let n=new t({dialog:o,promptText:e,markdownText:s,onConversationSaveAs:i});n.show(o.contentElement),n.updateComplete.then(()=>{o.show()})}};var{ref:It,repeat:Lo,classMap:Ws}=Io,{widget:js}=Hs.Widget,Bs={emptyStateText:"How can I help you?",emptyStateTextGemini:"Where should we start?"},_s=qs.i18n.lockedString,Mo=1,$o=(t,e,s)=>{let i=Ws({"chat-ui":!0,gemini:At.AiUtils.isGeminiBranding()}),o=Ws({"chat-input-widget":!0,sticky:!t.isReadOnly});Ao(le`
      <style>${Ds}</style>
      <div class=${i}>
        <main @scroll=${t.handleScroll} ${It(n=>{e.mainElement=n})}>
          ${t.messages.length>0?le`
            <div class="messages-container" ${It(t.handleMessageContainerRef)}>
              ${Lo(t.messages,n=>n.id,(n,a)=>{let d=a>0?t.messages[a-1]:null,l=n.entity==="model"&&d?.entity==="user"?d.text:"";return js(ke,{message:n,isLoading:t.isLoading&&a===t.messages.length-1,isReadOnly:t.isReadOnly,canShowFeedbackForm:t.canShowFeedbackForm,markdownRenderer:t.markdownRenderer,isLastMessage:a===t.messages.length-1,isFirstMessage:a===0,prompt:l,onSuggestionClick:t.handleSuggestionClick,onFeedbackSubmit:t.onFeedbackSubmit,onCopyResponseClick:t.onCopyResponseClick,onExportClick:t.exportForAgentsClick,walkthrough:{...t.walkthrough}})})}
            </div>
          `:le`
            <div class="empty-state-container">
              <div class="header">
                <div class="icon">
                  <devtools-icon
                    name="smart-assistant"
                  ></devtools-icon>
                </div>
                ${At.AiUtils.isGeminiBranding()?le`
                    <h1 class='greeting'>Hello</h1>
                    <p class='cta'>${_s(Bs.emptyStateTextGemini)}</p>
                  `:le`<h1>${_s(Bs.emptyStateText)}</h1>`}
              </div>
              <div class="empty-state-content">
                ${t.emptyStateSuggestions.map(({title:n,jslogContext:a})=>le`<devtools-button
                    class="suggestion"
                    @click=${()=>t.handleSuggestionClick(n)}
                    .data=${{variant:"outlined",size:"REGULAR",title:n,jslogContext:a??"suggestion",disabled:t.isTextInputDisabled}}
                  >${n}</devtools-button>`)}
              </div>
            </div>
          `}
          <devtools-widget class=${o} ${js(ae,{isLoading:t.isLoading,blockedByCrossOrigin:t.blockedByCrossOrigin,isTextInputDisabled:t.isTextInputDisabled,inputPlaceholder:t.inputPlaceholder,disclaimerText:t.disclaimerText,context:t.context,isContextSelected:t.isContextSelected,inspectElementToggled:t.inspectElementToggled,multimodalInputEnabled:t.multimodalInputEnabled??!1,conversationType:t.conversationType,uploadImageInputEnabled:t.uploadImageInputEnabled??!1,isReadOnly:t.isReadOnly,textInputValue:t.textInputValue,onTextChange:t.onTextChange,onContextClick:t.onContextClick,onInspectElementClick:t.onInspectElementClick,onTextSubmit:t.onTextSubmit,onCancelClick:t.onCancelClick,onNewConversation:t.onNewConversation,onContextRemoved:t.onContextRemoved,onContextAdd:t.onContextAdd})} ${It(n=>{e.input=n})}></devtools-widget>
        </main>
      </div>
    `,s)},Te=class extends HTMLElement{#s=this.attachShadow({mode:"open"});#t;#i;#o;#a={};#r=new ResizeObserver(()=>this.#h());#c=!0;#d=!1;#e;#g=null;constructor(e,s=$o){super(),this.#i=e,this.#e=s}set props(e){this.#i=e,this.#f()}connectedCallback(){this.#f(),this.#o&&this.#r.observe(this.#o)}disconnectedCallback(){this.#r.disconnect()}focusTextInput(){let e=this.#s.querySelector(".chat-input");e&&e.focus()}setInputValue(e){this.#a.input?.getWidget()?.setInputValue(e)}restoreScrollPosition(){this.#t!==void 0&&this.#a.mainElement&&this.#l(this.#t)}scrollToBottom(){this.#a.mainElement&&this.#l(this.#a.mainElement.scrollHeight)}#h(){this.#c&&this.#a.mainElement&&this.#c&&this.#l(this.#a.mainElement.scrollHeight)}#l(e){this.#a.mainElement&&(this.#t=e,this.#d=!0,this.#a.mainElement.scrollTop=e)}#u=e=>{this.#o=e,e?this.#r.observe(e):(this.#c=!0,this.#r.disconnect())};#m=e=>{if(!(!e.target||!(e.target instanceof HTMLElement))){if(this.#d){this.#d=!1;return}this.#t=e.target.scrollTop,this.#c=e.target.scrollTop+e.target.clientHeight+Mo>e.target.scrollHeight}};#p=e=>{this.#a.input?.getWidget()?.setInputValue(e),this.#f(),this.focusTextInput(),et.userMetrics.actionTaken(et.UserMetrics.Action.AiAssistanceDynamicSuggestionClicked)};async#b(){let e=this.#i.conversationMarkdown.replace(/\*\*Export Timestamp \(UTC\):\*\* .*\n\n/,"");if(this.#g?.markdown===e)return this.#g.summary;try{let s=await this.#i.generateConversationSummary(this.#i.conversationMarkdown);return this.#g={markdown:e,summary:s},s}catch(s){return console.error(s),"Failed to generate summary."}}async#y(){let e=this.#b();Ce.show({promptText:e,markdownText:this.#i.conversationMarkdown,onConversationSaveAs:this.#i.onExportConversation??(async()=>{})})}#f(){this.#e({...this.#i,handleScroll:this.#m,handleSuggestionClick:this.#p,handleMessageContainerRef:this.#u,exportForAgentsClick:this.#y.bind(this)},this.#a,this.#s)}};customElements.define("devtools-ai-chat-view",Te);var Xs={};j(Xs,{DEFAULT_VIEW:()=>Js,DisabledWidget:()=>Le});import"./../../core/host/host.js";import*as Lt from"./../../core/i18n/i18n.js";import*as Gs from"./../../core/root/root.js";import*as Se from"./../../ui/i18n/i18n.js";import*as ce from"./../../ui/legacy/legacy.js";import{html as Ae,render as Ro}from"./../../ui/lit/lit.js";import*as Ys from"./../../ui/visual_logging/visual_logging.js";var Ks=`@scope to (devtools-widget > *){.disabled-view{display:flex;max-width:var(--sys-size-34);border-radius:var(--sys-shape-corner-small);box-shadow:var(--sys-elevation-level3);background-color:var(--app-color-card-background);font:var(--sys-typescale-body4-regular);text-wrap:pretty;padding:var(--sys-size-6) var(--sys-size-8);margin:var(--sys-size-4);line-height:var(--sys-size-9);.disabled-view-icon-container{flex-shrink:0;border-radius:var(--sys-shape-corner-extra-small);width:var(--sys-size-9);height:var(--sys-size-9);background:linear-gradient(135deg,var(--sys-color-gradient-primary),var(--sys-color-gradient-tertiary));margin-right:var(--sys-size-5);devtools-icon{margin:var(--sys-size-2);width:var(--sys-size-8);height:var(--sys-size-8)}}}.link{color:var(--text-link);text-decoration:underline;cursor:pointer}}
/*# sourceURL=${import.meta.resolve("././components/disabledWidget.css")} */`;var K={notLoggedIn:"This feature is only available when you are signed in to Chrome with your Google account",offline:"Check your internet connection and try again",settingsLink:"AI assistance in Settings",turnOnForStyles:"Turn on {PH1} to get help with understanding CSS styles",turnOnForStylesAndRequests:"Turn on {PH1} to get help with styles and network requests",turnOnForStylesRequestsAndFiles:"Turn on {PH1} to get help with styles, network requests, and files",turnOnForStylesRequestsPerformanceAndFiles:"Turn on {PH1} to get help with styles, network requests, performance, and files",notAvailableInIncognitoMode:"AI assistance is not available in Incognito mode or Guest mode"},Ie=Lt.i18n.registerUIStrings("panels/ai_assistance/components/DisabledWidget.ts",K),tt=Lt.i18n.getLocalizedString.bind(void 0,Ie);function Eo(t){switch(t){case"no-account-email":case"sync-is-paused":return Ae`${tt(K.notLoggedIn)}`;case"no-internet":return Ae`${tt(K.offline)}`}}function Do(t){if(t.isOffTheRecord)return Ae`${tt(K.notAvailableInIncognitoMode)}`;let e=document.createElement("span");e.textContent=tt(K.settingsLink),e.classList.add("link"),ce.ARIAUtils.markAsLink(e),e.addEventListener("click",()=>{ce.ViewManager.ViewManager.instance().showView("chrome-ai")}),e.setAttribute("jslog",`${Ys.action("open-ai-settings").track({click:!0})}`);let s;return t.devToolsAiAssistancePerformanceAgent?.enabled?s=Se.getFormatLocalizedString(Ie,K.turnOnForStylesRequestsPerformanceAndFiles,{PH1:e}):t.devToolsAiAssistanceFileAgent?.enabled?s=Se.getFormatLocalizedString(Ie,K.turnOnForStylesRequestsAndFiles,{PH1:e}):t.devToolsAiAssistanceNetworkAgent?.enabled?s=Se.getFormatLocalizedString(Ie,K.turnOnForStylesAndRequests,{PH1:e}):s=Se.getFormatLocalizedString(Ie,K.turnOnForStyles,{PH1:e}),Ae`${s}`}var Js=(t,e,s)=>{Ro(Ae`
      <style>
        ${Ks}
      </style>
      <div class="disabled-view">
        <div class="disabled-view-icon-container">
          <devtools-icon name="smart-assistant"></devtools-icon>
        </div>
        <div>
          ${t.aidaAvailability==="available"?Do(t.hostConfig):Eo(t.aidaAvailability)}
        </div>
      </div>
    `,s)},Le=class extends ce.Widget.Widget{aidaAvailability="no-account-email";#s;constructor(e,s=Js){super(e),this.#s=s}wasShown(){super.wasShown(),this.requestUpdate()}performUpdate(){let e=Gs.Runtime.hostConfig;this.#s({aidaAvailability:this.aidaAvailability,hostConfig:e},{},this.contentElement)}};var oi={};j(oi,{DEFAULT_VIEW:()=>ii,ExploreWidget:()=>Me});import*as ti from"./../../core/i18n/i18n.js";import*as si from"./../../core/root/root.js";import*as O from"./../../ui/legacy/legacy.js";import{html as Mt,render as Po}from"./../../ui/lit/lit.js";import*as $t from"./../../ui/visual_logging/visual_logging.js";var Qs=`@scope to (devtools-widget > *){.ai-assistance-explore-container{&,
    *{box-sizing:border-box;margin:0;padding:0}width:100%;height:fit-content;display:flex;flex-direction:column;align-items:center;margin:auto 0;font:var(--sys-typescale-headline4);gap:var(--sys-size-8);padding:var(--sys-size-3);overflow:auto;scrollbar-gutter:stable both-edges;.link{padding:0;margin:0 3px}.header{flex-shrink:0;display:flex;flex-direction:column;width:100%;align-items:center;justify-content:center;justify-self:center;gap:var(--sys-size-4);.icon{display:flex;justify-content:center;align-items:center;height:var(--sys-size-14);width:var(--sys-size-14);border-radius:var(--sys-shape-corner-small);background:linear-gradient(135deg,var(--sys-color-gradient-primary),var(--sys-color-gradient-tertiary))}h1{font:var(--sys-typescale-headline4)}p{text-align:center;font:var(--sys-typescale-body4-regular)}.link{font:var(--sys-typescale-body4-regular)}}.content{flex-shrink:0;display:flex;flex-direction:column;gap:var(--sys-size-5);align-items:center;justify-content:center;justify-self:center}.feature-card{display:flex;padding:var(--sys-size-4) var(--sys-size-6);gap:10px;background-color:var(--sys-color-surface2);border-radius:var(--sys-shape-corner-medium-small);width:100%;align-items:center;.feature-card-icon{min-width:var(--sys-size-12);min-height:var(--sys-size-12);display:flex;justify-content:center;align-items:center;background-color:var(--sys-color-tonal-container);border-radius:var(--sys-shape-corner-full);devtools-icon{width:18px;height:18px}}.feature-card-content{h3{font:var(--sys-typescale-body3-medium)}p{font:var(--sys-typescale-body4-regular);line-height:18px}}}}.ai-assistance-explore-footer{flex-shrink:0;width:100%;display:flex;justify-content:center;align-items:center;padding-block:var(--sys-size-3);font:var(--sys-typescale-body5-regular);border-top:1px solid var(--sys-color-divider);text-wrap:balance;text-align:center;p{margin:0;padding:0}}}
/*# sourceURL=${import.meta.resolve("././components/exploreWidget.css")} */`;var Zs={Explore:"Explore AI assistance",learnAbout:"Learn about AI in DevTools"},ei=ti.i18n.lockedString,ii=(t,e,s)=>{function i(o){return Mt`Open
     <button
       class="link"
       role="link"
       jslog=${$t.link(o.jslogContext).track({click:!0})}
       @click=${o.onClick}
     >${o.panelName}</button>
     ${o.text}`}Po(Mt`
      <style>
        ${Qs}
      </style>
      <div class="ai-assistance-explore-container">
        <div class="header">
          <div class="icon">
            <devtools-icon name="smart-assistant"></devtools-icon>
          </div>
          <h1>${ei(Zs.Explore)}</h1>
          <p>
            To chat about an item, right-click and select${" "}
            <strong>Ask AI</strong>.
            <button
              class="link"
              role="link"
              jslog=${$t.link("open-ai-settings").track({click:!0})}
              @click=${()=>{O.ViewManager.ViewManager.instance().showView("chrome-ai")}}
            >${ei(Zs.learnAbout)}
            </button>
          </p>
        </div>
        <div class="content">
          ${t.featureCards.map(o=>Mt`
              <div class="feature-card">
                <div class="feature-card-icon">
                  <devtools-icon name=${o.icon}></devtools-icon>
                </div>
                <div class="feature-card-content">
                  <h3>${o.heading}</h3>
                  <p>${i(o)}</p>
                </div>
              </div>
            `)}
        </div>
      </div>
    `,s)},Me=class extends O.Widget.Widget{#s;constructor(e,s=ii){super(e),this.#s=s}wasShown(){super.wasShown(),this.requestUpdate()}performUpdate(){let e=si.Runtime.hostConfig,s=[];e.devToolsFreestyler?.enabled&&O.ViewManager.ViewManager.instance().hasView("elements")&&s.push({icon:"brush-2",heading:"CSS styles",jslogContext:"open-elements-panel",onClick:()=>{O.ViewManager.ViewManager.instance().showView("elements")},panelName:"Elements",text:"to ask about CSS styles"}),e.devToolsAiAssistanceNetworkAgent?.enabled&&O.ViewManager.ViewManager.instance().hasView("network")&&s.push({icon:"arrow-up-down",heading:"Network",jslogContext:"open-network-panel",onClick:()=>{O.ViewManager.ViewManager.instance().showView("network")},panelName:"Network",text:"to ask about a request's details"}),e.devToolsAiAssistanceFileAgent?.enabled&&O.ViewManager.ViewManager.instance().hasView("sources")&&s.push({icon:"document",heading:"Files",jslogContext:"open-sources-panel",onClick:()=>{O.ViewManager.ViewManager.instance().showView("sources")},panelName:"Sources",text:"to ask about a file's content"}),e.devToolsAiAssistancePerformanceAgent?.enabled&&O.ViewManager.ViewManager.instance().hasView("timeline")&&s.push({icon:"performance",heading:"Performance",jslogContext:"open-performance-panel",onClick:()=>{O.ViewManager.ViewManager.instance().showView("timeline")},panelName:"Performance",text:"to ask about a trace item"}),this.#s({featureCards:s},{},this.contentElement)}};var li={};j(li,{DEFAULT_VIEW:()=>ri,OptInChangeDialog:()=>$e});import*as Et from"./../../core/i18n/i18n.js";import*as Rt from"./../../core/root/root.js";import"./../../ui/components/buttons/buttons.js";import*as st from"./../../ui/legacy/legacy.js";import*as zo from"./../../ui/lit/lit.js";import*as ai from"./../../ui/visual_logging/visual_logging.js";var ni=`@scope to (devtools-widget > *){:scope{width:100%;box-shadow:none;padding:var(--sys-size-8);background-color:var(--sys-color-surface);border-radius:var(--sys-shape-corner-medium)}.opt-in-change-dialog{width:var(--sys-size-33);max-width:100%}header{display:flex;flex-direction:row;align-items:center;gap:var(--sys-size-8);margin-bottom:var(--sys-size-8);h1{margin:0;color:var(--sys-color-on-surface);font:var(--sys-typescale-headline5)}.header-icon-container{background:linear-gradient(135deg,var(--sys-color-gradient-primary),var(--sys-color-gradient-tertiary));border-radius:var(--sys-size-4);height:var(--sys-size-14);width:var(--sys-size-14);display:flex;align-items:center;justify-content:center;devtools-icon{width:var(--sys-size-9);height:var(--sys-size-9)}}}main{background-color:var(--sys-color-surface4);border-radius:var(--sys-shape-corner-medium-small);padding:var(--sys-size-8);display:flex;flex-direction:column;gap:var(--sys-size-6);margin-bottom:var(--sys-size-8);.item{display:flex;flex-direction:row;align-items:center;gap:var(--sys-size-8);devtools-icon{width:var(--sys-size-8);height:var(--sys-size-8);flex-shrink:0;color:var(--sys-color-on-surface-subtle)}.text{font:var(--sys-typescale-body4);color:var(--sys-color-on-surface)}}}footer{display:flex;flex-direction:row;align-items:center;justify-content:flex-end;.right-buttons{display:flex;gap:var(--sys-size-5)}}}
/*# sourceURL=${import.meta.resolve("././components/optInChangeDialog.css")} */`;var{html:Uo,render:No}=zo,W={title:"AI assistance just got better",integrationPoint:"AI assistance is now integrated with Application and Lighthouse panels, and pulls context from data sources simultaneously",widgetPoint:"Use widgets to verify results or jump to source data for select debugging cases",privacyDisclaimer:"Chat messages, data accessible for this site via DevTools panels and Web APIs, and items you select such as network requests, files, and performance traces are sent to Google and may be seen by human reviewers to improve this feature. This is an experimental AI feature and won\u2019t always get it right.",privacyDisclaimerEnterpriseNoLogging:"Chat messages, data accessible for this site via DevTools panels and Web APIs, and items you select such as network requests, files, and performance traces are sent to Google. The content submitted to and generated by this feature will not be used to improve Google\u2019s AI models. This is an experimental AI feature and won\u2019t always get it right.",manageSettings:"Manage in settings",gotIt:"Got it"},Fo=Et.i18n.registerUIStrings("panels/ai_assistance/components/OptInChangeDialog.ts",W),_=Et.i18n.getLocalizedString.bind(void 0,Fo),ri=(t,e,s)=>{let i=t.loggingEnabled?_(W.privacyDisclaimer):_(W.privacyDisclaimerEnterpriseNoLogging);No(Uo`
    <style>${ni}</style>
    <div class="opt-in-change-dialog" jslog=${ai.dialog("ai-v2-opt-in-change-dialog")}>
      <header>
        <div class="header-icon-container">
          <devtools-icon name="smart-assistant" role="presentation"></devtools-icon>
        </div>
        <h1 tabindex="-1">
          ${_(W.title)}
        </h1>
      </header>
      <main>
        <div class="item">
          <devtools-icon name="lightbulb-spark" role="presentation"></devtools-icon>
          <div class="text">${_(W.integrationPoint)}</div>
        </div>
        <div class="item">
          <devtools-icon name="flowsheet" role="presentation"></devtools-icon>
          <div class="text">${_(W.widgetPoint)}</div>
        </div>
        <div class="item">
          <devtools-icon name="google" role="presentation"></devtools-icon>
          <div class="text">${i}</div>
        </div>
      </main>
      <footer>
        <div class="right-buttons">
          <devtools-button
            @click=${t.onManageSettings}
            .jslogContext=${"ai-assistance-v2-opt-in.manage-settings"}
            .variant=${"outlined"}
            .accessibleLabel=${_(W.manageSettings)}
          >
            ${_(W.manageSettings)}
          </devtools-button>
          <devtools-button
            @click=${t.onGotIt}
            .jslogContext=${"ai-assistance-v2-opt-in.got-it"}
            .variant=${"primary"}
            .accessibleLabel=${_(W.gotIt)}
          >
            ${_(W.gotIt)}
          </devtools-button>
        </div>
      </footer>
    </div>
  `,s)},$e=class t extends st.Widget.VBox{#s;#t;#i;constructor(e,s=ri){super(),this.#t=e.onGotIt,this.#i=e.onManageSettings,this.#s=s,this.requestUpdate()}performUpdate(){let e=Rt.Runtime.hostConfig.aidaAvailability?.enterprisePolicyValue!==Rt.Runtime.GenAiEnterprisePolicyValue.ALLOW_WITHOUT_LOGGING,s={onGotIt:this.#t,onManageSettings:this.#i,loggingEnabled:e};this.#s(s,void 0,this.contentElement)}focusTitle(){this.contentElement.querySelector("h1")?.focus()}static show(e){let s=new st.Dialog.Dialog;s.setAriaLabel(_(W.title)),s.setOutsideClickCallback(o=>o.consume(!0)),s.setCloseOnEscape(!1),s.setSizeBehavior("MeasureContent"),s.setDimmed(!0);let i=new t({onGotIt:()=>{s.hide(),e.onGotIt()},onManageSettings:()=>{s.hide(),e.onManageSettings()}});i.show(s.contentElement),i.updateComplete.then(()=>{s.show(),i.focusTitle()})}};import*as ci from"./../../core/common/common.js";import*as ge from"./../../core/sdk/sdk.js";import*as di from"./../../models/trace/trace.js";import*as it from"./../../ui/lit/lit.js";import*as gi from"./../common/common.js";var{html:Dt}=it.StaticHtml,{until:Oo}=it.Directives,de=class extends Y{mainFrameId;lookupEvent;constructor(e="",s=()=>null){super(),this.mainFrameId=e,this.lookupEvent=s}templateForToken(e){if(e.type==="link"&&e.href.startsWith("#")){if(e.href.startsWith("#node-")){let n=Number(e.href.replace("#node-",""));return Dt`<span>${Oo(this.#s(n,e.text).then(a=>a||e.text),e.text)}</span>`}let s=this.lookupEvent(e.href.slice(1));if(!s)return Dt`${e.text}`;let i=e.text,o="";return di.Types.Events.isSyntheticNetworkRequest(s)?o=s.args.data.url:i+=` (${s.name})`,Dt`<a href="#" draggable=false .title=${o} @click=${n=>{n.stopPropagation(),ci.Revealer.reveal(new ge.TraceObject.RevealableEvent(s))}}>${i}</a>`}return super.templateForToken(e)}async#s(e,s){if(e===void 0)return;let o=ge.TargetManager.TargetManager.instance().primaryPageTarget()?.model(ge.DOMModel.DOMModel);if(!o)return;let a=(await o.pushNodesByBackendIdsToFrontend(new Set([e])))?.get(e);return!a||a.frameId()!==this.mainFrameId?void 0:gi.DOMLinkifier.Linkifier.instance().linkify(a,{textContent:s})}};var ui={};j(ui,{saveToDisk:()=>Ut});import*as Pt from"./../../core/platform/platform.js";import*as hi from"./../../core/text_utils/text_utils.js";import*as zt from"./../../models/workspace/workspace.js";async function Ut(t){let e=t.getConversationMarkdown(),s=new hi.ContentData.ContentData(e,!1,"text/markdown"),i=Pt.StringUtilities.toSnakeCase(t.title||""),o="devtools_",n=".md",a=63-o.length-n.length,l=(i?Pt.StringUtilities.truncateToCodeUnitLength(i,a):"")||"conversation",p=`${o}${l}${n}`;await zt.FileManager.FileManager.instance().save(p,s,!0),zt.FileManager.FileManager.instance().close(p)}var{html:se}=G,{widget:Nt}=u.Widget,Vo="https://crbug.com/364805393",Wo="https://developer.chrome.com/docs/devtools/ai-assistance",jo=700,Bo=400,A={newChat:"New chat",help:"Help",settings:"Settings",sendFeedback:"Send feedback",newChatCreated:"New chat created",chatDeleted:"Chat deleted",history:"History",deleteChat:"Delete local chat",clearChatHistory:"Clear local chats",noPastConversations:"No past conversations",followTheSteps:"Follow the steps above to ask a question",inputDisclaimerForEmptyState:"This is an experimental AI feature and won\u2019t always get it right.",responseCopiedToClipboard:"Response copied to clipboard"},C={answerLoading:"Answer loading",answerReady:"Answer ready",analyzingData:"Analyzing data",crossOriginError:"To talk about data from another origin, start a new chat",inputPlaceholderForStyling:"Ask a question about the selected element",inputPlaceholderForNetwork:"Ask a question about the selected network request",inputPlaceholderForFile:"Ask a question about the selected file",inputPlaceholderForPerformanceWithNoRecording:"Record a performance trace and select an item to ask a question",inputPlaceholderForStylingNoContext:"Select an element to ask a question",inputPlaceholderForNetworkNoContext:"Select a network request to ask a question",inputPlaceholderForFileNoContext:"Select a file to ask a question",inputPlaceholderForPerformanceTrace:"Ask a question about the selected performance trace",inputPlaceholderForPerformanceTraceNoContext:"Record or select a performance trace to ask a question",inputPlaceholderForNoContext:"Ask AI Assistance",inputPlaceholderForNoContextBranded:"Ask Gemini",inputPlaceholderForV2:"Ask a question (AIAgent2 enabled)",inputPlaceholderForAccessibility:"Ask a question about the selected Lighthouse report",inputPlaceholderForAccessibilityNoContext:"Generate a Lighthouse report to ask a question",inputDisclaimer:"Chat messages, data accessible for this site via DevTools panels and Web APIs, and items you select such as network requests, files, and performance traces are sent to Google and may be seen by human reviewers to improve this feature. This is an experimental AI feature and won\u2019t always get it right.",inputDisclaimerEnterpriseNoLogging:"Chat messages, data accessible for this site via DevTools panels and Web APIs, and items you select such as network requests, files, and performance traces are sent to Google. The content submitted to and generated by this feature will not be used to improve Google\u2019s AI models. This is an experimental AI feature and won\u2019t always get it right."},_o=rt.i18n.registerUIStrings("panels/ai_assistance/AiAssistancePanel.ts",A),L=rt.i18n.getLocalizedString.bind(void 0,_o),T=rt.i18n.lockedString;function ot(t){return t&&t.nodeType()===Node.ELEMENT_NODE?t:null}async function qo(t){let e=t?.selectedContext;if(e){let s=await e.getSuggestions();if(s)return s}if(!t?.type||t.isReadOnly)return[];switch(t.type){case"freestyler":return[{title:"What can you help me with?",jslogContext:"styling-default"},{title:"Why isn\u2019t this element visible?",jslogContext:"styling-default"},{title:"How do I center this element?",jslogContext:"styling-default"}];case"drjones-file":return[{title:"What does this script do?",jslogContext:"file-default"},{title:"Is the script optimized for performance?",jslogContext:"file-default"},{title:"Does the script handle user input safely?",jslogContext:"file-default"}];case"accessibility":return[{title:"How can I fix accessibility issues on my page?",jslogContext:"accessibility-default"},{title:"What accessibility issues exist on my page?",jslogContext:"accessibility-default"}];case"drjones-network-request":return[{title:"Why is this network request taking so long?",jslogContext:"network-default"},{title:"Are there any security headers present?",jslogContext:"network-default"},{title:"Why is the request failing?",jslogContext:"network-default"}];case"drjones-performance-full":return[{title:"What performance issues exist with my page?",jslogContext:"performance-default"}];case"none":return[{title:"What can you help me with?",jslogContext:"empty"},{title:"What performance issues exist on the page?",jslogContext:"empty"},{title:"What are the slowest network requests on this page?",jslogContext:"empty"}];case"storage":return[{title:"How is localStorage used on this page?",jslogContext:"storage-default"},{title:"How is sessionStorage used on this page?",jslogContext:"storage-default"},{title:"What cookies are stored for this page?",jslogContext:"storage-default"}];default:bi.assertNever(t.type,"Unknown conversation type")}}function Ho(t){let e={},s=y.TargetManager.TargetManager.instance().primaryPageTarget(),i=s?.model(y.DOMModel.DOMModel),o=s?.model(y.ResourceTreeModel.ResourceTreeModel),n=t?.selectedContext;if(n instanceof g.PerformanceTraceContext.PerformanceTraceContext){let a=n.getItem();e.mainFrameId=a.parsedTrace.data.Meta.mainFrameId,e.lookupTraceEvent=a.lookupEvent.bind(a)}else i&&(e.mainDocumentURL=i.existingDocument()?.documentURL),o&&(e.mainFrameId=o.mainFrame?.id);return new Ne(e)}function Ko(t){if(t?.type==="drjones-performance-full"&&t.isReadOnly)return new de;if(R.Runtime.hostConfig.devToolsAiV2Architecture?.enabled&&t&&!t.isReadOnly)return Ho(t);let e=t?.selectedContext;if(e instanceof g.PerformanceTraceContext.PerformanceTraceContext){let s=e.getItem();return new de(s.parsedTrace.data.Meta.mainFrameId,s.lookupEvent.bind(s))}if(t?.type==="drjones-performance-full")return new de;if(t?.type==="accessibility"){let i=y.TargetManager.TargetManager.instance().primaryPageTarget()?.model(y.DOMModel.DOMModel)?.existingDocument()?.documentURL;return new ze(i)}return new Y}function Go(t){return se`
    <div class="toolbar-container" role="toolbar" jslog=${Ee.toolbar()}>
      <devtools-toolbar class="freestyler-left-toolbar" role="presentation">
      ${t.showChatActions?se`<devtools-button
          title=${L(A.newChat)}
          aria-label=${L(A.newChat)}
          .iconName=${"plus"}
          .jslogContext=${"freestyler.new-chat"}
          .variant=${"toolbar"}
          @click=${t.onNewChatClick}></devtools-button>
        <div class="toolbar-divider"></div>
        <devtools-menu-button
          title=${L(A.history)}
          aria-label=${L(A.history)}
          .iconName=${"history"}
          .jslogContext=${"freestyler.history"}
          .populateMenuCall=${t.populateHistoryMenu}
        ></devtools-menu-button>`:G.nothing}
        ${t.showActiveConversationActions?se`
          <devtools-button
              title=${L(A.deleteChat)}
              aria-label=${L(A.deleteChat)}
              .iconName=${"bin"}
              .jslogContext=${"freestyler.delete"}
              .variant=${"toolbar"}
              @click=${t.onDeleteClick}>
          </devtools-button>`:G.nothing}
      </devtools-toolbar>
      <devtools-toolbar class="freestyler-right-toolbar" role="presentation">
        <devtools-link
          class="toolbar-feedback-link"
          title=${L(A.sendFeedback)}
          href=${Vo}
          jslogcontext=${"freestyler.send-feedback"}
        >${L(A.sendFeedback)}</devtools-link>
        <div class="toolbar-divider"></div>
        <devtools-button
          title=${L(A.help)}
          aria-label=${L(A.help)}
          .iconName=${"help"}
          .jslogContext=${"freestyler.help"}
          .variant=${"toolbar"}
          @click=${t.onHelpClick}></devtools-button>
        <devtools-button
          title=${L(A.settings)}
          aria-label=${L(A.settings)}
          .iconName=${"gear"}
          .jslogContext=${"freestyler.settings"}
          .variant=${"toolbar"}
          @click=${t.onSettingsClick}></devtools-button>
      </devtools-toolbar>
    </div>
  `}function mi(t,e,s){function i(){switch(t.state){case"chat-view":return se`<devtools-ai-chat-view
          .props=${t.props}
          ${G.Directives.ref(a=>{!a||!(a instanceof Te)||(e.chatView=a)})}
        ></devtools-ai-chat-view>`;case"explore-view":return se`<devtools-widget class="fill-panel" ${Nt(Me)}>
                    </devtools-widget>`;case"disabled-view":return se`<devtools-widget class="fill-panel" ${Nt(Le,t.props)}>
                    </devtools-widget>`}}let o=t.state==="chat-view"&&t.props.walkthrough.isExpanded,n=!1;if(t.state==="chat-view"){let a=t.props.messages.at(-1);a&&t.props.walkthrough.activeSidebarMessage?.id===a.id&&(n=!0)}G.render(se`
    ${Go(t)}
    <div class="ai-assistance-view-container">
      <devtools-split-view
        name="ai-assistance-split-view-state"
        direction="column"
        sidebar-position="second"
        sidebar-visibility=${o&&!t.props.walkthrough.isInlined?"visible":"hidden"}
        sidebar-initial-size=${Bo}
      >
        <div slot="main" class="main-view">
          ${i()}
        </div>
        ${o?se`
          <devtools-widget slot="sidebar" ${Nt(ie,{message:t.props.walkthrough.activeSidebarMessage,isLoading:t.props.isLoading&&n,markdownRenderer:t.props.markdownRenderer,onToggle:t.props.walkthrough.onToggle})}></devtools-widget>`:G.nothing}
      </devtools-split-view>
    </div>
  `,s)}function pi(t){return t?new g.DOMNodeContext.DOMNodeContext(t):null}function Yo(t){return t?new g.FileContext.FileContext(t):null}function vi(t){return t?new g.AccessibilityContext.AccessibilityContext(t.report):null}function Jo(t){if(!t)return null;let e=me.NetworkPanel.NetworkPanel.instance().networkLogView.timeCalculator();return new g.RequestContext.RequestContext(t,e)}function Xo(t){return t?new g.PerformanceTraceContext.PerformanceTraceContext(t):null}function fi(t){return t?new g.StorageContext.StorageContext(t):null}var Ft,at=class t extends u.Panel.Panel{view;static panelName="freestyler";#s;#t;#i;#o={};#a=en();#r;#c=new g.ChangeManager.ChangeManager;#d=new U.Mutex.Mutex;#e;#g=null;#h=null;#l=null;#u=null;#m=null;#p=null;#b=[];#y=!1;#f;#w=null;#C=new AbortController;#n={isInlined:!1,isExpanded:!1,activeSidebarMessage:null,inlineExpandedMessages:[]};#S="";constructor(e=mi,{aidaClient:s,aidaAvailability:i}){super(t.panelName),this.view=e,this.registerRequiredCSS(Vt),this.#r=this.#X(),this.#t=s,this.#f=i,u.ActionRegistry.ActionRegistry.instance().hasAction("elements.toggle-element-search")&&(this.#s=u.ActionRegistry.ActionRegistry.instance().getAction("elements.toggle-element-search"))}#K(){return{isLoading:this.#y,showChatActions:this.#te(),showActiveConversationActions:!!(this.#e&&!this.#e.isEmpty),onNewChatClick:this.#R.bind(this),populateHistoryMenu:this.#ce.bind(this),onDeleteClick:this.#de.bind(this),onExportConversationClick:this.#_.bind(this),onHelpClick:()=>{xi.openInNewTab(Wo)},onSettingsClick:()=>{u.ViewManager.ViewManager.instance().showView("chrome-ai")}}}async#G(){let e=R.Runtime.hostConfig.aidaAvailability?.blockedByAge===!0;if(this.#f!=="available"||!this.#r?.getIfNotDisabled()||e)return{state:"disabled-view",props:{aidaAvailability:this.#f}};if(this.#e){let s=await qo(this.#e),i=Ko(this.#e),o=null;return he()&&this.#k(this.#x())&&(o=this.#re.bind(this)),{state:"chat-view",props:{blockedByCrossOrigin:this.#e.isBlockedByOrigin,isLoading:this.#y,messages:this.#b,context:this.#e.selectedContext??this.#k(this.#x()),isContextSelected:!!this.#e.selectedContext,conversationType:this.#e.type,isReadOnly:this.#e.isReadOnly??!1,inspectElementToggled:this.#s?.toggled()??!1,canShowFeedbackForm:this.#a,multimodalInputEnabled:Ot()&&this.#e.type==="freestyler",isTextInputDisabled:this.#ee(),emptyStateSuggestions:s,inputPlaceholder:this.#se(),disclaimerText:this.#ie(),textInputValue:this.#S,onTextChange:n=>{this.#S=n},onExportConversation:this.#_.bind(this),uploadImageInputEnabled:Zo()&&this.#e.type==="freestyler",markdownRenderer:i,conversationMarkdown:this.#e.getConversationMarkdown(),generateConversationSummary:async n=>(this.#i||(this.#i=new g.ConversationSummary.ConversationSummary({aidaClient:this.#t,serverSideLoggingEnabled:this.#a})),await this.#i.summarizeConversation(n)),onTextSubmit:async(n,a,d)=>{let l=()=>{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceQuerySubmitted),this.#q(n,a,d)},p=U.Settings.Settings.instance().resolve(g.AiUtils.aiAssistanceV2OptInChangeDialogSeenSettingDescriptor);if(!p.get()){$e.show({onGotIt:()=>{p.set(!0),l()},onManageSettings:()=>{p.set(!0),this.#o.chatView?.setInputValue(n),u.ViewManager.ViewManager.instance().showView("chrome-ai")}});return}l()},onInspectElementClick:this.#Z.bind(this),onFeedbackSubmit:this.#oe.bind(this),onCancelClick:this.#E.bind(this),onContextClick:this.#ne.bind(this),onNewConversation:this.#R.bind(this),onCopyResponseClick:this.#Q.bind(this),onContextRemoved:he()?this.#ae.bind(this):null,onContextAdd:o,walkthrough:{onToggle:this.#J.bind(this),onOpen:this.#I.bind(this),isExpanded:this.#n.isExpanded,isInlined:this.#n.isInlined,activeSidebarMessage:this.#n.activeSidebarMessage,inlineExpandedMessages:this.#n.inlineExpandedMessages}}}}return{state:"explore-view"}}onResize(){super.onResize(),this.#Y()}#Y(){let e=this.contentElement.offsetWidth<jo;if(e!==this.#n.isInlined){if(this.#n.isInlined=e,!this.#n.isExpanded){this.#n.activeSidebarMessage=null,this.#n.inlineExpandedMessages=[],this.requestUpdate();return}e?this.#n.inlineExpandedMessages=this.#n.activeSidebarMessage?[this.#n.activeSidebarMessage]:[]:this.#n.activeSidebarMessage=this.#n.inlineExpandedMessages.at(-1)??null,this.requestUpdate()}}#I(e){this.#n.inlineExpandedMessages.some(s=>s.id===e.id)||this.#n.inlineExpandedMessages.push(e),this.#n.activeSidebarMessage=e,this.#n.isExpanded=!0,this.requestUpdate()}#J(e,s){if(e){this.#I(s);return}this.#n.inlineExpandedMessages=this.#n.inlineExpandedMessages.filter(i=>i.id!==s.id),this.#n.isInlined?(this.#n.isExpanded=this.#n.inlineExpandedMessages.length>0,this.#n.activeSidebarMessage?.id===s.id&&(this.#n.activeSidebarMessage=this.#n.inlineExpandedMessages.at(-1)??null)):(this.#n.isExpanded=!1,this.#n.activeSidebarMessage=null),this.requestUpdate()}#X(){return new g.AiSetting.AiSetting(g.AiUtils.aiAssistanceEnabledSettingDescriptor,f.AidaClient.HostConfigTracker.instance(),U.Settings.Settings.instance())}static async instance(e={forceNew:null}){let{forceNew:s}=e;if(!Ft||s){let i=new f.AidaClient.AidaClient,o=f.AidaClient.HostConfigTracker.instance().aidaAvailability??await f.AidaClient.AidaClient.checkAccessPreconditions();Ft=new t(mi,{aidaClient:i,aidaAvailability:o})}return Ft}#A(){let e=u.Context.Context.instance().flavor(ue.TimelinePanel.TimelinePanel);e!==this.#w&&(this.#w?.removeEventListener("IsViewingTrace",this.requestUpdate,this),this.#w=e,this.#w&&this.#w.addEventListener("IsViewingTrace",this.requestUpdate,this))}async#L(){return await ue.TimelinePanel.TimelinePanel.executeRecordAndReload()}async#M(e){return await Re.LighthousePanel.LighthousePanel.executeLighthouseRecording({isAIControlled:!0,...e})}#x(){let{hostConfig:e}=R.Runtime,s=u.ViewManager.ViewManager.instance(),i=s.isViewVisible("elements"),o=s.isViewVisible("network"),n=s.isViewVisible("sources"),a=s.isViewVisible("timeline"),d=s.isViewVisible("lighthouse"),l=s.isViewVisible("resources"),p;return i&&e.devToolsFreestyler?.enabled?p="freestyler":o&&e.devToolsAiAssistanceNetworkAgent?.enabled?p="drjones-network-request":n&&e.devToolsAiAssistanceFileAgent?.enabled?p="drjones-file":a&&e.devToolsAiAssistancePerformanceAgent?.enabled?p="drjones-performance-full":d&&e.devToolsAiAssistanceAccessibilityAgent?.enabled?p="accessibility":l&&e.devToolsAiAssistanceStorageAgent?.enabled&&(p="storage"),he()&&!p?"none":p}#$(){if(this.#y){this.requestUpdate();return}if(this.#e&&!this.#e.isEmpty){this.requestUpdate();return}let e=this.#x();if(this.#e?.type===e){this.requestUpdate();return}let s=e?new g.AiConversation.AiConversation({type:e,data:[],isReadOnly:!1,aidaClient:this.#t,changeManager:this.#c,performanceRecordAndReload:this.#L.bind(this),onInspectElement:this.#D.bind(this),networkTimeCalculator:me.NetworkPanel.NetworkPanel.instance().networkLogView.timeCalculator(),lighthouseRecording:this.#M.bind(this)}):void 0;this.#v(s)}#v(e){if(this.#e!==e){if(this.#E(),this.#b=[],this.#y=!1,this.#e?.archiveConversation(),!e){let s=this.#x();s&&(e=new g.AiConversation.AiConversation({type:s,data:[],isReadOnly:!1,aidaClient:this.#t,changeManager:this.#c,performanceRecordAndReload:this.#L.bind(this),onInspectElement:this.#D.bind(this),networkTimeCalculator:me.NetworkPanel.NetworkPanel.instance().networkLogView.timeCalculator(),lighthouseRecording:this.#M.bind(this)}))}this.#e=e}if(this.#e)if(this.#e.isEmpty&&he()){let s=this.#k(this.#x());this.#e.setContext(s)}else{let s=this.#k(this.#e.type);(s||!he())&&this.#e.setContext(s)}this.requestUpdate()}wasShown(){super.wasShown(),this.#o.chatView?.restoreScrollPosition(),this.#o.chatView?.focusTextInput(),this.#h=pi(ot(u.Context.Context.instance().flavor(y.DOMModel.DOMNode))),this.#u=Jo(u.Context.Context.instance().flavor(y.NetworkRequest.NetworkRequest)),this.#l=Xo(u.Context.Context.instance().flavor(g.AIContext.AgentFocus)),this.#g=Yo(u.Context.Context.instance().flavor(nt.UISourceCode.UISourceCode)),this.#m=vi(u.Context.Context.instance().flavor(Re.LighthousePanel.ActiveLighthouseReport)),this.#p=fi(u.Context.Context.instance().flavor(g.StorageItem.StorageItem)),this.#v(this.#e),g.AiHistoryStorage.AiHistoryStorage.instance().addEventListener("AiHistoryDeleted",this.#j,this),this.#r.addEventListener("Changed",this.requestUpdate,this),f.AidaClient.HostConfigTracker.instance().addEventListener("aidaAvailabilityChanged",this.#z);let e=f.AidaClient.HostConfigTracker.instance().aidaAvailability;e!==void 0&&this.#P(e),this.#s?.addEventListener("Toggled",this.requestUpdate,this),u.Context.Context.instance().addFlavorChangeListener(y.DOMModel.DOMNode,this.#U),u.Context.Context.instance().addFlavorChangeListener(y.NetworkRequest.NetworkRequest,this.#F),u.Context.Context.instance().addFlavorChangeListener(g.AIContext.AgentFocus,this.#O),u.Context.Context.instance().addFlavorChangeListener(g.StorageItem.StorageItem,this.#N),u.Context.Context.instance().addFlavorChangeListener(nt.UISourceCode.UISourceCode,this.#V),u.Context.Context.instance().addFlavorChangeListener(Re.LighthousePanel.ActiveLighthouseReport,this.#W),u.ViewManager.ViewManager.instance().addEventListener("ViewVisibilityChanged",this.#$,this),y.TargetManager.TargetManager.instance().addModelListener(y.DOMModel.DOMModel,y.DOMModel.Events.AttrModified,this.#T,this),y.TargetManager.TargetManager.instance().addModelListener(y.DOMModel.DOMModel,y.DOMModel.Events.AttrRemoved,this.#T,this),u.Context.Context.instance().addFlavorChangeListener(ue.TimelinePanel.TimelinePanel,this.#A,this),this.#A(),this.#$(),f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistancePanelOpened)}willHide(){super.willHide(),g.AiHistoryStorage.AiHistoryStorage.instance().removeEventListener("AiHistoryDeleted",this.#j,this),this.#r.removeEventListener("Changed",this.requestUpdate,this),f.AidaClient.HostConfigTracker.instance().removeEventListener("aidaAvailabilityChanged",this.#z),this.#s?.removeEventListener("Toggled",this.requestUpdate,this),u.Context.Context.instance().removeFlavorChangeListener(y.DOMModel.DOMNode,this.#U),u.Context.Context.instance().removeFlavorChangeListener(y.NetworkRequest.NetworkRequest,this.#F),u.Context.Context.instance().removeFlavorChangeListener(g.AIContext.AgentFocus,this.#O),u.Context.Context.instance().removeFlavorChangeListener(g.StorageItem.StorageItem,this.#N),u.Context.Context.instance().removeFlavorChangeListener(nt.UISourceCode.UISourceCode,this.#V),u.Context.Context.instance().removeFlavorChangeListener(Re.LighthousePanel.ActiveLighthouseReport,this.#W),u.ViewManager.ViewManager.instance().removeEventListener("ViewVisibilityChanged",this.#$,this),u.Context.Context.instance().removeFlavorChangeListener(ue.TimelinePanel.TimelinePanel,this.#A,this),y.TargetManager.TargetManager.instance().removeModelListener(y.DOMModel.DOMModel,y.DOMModel.Events.AttrModified,this.#T,this),y.TargetManager.TargetManager.instance().removeModelListener(y.DOMModel.DOMModel,y.DOMModel.Events.AttrRemoved,this.#T,this),this.#w&&(this.#w.removeEventListener("IsViewingTrace",this.requestUpdate,this),this.#w=null)}#P(e){e!==this.#f&&(this.#f=e,this.requestUpdate())}#z=e=>{this.#P(e.data)};#U=e=>{this.#h?.getItem()!==e.data&&(this.#h=pi(ot(e.data)),this.#v(this.#e))};#N=e=>{this.#p?.getItem()!==e.data&&(this.#p=fi(e.data),this.#v(this.#e))};#T=e=>{this.#h?.getItem()===e.data.node&&(e.data.name==="class"||e.data.name==="id")&&this.requestUpdate()};#F=e=>{if(this.#u?.getItem()!==e.data){if(e.data){let s=me.NetworkPanel.NetworkPanel.instance().networkLogView.timeCalculator();this.#u=new g.RequestContext.RequestContext(e.data,s)}else this.#u=null;this.#v(this.#e)}};#O=e=>{this.#l?.getItem()!==e.data&&(this.#l=e.data?new g.PerformanceTraceContext.PerformanceTraceContext(e.data):null,this.#v(this.#e))};#V=e=>{let s=e.data;!s||this.#g?.getItem()===s||(this.#g=new g.FileContext.FileContext(e.data),this.#v(this.#e))};#W=e=>{let s=e.data;this.#m?.getItem()!==s?.report&&(this.#m=vi(s),this.#v(this.#e))};async performUpdate(){let e={...this.#K(),...await this.#G()};this.view(e,this.#o,this.contentElement)}#Q(e){let s=Qo(e);s&&(f.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(s),wi.Snackbar.Snackbar.show({message:L(A.responseCopiedToClipboard)}))}#Z(){u.Context.Context.instance().setFlavor(U.ReturnToPanel.ReturnToPanelFlavor,new U.ReturnToPanel.ReturnToPanelFlavor(this.panelName)),this.#s?.execute()}#ee(){return!!(this.#e&&this.#e.isBlockedByOrigin||!this.#e||!this.#e.selectedContext&&!he())}#te(){let e=this.#r?.getIfNotDisabled(),s=R.Runtime.hostConfig.aidaAvailability?.blockedByAge===!0;return!(!e||s||this.#f==="no-account-email"||this.#f==="sync-is-paused")}#se(){if(!this.#e)return L(A.followTheSteps);if(this.#e&&this.#e.isBlockedByOrigin)return T(C.crossOriginError);if(R.Runtime.hostConfig.devToolsAiV2Architecture?.enabled)return T(C.inputPlaceholderForV2);switch(this.#e.type){case"freestyler":return this.#e.selectedContext?T(C.inputPlaceholderForStyling):T(C.inputPlaceholderForStylingNoContext);case"drjones-file":return this.#e.selectedContext?T(C.inputPlaceholderForFile):T(C.inputPlaceholderForFileNoContext);case"drjones-network-request":return this.#e.selectedContext?T(C.inputPlaceholderForNetwork):T(C.inputPlaceholderForNetworkNoContext);case"drjones-performance-full":return u.Context.Context.instance().flavor(ue.TimelinePanel.TimelinePanel)?.hasActiveTrace()?this.#e.selectedContext?T(C.inputPlaceholderForPerformanceTrace):T(C.inputPlaceholderForPerformanceTraceNoContext):T(C.inputPlaceholderForPerformanceWithNoRecording);case"accessibility":return this.#e.selectedContext?T(C.inputPlaceholderForAccessibility):T(C.inputPlaceholderForAccessibilityNoContext);case"storage":return T(C.inputPlaceholderForNoContext);case"none":return g.AiUtils.isGeminiBranding()?T(C.inputPlaceholderForNoContextBranded):T(C.inputPlaceholderForNoContext)}}#ie(){return!this.#e||this.#e.isReadOnly?L(A.inputDisclaimerForEmptyState):R.Runtime.hostConfig.aidaAvailability?.enterprisePolicyValue!==R.Runtime.GenAiEnterprisePolicyValue.ALLOW_WITHOUT_LOGGING?T(C.inputDisclaimer):T(C.inputDisclaimerEnterpriseNoLogging)}#oe(e,s,i){this.#t.registerClientEvent({corresponding_aida_rpc_global_id:e,disable_user_content_logging:!this.#a,do_conversation_client_event:{user_feedback:{sentiment:s,user_input:{comment:i}}}})}#ne(){if(!this.#e)return;let e=this.#e.selectedContext;if(e instanceof g.RequestContext.RequestContext){let s=ki.UIRequestLocation.UIRequestLocation.tab(e.getItem(),"headers-component");return U.Revealer.reveal(s)}if(e instanceof g.FileContext.FileContext)return U.Revealer.reveal(e.getItem().uiLocation(0,0));if(e instanceof g.PerformanceTraceContext.PerformanceTraceContext){let s=e.getItem();if(s.callTree){let i=s.callTree.selectedNode?.event??s.callTree.rootNode.event,o=new y.TraceObject.RevealableEvent(i);return U.Revealer.reveal(o)}if(s.insight)return U.Revealer.reveal(s.insight)}}#ae(){this.#e?.setContext(null),this.requestUpdate()}#re(){this.#e?.setContext(this.#k(this.#x())),this.requestUpdate()}#le(){let e=!!R.Runtime.hostConfig.aidaAvailability?.enabled,s=!!R.Runtime.hostConfig.aidaAvailability?.blockedByAge,i=this.#f==="available",o=!!this.#r?.getIfNotDisabled();return e&&i&&o&&!s}async handleAction(e,s){if(this.#y&&!s?.prompt){this.#o.chatView?.focusTextInput();return}let i;switch(e){case"freestyler.elements-floating-button":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromElementsPanelFloatingButton),i="freestyler";break}case"freestyler.element-panel-context":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromElementsPanel),i="freestyler";break}case"drjones.network-floating-button":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromNetworkPanelFloatingButton),i="drjones-network-request";break}case"drjones.network-panel-context":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromNetworkPanel),i="drjones-network-request";break}case"drjones.performance-panel-context":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromPerformancePanelCallTree),i="drjones-performance-full";break}case"drjones.sources-floating-button":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromSourcesPanelFloatingButton),i="drjones-file";break}case"drjones.sources-panel-context":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromSourcesPanel),i="drjones-file";break}case"ai-assistance.storage-floating-button":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromApplicationPanelFloatingButton),i="storage";break}case"ai-assistance.application-panel-context":{f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceOpenedFromApplicationPanel),i="storage";break}}if(!i)return;let o=this.#e;(!this.#e||this.#e.type!==i||this.#e.isEmpty)&&(o=new g.AiConversation.AiConversation({type:i,data:[],isReadOnly:!1,aidaClient:this.#t,changeManager:this.#c,performanceRecordAndReload:this.#L.bind(this),onInspectElement:this.#D.bind(this),networkTimeCalculator:me.NetworkPanel.NetworkPanel.instance().networkLogView.timeCalculator(),lighthouseRecording:this.#M.bind(this)})),this.#v(o);let n=s?.prompt;if(n&&typeof n=="string"){if(!this.#le())return;f.userMetrics.actionTaken(f.UserMetrics.Action.AiAssistanceQuerySubmitted),this.#e&&this.#e.isBlockedByOrigin&&this.#R(),await this.#q(n)}else this.#o.chatView?.focusTextInput()}#ce(e){let s=g.AiHistoryStorage.AiHistoryStorage.instance().getHistory(),i=this.#e?.id;for(let n of[...s].reverse()){if(n.history.length===0)continue;let d=g.AiConversation.AiConversation.titleForSerialized(n);d&&e.defaultSection().appendCheckboxItem(d,()=>{let l=g.AiConversation.AiConversation.fromSerializedConversation(n);this.#ge(l)},{checked:i===n.id,jslogContext:"freestyler.history-item"})}let o=e.defaultSection().items.length===0;o&&e.defaultSection().appendItem(L(A.noPastConversations),()=>{},{disabled:!0}),e.footerSection().appendItem(L(A.clearChatHistory),()=>{g.AiHistoryStorage.AiHistoryStorage.instance().deleteAll()},{disabled:o})}#j(){this.#v()}#B(){this.#n.isExpanded=!1,this.#n.activeSidebarMessage=null,this.#n.inlineExpandedMessages=[]}#de(){this.#e&&(this.#B(),g.AiHistoryStorage.AiHistoryStorage.instance().deleteHistoryEntry(this.#e.id),this.#v(),u.ARIAUtils.LiveAnnouncer.alert(L(A.chatDeleted)))}async#_(){if(this.#e)return await Ut(this.#e)}async#ge(e){this.#e?.id!==e.id&&(this.#v(e),await this.#H(e.history))}#R(){this.#S="",this.#v(),this.#B(),u.ARIAUtils.LiveAnnouncer.alert(L(A.newChatCreated))}#E(){this.#C.abort(),this.#C=new AbortController}#k(e){switch(e){case"freestyler":return this.#h;case"drjones-file":return this.#g;case"drjones-network-request":return this.#u;case"drjones-performance-full":return this.#l;case"accessibility":return this.#m;case"storage":return this.#p;case"none":case void 0:return null}}#he=e=>{e instanceof g.FileContext.FileContext?this.#g=e:e instanceof g.DOMNodeContext.DOMNodeContext?this.#h=e:e instanceof g.RequestContext.RequestContext?this.#u=e:e instanceof g.PerformanceTraceContext.PerformanceTraceContext?this.#l=e:e instanceof g.AccessibilityContext.AccessibilityContext?this.#m=e:e instanceof g.StorageContext.StorageContext&&(this.#p=e),Ee.logFunctionCall(`context-change-${this.#e?.type}`),this.requestUpdate()};async#D(){if(!this.#s)return null;let e=new Promise(s=>{let i=a=>{a.data&&(s(ot(a.data)),n())},o=a=>{a.data||window.setTimeout(()=>{s(ot(u.Context.Context.instance().flavor(y.DOMModel.DOMNode))),n()},50)},n=()=>{u.Context.Context.instance().removeFlavorChangeListener(y.DOMModel.DOMNode,i),this.#s?.removeEventListener("Toggled",o)};u.Context.Context.instance().addFlavorChangeListener(y.DOMModel.DOMNode,i),this.#s?.addEventListener("Toggled",o),this.#C.signal.addEventListener("abort",()=>{s(null),n()},{once:!0})});this.#s.execute();try{return await e}finally{this.#s.toggled()&&this.#s.execute()}}async#q(e,s,i){if(!this.#e)return;this.#E();let o=this.#C.signal;this.#e.isEmpty&&lt.UserBadges.instance().recordAction(lt.BadgeAction.STARTED_AI_CONVERSATION);let n;Ot()&&s&&i&&(n={input:s,id:crypto.randomUUID(),type:i}),Ee.logFunctionCall(`start-conversation-${this.#e.type}`,"ui"),await this.#H(this.#e.run(e,{signal:o,multimodalInput:n}))}async#H(e){let s=await this.#d.acquire();try{let n=function(){let l=i.parts.at(-1);l?.type==="step"&&l.step===o||i.parts.push({type:"step",step:o})},i={entity:"model",parts:[],id:crypto.randomUUID()},o={state:{type:"in_progress"}};this.#y=!0;let a=!1,d=!1;for await(let l of e){switch(l.type){case"user-query":{this.#b.push({entity:"user",text:l.query,imageInput:l.imageInput,id:crypto.randomUUID()}),i={entity:"model",parts:[],id:crypto.randomUUID()},this.#b.push(i),this.#n.isExpanded&&!this.#n.isInlined&&this.#I(i);break}case"querying":{o={state:{type:"in_progress"}},i.parts.length||n();break}case"context":{o.title=T(C.analyzingData),o.contextDetails=l.details,o.widgets=l.widgets,o.state={type:"completed"},n();break}case"title":{o.title=l.title,n();break}case"thought":{o.state={type:"completed"},o.thought=l.thought,n();break}case"suggestions":{let p=i.parts.at(-1);p?.type==="answer"?p.suggestions=l.suggestions:i.parts.push({type:"answer",text:"",suggestions:l.suggestions});break}case"side-effect":{o.code??=l.code,o.state={type:"needs_approval",sideEffectDialog:{description:l.description,onAnswer:p=>{l.confirm(p),o.state={type:"completed"},this.requestUpdate()}}},n();break}case"action":{o.state=l.canceled?{type:"canceled"}:{type:"completed"},o.code??=l.code,o.output??=l.output,o.widgets??=l.widgets,n();break}case"answer":{i.rpcId=l.rpcId;let p=i.parts.at(-1);if(p?.type==="answer")p.text=l.text,l.suggestions&&(p.suggestions=l.suggestions);else{let k={type:"answer",text:l.text};l.suggestions&&(k.suggestions=l.suggestions),i.parts.push(k)}if(l.widgets&&i.parts.push({type:"widget",widgets:l.widgets}),i.parts.length>1){let k=i.parts[0];k.type==="step"&&k.step.state.type==="in_progress"&&!k.step.thought&&!k.step.code&&!k.step.contextDetails&&i.parts.shift()}o.state={type:"completed"};break}case"error":{i.error=l.error;let p=i.parts.at(-1);if(p?.type==="step"){let k=p.step;l.error==="abort"?k.state={type:"canceled"}:k.state.type==="in_progress"&&i.parts.pop()}l.error==="block"&&i.parts.at(-1)?.type==="answer"&&i.parts.pop();break}case"context-change":{this.#he(l.context),o.state={type:"completed"},o.widgets=l.widgets,n(),o={state:{type:"in_progress"}};break}}if(!this.#e?.isReadOnly)switch(this.requestUpdate(),(l.type==="context"||l.type==="side-effect")&&this.#o.chatView?.scrollToBottom(),l.type){case"context":u.ARIAUtils.LiveAnnouncer.status(T(C.analyzingData));break;case"answer":!l.complete&&!a?(a=!0,u.ARIAUtils.LiveAnnouncer.status(T(C.answerLoading))):l.complete&&!d&&(d=!0,u.ARIAUtils.LiveAnnouncer.status(T(C.answerReady)))}}this.#y=!1,this.requestUpdate()}finally{s()}}};function Qo(t){let e=["## AI"];for(let s of t.parts)if(s.type==="answer")e.push(`### Answer

${s.text}`);else if(s.type==="step"){let i=s.step;i.title&&e.push(`### ${i.title}`),i.contextDetails&&e.push(g.AiConversation.generateContextDetailsMarkdown(i.contextDetails)),i.thought&&e.push(i.thought),i.code&&e.push(`**Code executed:**
\`\`\`
${i.code.trim()}
\`\`\``),i.output&&e.push(`**Data returned:**
\`\`\`
${i.output}
\`\`\``)}return e.join(`

`)}var yi=class{handleAction(e,s,i){switch(s){case"freestyler.elements-floating-button":case"freestyler.element-panel-context":case"freestyler.main-menu":case"drjones.network-floating-button":case"drjones.network-panel-context":case"drjones.performance-panel-context":case"drjones.sources-floating-button":case"drjones.sources-panel-context":case"ai-assistance.storage-floating-button":case"ai-assistance.application-panel-context":return(async()=>{let o=u.ViewManager.ViewManager.instance().view(at.panelName);if(!o)return;await u.ViewManager.ViewManager.instance().showView(at.panelName);let n=u.InspectorView.InspectorView.instance().totalSize()/4;u.InspectorView.InspectorView.instance().drawerSize()<n&&u.InspectorView.InspectorView.instance().setDrawerSize(n),(await o.widget()).handleAction(s,i)})(),!0}return!1}};function Zo(){return Ot()&&!!R.Runtime.hostConfig.devToolsFreestyler?.multimodalUploadInput}function Ot(){return!!R.Runtime.hostConfig.devToolsFreestyler?.multimodal}function he(){return!!R.Runtime.hostConfig.devToolsAiAssistanceContextSelectionAgent?.enabled}function en(){return!R.Runtime.hostConfig.aidaAvailability?.disallowLogging}export{Ne as AIv2MarkdownRenderer,ze as AccessibilityAgentMarkdownRenderer,yi as ActionDelegate,at as AiAssistancePanel,ns as ChatInput,Es as ChatMessage,Te as ChatView,Xs as DisabledWidget,oi as ExploreWidget,ui as ExportConversation,Vs as ExportForAgentsDialog,pt as ImageResize,Y as MarkdownRendererWithCodeBlock,li as OptInChangeDialog,as as WalkthroughUtils,ms as WalkthroughView,Qo as getResponseMarkdown};
//# sourceMappingURL=ai_assistance.js.map
