var N=Object.defineProperty;var u=(i,e)=>{for(var t in e)N(i,t,{get:e[t],enumerable:!0})};var E={};u(E,{CodeBlock:()=>w,languageFromToken:()=>z});import"./../../kit/kit.js";import*as x from"./../../../core/i18n/i18n.js";import*as s from"./../../../third_party/codemirror.next/codemirror.next.js";import"./../buttons/buttons.js";import*as T from"./../text_editor/text_editor.js";import*as S from"./../../legacy/legacy.js";import*as n from"./../../lit/lit.js";import*as v from"./../../visual_logging/visual_logging.js";var L=`*{margin:0;padding:0;box-sizing:border-box}:host{display:block;--code-block-max-code-height:none;--code-block-background-color:var(--sys-color-surface2)}.codeblock{box-sizing:border-box;color:var(--sys-color-on-surface)}.codeblock .editor-wrapper{color:var(--sys-color-on-surface);background:var(--code-block-background-color);padding:10px 5px 0;border-bottom-left-radius:var(--sys-shape-corner-extra-small);border-bottom-right-radius:var(--sys-shape-corner-extra-small)}.codeblock .editor-wrapper:has(.heading){padding:var(--sys-size-3) var(--sys-size-4) 0 5px}.codeblock:not(:has(.toolbar)) .editor-wrapper{border-radius:var(--sys-shape-corner-extra-small)}.codeblock .editor-wrapper .code{max-height:var(--code-block-max-code-height);overflow:auto;padding-bottom:10px}.codeblock.no-toolbar .editor-wrapper{position:relative}.codeblock.no-toolbar .copy-button-container{position:absolute;top:5px;right:5px;z-index:1}.heading{display:flex;justify-content:space-between;align-items:center;height:var(--sys-size-11)}.heading-text-wrapper{display:flex;.citation{text-decoration:underline;color:var(--sys-color-primary);background-color:transparent;cursor:pointer;outline-offset:var(--sys-size-2);border:none;padding-bottom:2px;font-size:11px;font-family:var(--default-font-family)}}.heading-text{font:var(--sys-typescale-body5-bold);padding-left:var(--sys-size-4);padding-right:var(--sys-size-2)}.codeblock .lang{padding:var(--sys-size-4) 0;flex:1}.codeblock .copy-button-container{display:flex;justify-content:center;align-items:center;font-size:var(--sys-typescale-body5-size);span{padding-right:var(--sys-size-4)}}.notice{margin-top:var(--sys-size-2);padding:var(--sys-size-4) var(--sys-size-5);background-color:var(--code-block-background-color);border-radius:var(--sys-shape-corner-extra-small);.link{font:var(--sys-typescale-body4-regular);color:var(--sys-color-primary);text-decoration-line:underline}}.show-all-container{display:flex;justify-content:center;align-items:center;padding:var(--sys-size-4) 0;background-color:var(--code-block-background-color)}
/*# sourceURL=${import.meta.resolve("./codeBlock.css")} */`;var{html:l}=n,c={code:"Code",copy:"Copy code",copyCodeSnippet:"Copy {PH1} code snippet",copied:"Copied to clipboard",disclaimer:"Use code snippets with caution",showAllLines:"Show all lines ({PH1} more)"},B=x.i18n.registerUIStrings("ui/components/markdown_view/CodeBlock.ts",c),d=x.i18n.getLocalizedString.bind(void 0,B);async function z(i){switch(i){case"javascript":case"js":case"jsx":return s.javascript.javascript({jsx:!0});case"typescript":case"ts":return s.javascript.javascript({typescript:!0});case"tsx":return s.javascript.javascript({typescript:!0,jsx:!0});case"less":case"scss":case"sass":case"css":return s.css.css();case"html":return s.html.html({autoCloseTags:!1,selfClosingTags:!0});case"xml":return(await s.xml()).xml();case"cpp":return(await s.cpp()).cpp();case"go":return new s.LanguageSupport(await s.go());case"java":return(await s.java()).java();case"kotlin":return new s.LanguageSupport(await s.kotlin());case"json":{let e=s.javascript.javascriptLanguage.configure({top:"SingleExpression"});return new s.LanguageSupport(e)}case"php":return(await s.php()).php();case"python":case"py":return(await s.python()).python();case"markdown":case"md":return(await s.markdown()).markdown();case"sh":case"bash":return new s.LanguageSupport(await s.shell());case"dart":return new s.LanguageSupport(await s.dart());case"angular":return(await s.angular()).angular();case"svelte":return(await s.svelte()).svelte();case"vue":return(await s.vue()).vue();default:return s.html.html({autoCloseTags:!1,selfClosingTags:!0})}}var w=class extends HTMLElement{#e=this.attachShadow({mode:"open"});#t="";#s="";#i=1e3;#o;#n=!1;#a;#l=new s.Compartment;#d=new s.Compartment;#u=!1;#p;#h=!0;#m=!0;#g=[];#c=Number.MAX_VALUE;connectedCallback(){this.#r()}set code(e){this.#t=e,this.#a=s.EditorState.create({doc:this.#t,extensions:[T.Config.baseConfiguration(this.#t),s.EditorState.readOnly.of(!0),s.EditorView.editable.of(!1),s.EditorView.lineWrapping,this.#l.of(s.javascript.javascript()),this.#d.of([])]}),this.#r()}get code(){return this.#t}set codeLang(e){this.#s=e,this.#r()}set timeout(e){this.#i=e,this.#r()}set displayNotice(e){this.#u=e,this.#r()}set header(e){this.#p=e,this.#r()}set showCopyButton(e){this.#h=e,this.#r()}set citations(e){this.#g=e}set displayToolbar(e){this.#m=e,this.#r()}set displayLimit(e){this.#c=e,this.#r()}get displayLimit(){return this.#c}#w(){S.UIUtils.copyTextToClipboard(this.#t,d(c.copied)),this.#n=!0,this.#r(),clearTimeout(this.#o),this.#o=setTimeout(()=>{this.#n=!1,this.#r()},this.#i)}#v(){return l`<p class="notice">
      <devtools-link class="link" href="https://support.google.com/legal/answer/13505487" jslogcontext="code-disclaimer">
        ${d(c.disclaimer)}
      </devtools-link>
    </p>`}#f(){return l`
      <div class="copy-button-container">
        <devtools-button
          .data=${{variant:"icon",size:"SMALL",jslogContext:"copy",iconName:"copy",title:d(c.copy)}}
          .accessibleLabel=${this.#p?d(c.copyCodeSnippet,{PH1:this.#p}):d(c.copy)}
          @click=${this.#w}
        ></devtools-button>
        ${this.#n?l`<span>${d(c.copied)}</span>`:n.nothing}
      </div>`}#b(){return this.#g.length?l`
      ${this.#g.map(e=>l`
        <button
          class="citation"
          jslog=${v.link("inline-citation").track({click:!0})}
          @click=${e.clickHandler}
        >[${e.index}]</button>
      `)}
    `:n.nothing}async#r(){let e=(this.#p??this.#s)||d(c.code);if(!this.#a)throw new Error("Unexpected: trying to render the text editor without editorState");let t=this.#a.doc.lines,r=t>this.#c;n.render(l`<div class=${n.Directives.classMap({codeblock:!0,"no-toolbar":!this.#m})} jslog=${v.section("code")}>
      <style>${L}</style>
        <div class="editor-wrapper">
        ${this.#m?l`
          <div class="heading">
            <div class="heading-text-wrapper">
              <h4 class="heading-text">${e}</h4>
              ${this.#b()}
            </div>
            ${this.#h?this.#f():n.nothing}
          </div>
        `:l`
          ${this.#h?this.#f():n.nothing}
        `}
        <div class="code">
          <devtools-text-editor .state=${this.#a}></devtools-text-editor>
        </div>
        ${r?l`
          <div class="show-all-container">
            <devtools-button
              .variant=${"outlined"}
              .size=${"SMALL"}
              .jslogContext=${"show-all"}
              .title=${d(c.showAllLines,{PH1:t-this.#c})}
              @click=${()=>{this.displayLimit=Number.MAX_VALUE}}
            >${d(c.showAllLines,{PH1:t-this.#c})}</devtools-button>
          </div>
        `:n.nothing}
      </div>
      ${this.#u?this.#v():n.nothing}
    </div>`,this.#e,{host:this});let a=this.#e?.querySelector("devtools-text-editor")?.editor;if(!a)return;let m=await z(this.#s),p=[];r&&(p=s.EditorView.decorations.of(s.Decoration.set(s.Decoration.replace({}).range(this.#a.doc.line(this.#c).to,this.#a.doc.length)))),a.dispatch({effects:[this.#l.reconfigure(m),this.#d.reconfigure(p)]})}};customElements.define("devtools-code-block",w);var P={};u(P,{MarkdownImage:()=>b});import"./../../kit/kit.js";import*as g from"./../../lit/lit.js";var j=`.markdown-image{display:block}
/*# sourceURL=${import.meta.resolve("./markdownImage.css")} */`;var I={};u(I,{getMarkdownImage:()=>k,markdownImages:()=>A});var A=new Map([]),k=i=>{let e=A.get(i);if(!e)throw new Error(`Markdown image with key '${i}' is not available, please check MarkdownImagesMap.ts`);return e};var{html:C,Directives:{ifDefined:R}}=g,b=class extends HTMLElement{#e=this.attachShadow({mode:"open"});#t;#s;set data(e){let{key:t,title:r}=e,a=k(t);this.#t=a,this.#s=r,this.#n()}#i(){if(!this.#t)return g.nothing;let{src:e,color:t,width:r="100%",height:a="100%"}=this.#t;return C`
      <devtools-icon .data=${{iconPath:e,color:t,width:r,height:a}}></devtools-icon>
    `}#o(){if(!this.#t)return g.nothing;let{src:e,width:t="100%",height:r="100%"}=this.#t;return C`
      <img class="markdown-image" src=${e} alt=${R(this.#s)} width=${t} height=${r} />
    `}#n(){if(!this.#t)return;let{isIcon:e}=this.#t,t=e?this.#i():this.#o();g.render(C`
      <style>${j}</style>
      ${t}
    `,this.#e,{host:this})}};customElements.define("devtools-markdown-image",b);var U={};u(U,{getMarkdownLink:()=>$,markdownLinks:()=>F});var F=new Map([["issuesContrastWCAG21AA","https://www.w3.org/TR/WCAG21/#contrast-minimum"],["issuesContrastWCAG21AAA","https://www.w3.org/TR/WCAG21/#contrast-enhanced"],["issuesContrastSuggestColor","https://developers.google.com/web/updates/2020/08/devtools#accessible-color"],["issuesCSPSetStrict","https://web.dev/strict-csp"],["issuesCSPWhyStrictOverAllowlist","https://web.dev/strict-csp/#why-a-strict-csp-is-recommended-over-allowlist-csps"],["issueCorsPreflightRequest","https://web.dev/cross-origin-resource-sharing/#preflight-requests-for-complex-http-calls"],["issueQuirksModeDoctype","https://web.dev/doctype/"],["sameSiteAndSameOrigin","https://web.dev/same-site-same-origin/"],["punycodeReference","https://wikipedia.org/wiki/Punycode"],["https://xhr.spec.whatwg.org/","https://xhr.spec.whatwg.org/"],["https://goo.gle/chrome-insecure-origins","https://goo.gle/chrome-insecure-origins"],["https://webrtc.org/web-apis/chrome/unified-plan/","https://webrtc.org/web-apis/chrome/unified-plan/"],["https://developer.chrome.com/blog/enabling-shared-array-buffer/","https://developer.chrome.com/blog/enabling-shared-array-buffer/"],["https://developer.chrome.com/docs/extensions/mv3/","https://developer.chrome.com/docs/extensions/mv3/"],["https://developer.chrome.com/blog/immutable-document-domain/","https://developer.chrome.com/blog/immutable-document-domain/"],["https://github.com/WICG/shared-element-transitions/blob/main/debugging_overflow_on_images.md","https://github.com/WICG/shared-element-transitions/blob/main/debugging_overflow_on_images.md"],["https://developer.chrome.com/docs/extensions/reference/privacy/#property-websites-privacySandboxEnabled","https://developer.chrome.com/docs/extensions/reference/privacy/#property-websites-privacySandboxEnabled"],["PNASecureContextRestrictionFeatureStatus","https://chromestatus.com/feature/5954091755241472"],["https://w3c.github.io/uievents/#legacy-event-types","https://w3c.github.io/uievents/#legacy-event-types"],["manageCookiesHelpPage","https://support.google.com/chrome/answer/95647"],["gracePeriodStagedControlExplainer","https://developers.google.com/privacy-sandbox/blog/grace-period-opt-out"],["signatureHeader","https://www.rfc-editor.org/rfc/rfc9421.html#name-the-signature-http-field"],["signatureInputHeader","https://www.rfc-editor.org/rfc/rfc9421.html#name-the-signature-input-http-fi"],["signatureParameters","https://www.rfc-editor.org/rfc/rfc9421.html#name-signature-parameters"],["sfByteSequence","https://www.rfc-editor.org/rfc/rfc8941.html#name-byte-sequences"],["sfDictionary","https://www.rfc-editor.org/rfc/rfc8941.html#name-dictionaries"],["sfInnerList","https://www.rfc-editor.org/rfc/rfc8941.html#name-inner-lists"],["sfList","https://www.rfc-editor.org/rfc/rfc8941.html#name-lists"],["sfString","https://www.rfc-editor.org/rfc/rfc8941.html#name-strings"],["sfToken","https://www.rfc-editor.org/rfc/rfc8941.html#name-tokens"],["componentParameterSf","https://www.rfc-editor.org/rfc/rfc9421.html#name-strict-serialization-of-htt"],["componentParameterReq","https://www.rfc-editor.org/rfc/rfc9421.html#content-request-response"],["unencodedDigestHeader","https://lpardue.github.io/draft-pardue-http-identity-digest/draft-pardue-httpbis-identity-digest.html"],["storagePartitioningExplainer","https://developers.google.com/privacy-sandbox/cookies/storage-partitioning"],["storageAccessAPI","https://developer.mozilla.org/en-US/docs/Web/API/StorageAccessHandle/createObjectURL"],["https://goo.gle/ps-status","https://goo.gle/ps-status"],["https://privacysandbox.com/news/update-on-plans-for-privacy-sandbox-technologies/","https://privacysandbox.com/news/update-on-plans-for-privacy-sandbox-technologies/"],["urlPatternSpec","https://urlpattern.spec.whatwg.org/"],["SelectivePermissionsInterventionIssue","https://issues.chromium.org/issues/new?component=1456114&title=Selective%20Permissions%20Intervention%20Breakage:%20%3Cyour%20domain%20here%3E&template=0"],["ChromeFilterlistRepository","https://github.com/chromium/chromium-ads-detection"]]),$=i=>{if(/^https:\/\/www\.chromestatus\.com\//.test(i)||/^https:\/\/developer\.chrome\.com\//.test(i)||/^https:\/\/developers\.google\.com\//.test(i)||/^https:\/\/web\.dev\//.test(i)||/^https:\/\/developer\.mozilla\.org\//.test(i)||i==="https://philipwalton.com/articles/the-state-of-es5-on-the-web/")return i;let e=F.get(i);if(!e)throw new Error(`Markdown link with key '${i}' is not available, please check MarkdownLinksMap.ts`);return e};var q={};u(q,{MarkdownInsightRenderer:()=>M,MarkdownLitRenderer:()=>f,MarkdownView:()=>y});import"./../../kit/kit.js";import*as h from"./../../lit/lit.js";import*as _ from"./../../visual_logging/visual_logging.js";var H=`:host{--code-background-color:var(--sys-color-surface4)}@keyframes typing{from{width:0}to{width:100%}}@keyframes expand{from{height:0}to{height:auto}}devtools-link{color:var(--sys-color-primary);outline-offset:2px;text-decoration:underline}.animating{overflow:hidden;white-space:nowrap;animation:typing 0.4s steps(40,end)}devtools-code-block.animating{animation:expand 0.1s linear}.pending{display:none!important}.message{line-height:18px;font-size:12px;color:var(--sys-color-on-surface);user-select:text}.message p{margin:0}.message p:not(:first-child){margin-block-start:2px}.message p:not(:last-child){margin-bottom:10px}.message ul{list-style-type:none;padding-inline-start:var(--sys-size-8)}.message ul ul{padding-inline-start:19px}.message li{margin-top:8px;display:list-item;list-style-type:disc}.message li.animating{overflow:visible;white-space:normal;animation:none}.message li.animating > .markdown-list-item-content{display:inline-block;vertical-align:top;overflow:hidden;white-space:nowrap;animation:typing 0.4s steps(40,end)}.message code{color:var(--sys-color-on-surface);font-family:var(--monospace-font-family);font-size:11px;user-select:text;cursor:text;background-color:var(--code-background-color);border-radius:2px;padding:1px 3px}devtools-code-block{margin-bottom:var(--sys-size-5)}.citation{text-decoration:underline;color:var(--sys-color-primary);background-color:transparent;cursor:pointer;outline-offset:var(--sys-size-2);border:none;padding:0;font-size:10px;font-family:var(--default-font-family)}h1.insight, h2.insight, h3.insight, h4.insight, h5.insight, h6.insight{font:var(--sys-typescale-body4-bold);margin:var(--sys-size-1) 0 10px}.message table{border-collapse:collapse;margin:var(--sys-size-5) 0;width:100%}.message th,
.message td{border:1px solid var(--sys-color-divider);padding:var(--sys-size-4) var(--sys-size-5)}.message th{background-color:var(--sys-color-surface2);font-weight:bold}
/*# sourceURL=${import.meta.resolve("./markdownView.css")} */`;var o=h.html,V=h.render,y=class extends HTMLElement{#e=this.attachShadow({mode:"open"});#t=[];#s=new f;#i=!1;#o=!1;set data(e){this.#t=e.tokens,e.renderer&&(this.#s=e.renderer),e.animationEnabled?(this.#i=!0,this.#s.addCustomClasses({paragraph:"pending",heading:"pending",list_item:"pending",code:"pending"})):this.#n(),this.#l()}#n(){let e=this.#e.querySelectorAll(".animating");for(let r of e)r.classList.remove("animating");let t=this.#e.querySelectorAll(".pending");for(let r of t)r.classList.remove("pending");this.#o=!1,this.#i=!1,this.#s.removeCustomClasses({paragraph:"pending",heading:"pending",list_item:"pending",code:"pending"})}#a(){if(this.#o)return;this.#o=!0;let e=()=>{let t=this.#e.querySelector(".pending");if(!t){this.#o=!1;return}t.addEventListener("animationend",()=>{t.classList.remove("animating"),e()},{once:!0}),t.classList.remove("pending"),t.classList.add("animating")};e()}#l(){this.#d(),this.#i&&this.#a()}#d(){V(o`
      <style>${H}</style>
      <div class='message'>
        ${this.#t.map(e=>this.#s.renderToken(e))}
      </div>
    `,this.#e,{host:this})}};customElements.define("devtools-markdown-view",y);var D=new Set(["list","code","table","heading","paragraph","blockquote"]);function O(i){return D.has(i.type)}var f=class{#e={};addCustomClasses(e){for(let[t,r]of Object.entries(e))this.#e[t]||(this.#e[t]=new Set),this.#e[t].add(r)}removeCustomClasses(e){for(let[t,r]of Object.entries(e))this.#e[t]&&this.#e[t].delete(r)}customClassMapForToken(e){let t=this.#e[e]||new Set,r=Object.fromEntries([...t].map(a=>[a,!0]));return h.Directives.classMap(r)}renderChildTokens(e){if("tokens"in e&&e.tokens)return e.tokens.map(t=>this.renderToken(t));throw new Error("Tokens not found")}unescape(e){let t=new Map([["&amp;","&"],["&lt;","<"],["&gt;",">"],["&quot;",'"'],["&#39;","'"]]);return e.replace(/&(amp|lt|gt|quot|#39);/g,r=>{let a=t.get(r);return a||r})}renderText(e){return"tokens"in e&&e.tokens?o`${this.renderChildTokens(e)}`:o`${this.unescape("text"in e?e.text:"")}`}renderHeading(e){let t=this.customClassMapForToken("heading");switch(e.depth){case 1:return o`<h1 class=${t}>${this.renderText(e)}</h1>`;case 2:return o`<h2 class=${t}>${this.renderText(e)}</h2>`;case 3:return o`<h3 class=${t}>${this.renderText(e)}</h3>`;case 4:return o`<h4 class=${t}>${this.renderText(e)}</h4>`;case 5:return o`<h5 class=${t}>${this.renderText(e)}</h5>`;default:return o`<h6 class=${t}>${this.renderText(e)}</h6>`}}renderCodeBlock(e){return o`<devtools-code-block
      class=${this.customClassMapForToken("code")}
      .code=${this.unescape(e.text)}
      .codeLang=${e.lang||""}>
    </devtools-code-block>`}templateForToken(e){switch(e.type){case"paragraph":return o`<p class=${this.customClassMapForToken("paragraph")}>${this.renderChildTokens(e)}</p>`;case"list":return o`<ul class=${this.customClassMapForToken("list")}>${e.items.map(t=>this.renderToken(t))}</ul>`;case"list_item":{let t=e.tokens||[],r=[],a=[],m=()=>{a.length>0&&(r.push(o`<span class="markdown-list-item-content">${a.map(p=>this.renderToken(p))}</span>`),a=[])};for(let p of t)O(p)?(m(),r.push(o`${this.renderToken(p)}`)):a.push(p);return m(),o`<li class=${this.customClassMapForToken("list_item")}>${r}</li>`}case"text":return this.renderText(e);case"codespan":return o`<code class=${this.customClassMapForToken("codespan")}>${this.unescape(e.text)}</code>`;case"code":return this.renderCodeBlock(e);case"space":return h.nothing;case"link":return o`<devtools-link
        class=${this.customClassMapForToken("link")}
        href=${$(e.href)}
        >${e.text}</devtools-link>`;case"image":return o`<devtools-markdown-image
        class=${this.customClassMapForToken("image")}
        .data=${{key:e.href,title:e.text}}></devtools-markdown-image>`;case"heading":return this.renderHeading(e);case"strong":return o`<strong class=${this.customClassMapForToken("strong")}>${this.renderText(e)}</strong>`;case"em":return o`<em class=${this.customClassMapForToken("em")}>${this.renderText(e)}</em>`;case"table":{let t=e;return o`
          <table class=${this.customClassMapForToken("table")}>
            <thead>
              <tr>
                ${t.header.map(r=>o`
                  <th style=${r.align?`text-align: ${r.align}`:""}>
                    ${r.tokens.map(a=>this.renderToken(a))}
                  </th>
                `)}
              </tr>
            </thead>
            <tbody>
              ${t.rows.map(r=>o`
                <tr>
                  ${r.map(a=>o`
                    <td style=${a.align?`text-align: ${a.align}`:""}>
                      ${a.tokens.map(m=>this.renderToken(m))}
                    </td>
                  `)}
                </tr>
              `)}
            </tbody>
          </table>
        `}default:return null}}renderToken(e){let t=this.templateForToken(e);if(t===null)throw new Error(`Markdown token type '${e.type}' not supported.`);return t}},M=class extends f{#e;constructor(e){super(),this.#e=e||(()=>{}),this.addCustomClasses({heading:"insight"})}renderToken(e){try{let t=this.templateForToken(e);return t===null?o`${e.raw}`:t}catch(t){return console.error("Failed to render markdown token:",t),o`${e.raw}`}}sanitizeUrl(e){try{let t=new URL(e);return t.protocol==="https:"||t.protocol==="http:"?t.toString():null}catch{return null}}detectCodeLanguage(e){return e.lang?e.lang:/^(\.|#)?[\w:\[\]="'-\.]+ ?{/m.test(e.text)||/^@import/.test(e.text)?"css":/^(var|const|let|function|async|import)\s/.test(e.text)?"js":""}templateForToken(e){switch(e.type){case"heading":return this.renderHeading(e);case"link":case"image":return this.sanitizeUrl(e.href)?o`${e.text??e.href}`:null;case"code":return o`<devtools-code-block
          class=${this.customClassMapForToken("code")}
          .code=${this.unescape(e.text)}
          .codeLang=${this.detectCodeLanguage(e)}
          .citations=${e.citations||[]}
          .displayNotice=${!0}>
        </devtools-code-block>`;case"citation":return o`<sup><button
            class="citation"
            jslog=${_.link("inline-citation").track({click:!0})}
            @click=${this.#e.bind(this,Number(e.linkText))}
          >[${e.linkText}]</button></sup>`}return super.templateForToken(e)}};export{E as CodeBlock,P as MarkdownImage,I as MarkdownImagesMap,U as MarkdownLinksMap,q as MarkdownView};
//# sourceMappingURL=markdown_view.js.map
