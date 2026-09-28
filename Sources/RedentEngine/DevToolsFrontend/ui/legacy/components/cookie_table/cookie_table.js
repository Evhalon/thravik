var P=Object.defineProperty;var L=(g,e)=>{for(var i in e)P(g,i,{get:e[i],enumerable:!0})};var U={};L(U,{CookiesTable:()=>w});import"./../data_grid/data_grid.js";import"./../../../components/buttons/buttons.js";import*as p from"./../../../../core/common/common.js";import*as f from"./../../../../core/i18n/i18n.js";import*as S from"./../../../../core/root/root.js";import*as E from"./../../../../core/sdk/sdk.js";import*as b from"./../../../../models/issues_manager/issues_manager.js";import*as C from"./../../../../panels/network/forward/forward.js";import{Icon as T}from"./../../../kit/kit.js";import{Directives as K,html as u,nothing as I,render as V}from"./../../../lit/lit.js";import*as A from"./../../legacy.js";var B=`.data-grid-data-grid-node .ai-button-container{display:none;float:right;devtools-floating-button{position:absolute;z-index:999;margin-left:-17px}}.data-grid-data-grid-node:hover .ai-button-container{display:inline-flex}
/*# sourceURL=${import.meta.resolve("./dataGridAiButton.css")} */`;var v=`devtools-data-grid{flex:auto}.cookies-table devtools-icon{margin-right:4px}
/*# sourceURL=${import.meta.resolve("./cookiesTable.css")} */`;var{repeat:q,ifDefined:k}=K,a={session:"Session",name:"Name",value:"Value",size:"Size",domain:"Domain",path:"Path",secure:"Secure",partitionKeySite:"Partition Key Site",priority:"Priority",editableCookies:"Editable Cookies",cookies:"Cookies",na:"N/A",showRequestsWithThisCookie:"Show requests with this cookie",showIssueAssociatedWithThis:"Show issue associated with this cookie",sourcePortTooltip:"Shows the source port (range 1-65535) the cookie was set on. If the port is unknown, this shows -1.",sourceSchemeTooltip:"Shows the source scheme (`Secure`, `NonSecure`) the cookie was set on. If the scheme is unknown, this shows `Unset`.",timeAfter:"after {date}",timeAfterTooltip:"The expiration timestamp is {seconds}, which corresponds to a date after {date}",opaquePartitionKey:"(opaque)",httpOnlyCookiesCannotBeAdded:"HttpOnly cookies cannot be added as context"},D=f.i18n.registerUIStrings("ui/legacy/components/cookie_table/CookiesTable.ts",a),r=f.i18n.getLocalizedString.bind(void 0,D),M=f.i18n.getLazilyComputedLocalizedString.bind(void 0,D),$=M(a.session);function R(g){return g==="http-only"||g==="secure"}var w=class extends A.Widget.VBox{#t;#i;#o;#s;#e=!1;#r;#l;#d;lastEditedColumnId;data=[];cookies=[];#n;cookieToBlockedReasons;cookieToExemptionReason;view;selectedKey;#a;renderInline;schemeBindingEnabled;portBindingEnabled;constructor(e,i,n,t,h,d,l){super(e),l||(l=(o,F,x)=>{V(u`
          <devtools-data-grid
               name=${o.editable?r(a.editableCookies):r(a.cookies)}
               id="cookies-table"
               striped
               ?inline=${o.renderInline}
               @create=${s=>o.onCreate(s.detail)}
               @refresh=${o.onRefresh}
               @deselect=${()=>o.onSelect(void 0)}
          >
            <table>
              ${o.showAiButton?u`<style>${B}</style>`:I}
               <tr>
                 <th id=${"name"} sortable ?disclosure=${o.editable} ?editable=${o.editable} long weight="24">
                   ${r(a.name)}
                 </th>
                 <th id=${"value"} sortable ?editable=${o.editable} long weight="34">
                   ${r(a.value)}
                 </th>
                 <th id=${"domain"} sortable weight="7" ?editable=${o.editable}>
                   ${r(a.domain)}
                 </th>
                 <th id=${"path"} sortable weight="7" ?editable=${o.editable}>
                   ${r(a.path)}
                 </th>
                 <th id=${"expires"} sortable weight="7" ?editable=${o.editable}>
                   Expires / Max-Age
                 </th>
                 <th id=${"size"} sortable align="right" weight="7">
                   ${r(a.size)}
                 </th>
                 <th id=${"http-only"} sortable align="center" weight="7" ?editable=${o.editable} type="boolean">
                   HttpOnly
                 </th>
                 <th id=${"secure"} sortable align="center" weight="7" ?editable=${o.editable} type="boolean">
                   ${r(a.secure)}
                 </th>
                 <th id=${"same-site"} sortable weight="7" ?editable=${o.editable}>
                   SameSite
                 </th>
                 <th id=${"partition-key-site"} sortable weight="7" ?editable=${o.editable}>
                   ${r(a.partitionKeySite)}
                 </th>
                 <th id=${"has-cross-site-ancestor"} sortable align="center" weight="7" ?editable=${o.editable} type="boolean">
                   Cross Site
                 </th>
                 <th id=${"priority"} sortable weight="7" ?editable=${o.editable}>
                   ${r(a.priority)}
                 </th>
                 ${o.schemeBindingEnabled?u`
                 <th id=${"source-scheme"} sortable align="center" weight="7" ?editable=${o.editable} type="string">
                   SourceScheme
                 </th>`:""}
                 ${o.portBindingEnabled?u`
                <th id=${"source-port"} sortable align="center" weight="7" ?editable=${o.editable} type="number">
                   SourcePort
                </th>`:""}
              </tr>
              ${q(this.data,s=>s.key,s=>{let y=!!s["http-only"];return u`
                <tr ?selected=${s.key===o.selectedKey}
                    ?inactive=${s.inactive}
                    ?dirty=${s.dirty}
                    ?highlighted=${s.flagged}
                    @edit=${m=>o.onEdit(s,m.detail.columnId,m.detail.valueBeforeEditing,m.detail.newText)}
                    @delete=${()=>o.onDelete(s)}
                    @contextmenu=${m=>o.onContextMenu(s,m.detail)}
                    @select=${()=>o.onSelect(s.key)}>
                  <td>${o.showAiButton?u`
                      <span class="ai-button-container">
                        <devtools-floating-button
                          icon-name=${S.Runtime.hostConfig.devToolsGeminiRebranding?.enabled?"spark":"smart-assistant"}
                          title=${k(y?r(a.httpOnlyCookiesCannotBeAdded):o.aiButtonTitle)}
                          ?disabled=${y}
                          @click=${m=>!y&&o.onAiButtonClick?.(s,m)}
                        ></devtools-floating-button>
                      </span>
                    `:I}${s.icons?.name}${s.name}</td>
                  <td>${s.value}</td>
                  <td>${s.icons?.domain}${s.domain}</td>
                  <td>${s.icons?.path}${s.path}</td>
                  <td title=${k(s.expiresTooltip)}>${s.expires}</td>
                  <td>${s.size}</td>
                  <td data-value=${y}></td>
                  <td data-value=${!!s.secure}>${s.icons?.secure}</td>
                  <td>${s.icons?.["same-site"]}${s["same-site"]}</td>
                  <td>${s["partition-key-site"]}</td>
                  <td data-value=${!!s["has-cross-site-ancestor"]}></td>
                  <td data-value=${k(s.priorityValue)}>${s.priority}</td>
                  ${o.schemeBindingEnabled?u`
                    <td title=${r(a.sourceSchemeTooltip)}>${s["source-scheme"]}</td>`:""}
                  ${o.portBindingEnabled?u`
                    <td title=${r(a.sourcePortTooltip)}>${s["source-port"]}</td>`:""}
                </tr>`})}
                ${o.editable?u`<tr placeholder><tr>`:""}
              </table>
            </devtools-data-grid>`,x,{host:x})}),this.registerRequiredCSS(v),this.element.classList.add("cookies-table"),this.#t=n,this.#i=t,this.#s=d,this.#a=!!n;let{devToolsEnableOriginBoundCookies:c}=S.Runtime.hostConfig;this.schemeBindingEnabled=!!c?.schemeBindingEnabled,this.portBindingEnabled=!!c?.portBindingEnabled,this.view=l,this.renderInline=!!i,this.#o=h,this.lastEditedColumnId=null,this.data=[],this.#n="",this.cookieToBlockedReasons=null,this.cookieToExemptionReason=null,this.requestUpdate()}set cookiesData(e){this.setCookies(e.cookies,e.cookieToBlockedReasons,e.cookieToExemptionReason)}set saveCallback(e){this.#t=e}set refreshCallback(e){this.#i=e}set selectedCallback(e){this.#o=e}set aiButtonIsEnabled(e){this.#e=e}get aiButtonIsEnabled(){return this.#e}set onAiButtonClick(e){this.#r=e}set onPopulateAiContextMenu(e){this.#l=e}set aiButtonTitle(e){this.#d=e}set deleteCallback(e){this.#s=e}set editable(e){this.#a=e}set inline(e){this.renderInline=e,this.requestUpdate()}setCookies(e,i,n){this.cookieToBlockedReasons=i||null,this.cookieToExemptionReason=n||null,this.cookies=e;let t=this.data.find(d=>d.key===this.selectedKey),h=this.cookies.find(d=>d.key()===this.selectedKey);this.data=e.sort((d,l)=>d.name().localeCompare(l.name())).map(this.createCookieData.bind(this)),t&&this.lastEditedColumnId&&!h&&(t.inactive=!0,this.data.push(t)),this.requestUpdate()}set cookieDomain(e){this.#n=e}selectedCookie(){return this.cookies.find(e=>e.key()===this.selectedKey)||null}willHide(){super.willHide(),this.lastEditedColumnId=null}performUpdate(){let e=this.#r,i={data:this.data,selectedKey:this.selectedKey,editable:this.#a,renderInline:this.renderInline,schemeBindingEnabled:this.schemeBindingEnabled,portBindingEnabled:this.portBindingEnabled,onEdit:this.onUpdateCookie.bind(this),onCreate:this.onCreateCookie.bind(this),onRefresh:this.refresh.bind(this),onDelete:this.onDeleteCookie.bind(this),onSelect:this.onSelect.bind(this),onContextMenu:this.populateContextMenu.bind(this),showAiButton:this.#e,aiButtonTitle:this.#e?this.#d:void 0,onAiButtonClick:this.#e&&e?(t,h)=>{h.stopPropagation();let d=this.cookies.find(l=>l.key()===t.key);d&&e(d,h)}:void 0},n={};this.view(i,n,this.element)}onSelect(e){this.selectedKey=e,this.#o?.(this.selectedCookie())}onDeleteCookie(e){let i=this.cookies.find(n=>n.key()===e.key);i&&this.#s&&this.#s(i,()=>this.refresh())}onUpdateCookie(e,i,n,t){let h=this.cookies.find(l=>l.key()===e.key);if(!h)return;let d={...e,[i]:t};if(!this.isValidCookieData(d)){d.dirty=!0,this.requestUpdate();return}this.lastEditedColumnId=i,this.saveCookie(d,h)}onCreateCookie(e){this.setDefaults(e),this.isValidCookieData(e)?this.saveCookie(e):(e.dirty=!0,this.requestUpdate())}setDefaults(e){e.name===void 0&&(e.name=""),e.value===void 0&&(e.value=""),e.domain===void 0&&(e.domain=this.#n),e.path===void 0&&(e.path="/"),e.expires===void 0&&(e.expires=$()),e["partition-key"]===void 0&&(e["partition-key"]="")}saveCookie(e,i){if(!this.#t)return;let n=this.createCookieFromData(e);this.#t(n,i??null).then(t=>{t||(e.dirty=!0),this.refresh()})}createCookieFromData(e){let i=new E.Cookie.Cookie(e.name||"",e.value||"",null,e.priority);for(let n of["domain","path","http-only","secure","same-site","source-scheme"])if(n in e){let t=e[n];R(n)?t===!0&&i.addAttribute(n):i.addAttribute(n,t)}return e.expires&&e.expires!==$()&&i.addAttribute("expires",new Date(e.expires).toUTCString()),"source-port"in e&&i.addAttribute("source-port",Number.parseInt(e["source-port"]||"",10)||void 0),e["partition-key-site"]&&i.setPartitionKey(e["partition-key-site"],e["has-cross-site-ancestor"]===!0),i.setSize(e.name.length+e.value.length),i}createCookieData(e){let n=e.type()===0,t={name:e.name(),value:e.value()};for(let l of["http-only","secure","same-site","source-scheme","source-port"])e.hasAttribute(l)&&(R(l)?t[l]=!0:t[l]=String(e.getAttribute(l)??!0));t.domain=e.domain()||(n?r(a.na):""),t.path=e.path()||(n?r(a.na):""),t.expires=e.maxAge()?f.TimeUtilities.secondsToString(Math.floor(e.maxAge())):e.expires()<0?$():e.expires()>864e13?r(a.timeAfter,{date:new Date(864e13).toISOString()}):e.expires()>0?new Date(e.expires()).toISOString():n?r(a.na):$(),e.expires()>864e13&&(t.expiresTooltip=r(a.timeAfterTooltip,{seconds:e.expires(),date:new Date(864e13).toISOString()})),t["partition-key-site"]=e.partitionKeyOpaque()?r(a.opaquePartitionKey).toString():e.topLevelSite(),t["has-cross-site-ancestor"]=e.hasCrossSiteAncestor(),t.size=String(e.size()),t.priority=e.priority(),t.priorityValue=["Low","Medium","High"].indexOf(e.priority());let h=this.cookieToBlockedReasons?.get(e)||[];for(let l of h){t.flagged=!0;let c=l.attribute||"name";t.icons=t.icons||{},c in t.icons?t.icons[c]&&(t.icons[c].title+=`
`+l.uiString):(t.icons[c]=new T,t.icons[c].name="info",t.icons[c].classList.add("small"),t.icons[c].title=l.uiString)}let d=this.cookieToExemptionReason?.get(e)?.uiString;return d&&(t.icons=t.icons||{},t.flagged=!0,t.icons.name=new T,t.icons.name.name="info",t.icons.name.classList.add("small"),t.icons.name.title=d),t.key=e.key(),t}isValidCookieData(e){return(!!e.name||!!e.value)&&this.isValidDomain(e.domain)&&this.isValidPath(e.path)&&this.isValidDate(e.expires)&&this.isValidPartitionKey(e["partition-key-site"])}isValidDomain(e){if(!e)return!0;let i=p.ParsedURL.ParsedURL.fromString("http://"+e);return i!==null&&i.domain()===e}isValidPath(e){if(!e)return!0;let i=p.ParsedURL.ParsedURL.fromString("http://example.com"+e);return i!==null&&i.path===e}isValidDate(e){return!e||e===$()||!isNaN(Date.parse(e))}isValidPartitionKey(e){return e?p.ParsedURL.ParsedURL.fromString(e)!==null:!0}refresh(){this.#i&&this.#i()}populateContextMenu(e,i){let n=this.cookies.find(h=>h.key()===e.key);if(!n)return;let t=n;this.#l?.(t,i),i.revealSection().appendItem(r(a.showRequestsWithThisCookie),()=>{let h=C.UIFilter.UIRequestFilter.filters([{filterType:C.UIFilter.FilterType.CookieDomain,filterValue:t.domain()},{filterType:C.UIFilter.FilterType.CookieName,filterValue:t.name()}]);p.Revealer.reveal(h)},{jslogContext:"show-requests-with-this-cookie"}),b.RelatedIssue.hasIssues(t,b.IssuesManager.IssuesManager.instance())&&i.revealSection().appendItem(r(a.showIssueAssociatedWithThis),()=>{b.RelatedIssue.reveal(t,b.IssuesManager.IssuesManager.instance())},{jslogContext:"show-issue-associated-with-this"})}};export{U as CookiesTable};
//# sourceMappingURL=cookie_table.js.map
