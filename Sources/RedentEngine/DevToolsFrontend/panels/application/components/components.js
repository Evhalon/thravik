var Wt=Object.defineProperty;var $=(t,e)=>{for(var a in e)Wt(t,a,{get:e[a],enumerable:!0})};var Xe={};$(Xe,{AdsView:()=>be});import"./../../../ui/legacy/components/data_grid/data_grid.js";import"./../../../ui/kit/kit.js";import*as ee from"./../../../core/common/common.js";import*as S from"./../../../core/i18n/i18n.js";import*as k from"./../../../core/sdk/sdk.js";import*as te from"./../../../ui/legacy/legacy.js";import*as j from"./../../../ui/lit/lit.js";import*as _e from"./../../../ui/visual_logging/visual_logging.js";var je=`:host{padding:var(--sys-size-6);display:flex;flex-direction:column;overflow:auto}.ads-view-container{display:flex;flex-direction:column;flex:auto}.metrics-container{flex:0 0 auto;margin:0;border:1px solid var(--sys-color-divider);display:grid;grid-template-columns:repeat(2,1fr);gap:var(--sys-size-1);background-color:var(--sys-color-divider)}.metric-box{background-color:var(--sys-color-surface);padding:var(--sys-size-6);display:flex;flex-direction:column;align-items:center;justify-content:center}.metric-title{font-size:var(--sys-typescale-body4-size);color:var(--sys-color-on-surface-subtle);margin:0 0 var(--sys-size-3)}.metric-value{font-size:var(--sys-typescale-headline3-size);font-weight:bold;color:var(--sys-color-on-surface);display:flex;flex-direction:column;align-items:center;margin:0;gap:var(--sys-size-2)}.metric-average{font-size:var(--sys-typescale-body4-size);font-weight:normal;color:var(--sys-color-on-surface-subtle)}.metrics-title,
.ad-frames-title,
.settings-title{color:var(--sys-color-on-surface);flex:0 0 auto;font-weight:bold;margin-bottom:var(--sys-size-5)}.ad-frames-data-grid{flex:auto}.ad-frames-container{border:1px solid var(--sys-color-divider);display:flex;flex:1;flex-direction:column;margin-bottom:0;min-height:var(--sys-size-22);position:relative;overflow:hidden}.divider{border:none;border-top:1px solid var(--sys-color-divider);margin:var(--sys-size-8) 0 var(--sys-size-6)}.setting-text-container{display:flex;flex-direction:column}.setting-explanation{color:var(--sys-color-token-subtle);white-space:break-spaces;margin-top:0}.footer-text{margin-bottom:var(--sys-size-6)}.inline-icon{width:var(--sys-size-8);height:var(--sys-size-8);vertical-align:text-bottom}
/*# sourceURL=${import.meta.resolve("./adsView.css")} */`;var{html:ve}=j,{bindToSetting:qt}=te.UIUtils,v={metrics:"Metrics",viewportAdDensity:"Viewport ad density",viewportAdCount:"Viewport ad count",totalCpuUsage:"Total CPU usage by ads",totalNetworkUsage:"Total network usage by ads",average:"(Average: {PH1})",adIframesTitle:"Ad iframes (total {PH1})",notAvailable:"N/A",unnamed:"<unnamed>",elementId:"Element ID",initialOrigin:"Initial origin",cpu:"CPU",network:"Network",adIframes:"Ad iframes",settings:"Settings",highlightAds:"Highlight ads",highlightsElementsRedDetectedToBe:"Highlights elements (red) detected to be ads.",adDetectionMistakes:"Chrome\u2019s ad detection can make mistakes.",learnMore:"Learn more"},Ot=S.i18n.registerUIStrings("panels/application/components/AdsView.ts",v),b=S.i18n.getLocalizedString.bind(void 0,Ot),Z=(t,e)=>t===void 0||t===-1?b(v.notAvailable):e(t),Ge=t=>Z(t,e=>S.TimeUtilities.millisToString(e)),Je=t=>Z(t,e=>S.ByteUtilities.bytesToString(e)),Vt=(t,e,a)=>{let i=t.metrics,n=(s,h)=>Z(s,f=>h?new Intl.NumberFormat(S.DevToolsLocale.DevToolsLocale.instance().locale,{style:"percent",maximumFractionDigits:0}).format(f/100):new Intl.NumberFormat(S.DevToolsLocale.DevToolsLocale.instance().locale).format(f)),l=(s,h)=>Z(s,f=>h?new Intl.NumberFormat(S.DevToolsLocale.DevToolsLocale.instance().locale,{style:"percent",minimumFractionDigits:2,maximumFractionDigits:2}).format(f/100):new Intl.NumberFormat(S.DevToolsLocale.DevToolsLocale.instance().locale,{minimumFractionDigits:2,maximumFractionDigits:2}).format(f));j.render(ve`
    <style>${je}</style>
    <div class="ads-view-container" jslog=${_e.pane("ads")}>
      <div class="metrics-title">${b(v.metrics)}</div>
      <dl class="metrics-container">
        <div class="metric-box">
          <dt class="metric-title">${b(v.viewportAdDensity)}</dt>
          <dd class="metric-value">
            <span>${n(i.viewportAdDensityByArea,!0)}</span>
            <span class="metric-average">${b(v.average,{PH1:l(i.averageViewportAdDensityByArea,!0)})}</span>
          </dd>
        </div>
        <div class="metric-box">
          <dt class="metric-title">${b(v.viewportAdCount)}</dt>
          <dd class="metric-value">
            <span>${n(i.viewportAdCount,!1)}</span>
            <span class="metric-average">${b(v.average,{PH1:l(i.averageViewportAdCount,!1)})}</span>
          </dd>
        </div>
        <div class="metric-box">
          <dt class="metric-title">${b(v.totalCpuUsage)}</dt>
          <dd class="metric-value">
            <span>${Ge(i.totalAdCpuTime)}</span>
          </dd>
        </div>
        <div class="metric-box">
          <dt class="metric-title">${b(v.totalNetworkUsage)}</dt>
          <dd class="metric-value">
            <span>${Je(i.totalAdNetworkBytes)}</span>
          </dd>
        </div>
      </dl>
      <hr class="divider">
      <div class="ad-frames-title">${b(v.adIframesTitle,{PH1:t.adFrames.length})}</div>
      <div class="ad-frames-container">
        <devtools-data-grid striped resize="last" class="ad-frames-data-grid" name=${b(v.adIframes)}>
          <table>
            <tr>
              <th id="elementId" weight="1" sortable>${b(v.elementId)}</th>
              <th id="initialOrigin" weight="2" sortable>${b(v.initialOrigin)}</th>
              <th id="cpuTime" weight="1" sortable type="numeric">${b(v.cpu)}</th>
              <th id="networkBytes" weight="1" sortable type="numeric">${b(v.network)}</th>
            </tr>
            ${t.adFrames.map(s=>ve`
              <tr>
                <td title=${s.elementId}>
                  ${s.elementId?ve`
                        <button class="text-button link-style devtools-link" @click=${s.revealFrame}>
                          ${s.elementId}
                        </button>
                      `:j.nothing}
                </td>
                <td title=${s.initialOrigin}>${s.initialOrigin}</td>
                <td title=${s.cpuTime} data-value=${s.rawCpuTime}>${s.cpuTime}</td>
                <td title=${s.networkBytes} data-value=${s.rawNetworkBytes}>${s.networkBytes}</td>
              </tr>
            `)}
          </table>
        </devtools-data-grid>
      </div>
      <hr class="divider">
      <div class="settings-title">${b(v.settings)}</div>
      <devtools-checkbox class="setting-container small"
          ${qt(ee.Settings.Settings.instance().resolve(k.SDKSettings.showAdHighlightsSettingDescriptor))}>
        <div class="setting-text-container">
          <div class="setting-label">${b(v.highlightAds)}</div>
          <div class="setting-explanation">${b(v.highlightsElementsRedDetectedToBe)}</div>
        </div>
      </devtools-checkbox>
      <hr class="divider">
      <div class="footer-text">
        <devtools-icon class="inline-icon" name="info"></devtools-icon>
        &#32;
        <span>
          ${b(v.adDetectionMistakes)}
          &#32;
          <devtools-link class="link devtools-link" href="https://chromium.googlesource.com/chromium/src/+/main/docs/ad_tagging.md" jslogcontext="learn-more">
            ${b(v.learnMore)}
          </devtools-link>
        </span>
      </div>
    </div>
  `,a)},be=class extends te.Widget.Widget{#e;#t;#r=!1;#o=0;#i;#a=new Map;#n=new Map;#s=new Set;constructor(e=Vt){super({useShadowDom:!0}),this.#i=e,this.#e={viewportAdDensityByArea:0,averageViewportAdDensityByArea:0,viewportAdCount:0,averageViewportAdCount:0,totalAdCpuTime:0,totalAdNetworkBytes:0,updateAdFrames:[],removeAdFrames:[]},this.requestUpdate()}wasShown(){super.wasShown(),this.#l(),k.TargetManager.TargetManager.instance().addModelListener(k.ResourceTreeModel.ResourceTreeModel,k.ResourceTreeModel.Events.PrimaryPageChanged,this.#u,this)}willHide(){this.#c(),k.TargetManager.TargetManager.instance().removeModelListener(k.ResourceTreeModel.ResourceTreeModel,k.ResourceTreeModel.Events.PrimaryPageChanged,this.#u,this),super.willHide()}#l(){this.#r||(this.#r=!0,this.#o++,this.#d(this.#o))}#c(){this.#r=!1,this.#t!==void 0&&(window.clearTimeout(this.#t),this.#t=void 0)}async#d(e){if(!this.#r||this.#o!==e)return;let a=k.TargetManager.TargetManager.instance().primaryPageTarget();if(a){let i=a.adsAgent();if(i){let n=await i.invoke_getAdMetrics();if(!this.#r||this.#o!==e)return;n.getError()||(this.#e=n.metrics,this.#m(n.metrics),this.requestUpdate())}}this.#r&&this.#o===e&&(this.#t=window.setTimeout(()=>this.#d(e),500))}#m(e){for(let a of e.removeAdFrames||[])this.#a.delete(a),this.#n.delete(a);for(let a of e.updateAdFrames||[]){let i=a.frameId,l={...this.#a.get(i)||{},...a};this.#a.set(i,l)}for(let a of this.#a.keys())!this.#n.has(a)&&!this.#s.has(a)&&(this.#s.add(a),this.#g(a).then(i=>{this.#a.has(a)&&i!==void 0&&this.#n.set(a,i)}).catch(()=>{}).finally(()=>{this.#s.delete(a),this.requestUpdate()}))}async#g(e){let a=k.FrameManager.FrameManager.instance().getFrame(e);if(!a)return;let i=await a.getOwnerDeferredDOMNode();return i&&(await i.resolvePromise())?.getAttribute("id")||null}#u(){this.#e={viewportAdDensityByArea:0,averageViewportAdDensityByArea:0,viewportAdCount:0,averageViewportAdCount:0,totalAdCpuTime:0,totalAdNetworkBytes:0,updateAdFrames:[],removeAdFrames:[]},this.#a.clear(),this.#n.clear(),this.#s.clear(),this.requestUpdate()}performUpdate(){let e=[];for(let[i,n]of this.#a){let l=this.#n.has(i)?this.#n.get(i)||b(v.unnamed):"",s=h=>{h.preventDefault(),h.stopPropagation();let f=k.FrameManager.FrameManager.instance().getFrame(i);f&&ee.Revealer.reveal(f)};e.push({elementId:l,initialOrigin:n.initialOrigin||"",cpuTime:Ge(n.cpuTime),rawCpuTime:n.cpuTime??-1,networkBytes:Je(n.networkBytes),rawNetworkBytes:n.networkBytes??-1,revealFrame:s})}let a={metrics:this.#e,adFrames:e};this.#i(a,void 0,this.contentElement)}};var et={};$(et,{BackForwardCacheView:()=>ye});import"./../../../ui/components/expandable_list/expandable_list.js";import"./../../../ui/components/report_view/report_view.js";import"./../../../ui/legacy/legacy.js";import"./../../../ui/kit/kit.js";import*as Qe from"./../../../core/common/common.js";import*as Se from"./../../../core/i18n/i18n.js";import*as d from"./../../../core/sdk/sdk.js";import"./../../../ui/components/buttons/buttons.js";import*as Ze from"./../../../ui/legacy/components/utils/utils.js";import*as _ from"./../../../ui/legacy/legacy.js";import{html as p,nothing as P,render as zt}from"./../../../ui/lit/lit.js";import*as x from"./../../../ui/visual_logging/visual_logging.js";import*as w from"./../../../core/i18n/i18n.js";var r={notMainFrame:"Navigation happened in a frame other than the main frame.",backForwardCacheDisabled:"Back/forward cache is disabled by flags. Visit chrome://flags/#back-forward-cache to enable it locally on this device.",relatedActiveContentsExist:"The page was opened using '`window.open()`' and another tab has a reference to it, or the page opened a window.",HTTPStatusNotOK:"Only pages with a status code of 2XX can be cached.",schemeNotHTTPOrHTTPS:"Only pages whose URL scheme is HTTP / HTTPS can be cached.",loading:"The page did not finish loading before navigating away.",wasGrantedMediaAccess:"Pages that have granted access to record video or audio are not currently eligible for back/forward cache.",HTTPMethodNotGET:"Only pages loaded via a GET request are eligible for back/forward cache.",subframeIsNavigating:"An iframe on the page started a navigation that did not complete.",timeout:"The page exceeded the maximum time in back/forward cache and was expired.",cacheLimit:"The page was evicted from the cache to allow another page to be cached.",JavaScriptExecution:"Chrome detected an attempt to execute JavaScript while in the cache.",rendererProcessKilled:"The renderer process for the page in back/forward cache was killed.",rendererProcessCrashed:"The renderer process for the page in back/forward cache crashed.",grantedMediaStreamAccess:"Pages that have granted media stream access are not currently eligible for back/forward cache.",cacheFlushed:"The cache was intentionally cleared.",serviceWorkerVersionActivation:"The page was evicted from back/forward cache due to a service worker activation.",sessionRestored:"Chrome restarted and cleared the back/forward cache entries.",serviceWorkerPostMessage:"A service worker attempted to send the page in back/forward cache a `MessageEvent`.",enteredBackForwardCacheBeforeServiceWorkerHostAdded:"A service worker was activated while the page was in back/forward cache.",serviceWorkerClaim:"The page was claimed by a service worker while it is in back/forward cache.",haveInnerContents:"Pages that have certain kinds of embedded content (e.g. PDFs) are not currently eligible for back/forward cache.",timeoutPuttingInCache:"The page timed out entering back/forward cache (likely due to long-running pagehide handlers).",backForwardCacheDisabledByLowMemory:"Back/forward cache is disabled due to insufficient memory.",backForwardCacheDisabledByCommandLine:"Back/forward cache is disabled by the command line.",networkRequestDatapipeDrainedAsBytesConsumer:"Pages that have inflight fetch() or XHR are not currently eligible for back/forward cache.",networkRequestRedirected:"The page was evicted from back/forward cache because an active network request involved a redirect.",networkRequestTimeout:"The page was evicted from the cache because a network connection was open too long. Chrome limits the amount of time that a page may receive data while cached.",networkExceedsBufferLimit:"The page was evicted from the cache because an active network connection received too much data. Chrome limits the amount of data that a page may receive while cached.",navigationCancelledWhileRestoring:"Navigation was cancelled before the page could be restored from back/forward cache.",backForwardCacheDisabledForPrerender:"Back/forward cache is disabled for prerenderer.",userAgentOverrideDiffers:"Browser has changed the user agent override header.",foregroundCacheLimit:"The page was evicted from the cache to allow another page to be cached.",backForwardCacheDisabledForDelegate:"Back/forward cache is not supported by delegate.",unloadHandlerExistsInMainFrame:"The page has an unload handler in the main frame.",unloadHandlerExistsInSubFrame:"The page has an unload handler in a sub frame.",serviceWorkerUnregistration:"ServiceWorker was unregistered while a page was in back/forward cache.",noResponseHead:"Pages that do not have a valid response head cannot enter back/forward cache.",cacheControlNoStore:"Pages with cache-control:no-store header cannot enter back/forward cache.",ineligibleAPI:"Ineligible APIs were used.",internalError:"Internal error.",webSocket:"Pages with WebSocket cannot enter back/forward cache.",webTransport:"Pages with WebTransport cannot enter back/forward cache.",webRTC:"Pages with WebRTC cannot enter back/forward cache.",mainResourceHasCacheControlNoStore:"Pages whose main resource has cache-control:no-store cannot enter back/forward cache.",mainResourceHasCacheControlNoCache:"Pages whose main resource has cache-control:no-cache cannot enter back/forward cache.",subresourceHasCacheControlNoStore:"Pages whose subresource has cache-control:no-store cannot enter back/forward cache.",subresourceHasCacheControlNoCache:"Pages whose subresource has cache-control:no-cache cannot enter back/forward cache.",containsPlugins:"Pages containing plugins are not currently eligible for back/forward cache.",documentLoaded:"The document did not finish loading before navigating away.",dedicatedWorkerOrWorklet:"Pages that use a dedicated worker or worklet are not currently eligible for back/forward cache.",outstandingNetworkRequestOthers:"Pages with an in-flight network request are not currently eligible for back/forward cache.",outstandingIndexedDBTransaction:"Page with ongoing indexed DB transactions are not currently eligible for back/forward cache.",requestedNotificationsPermission:"Pages that have requested notifications permissions are not currently eligible for back/forward cache.",requestedMIDIPermission:"Pages that have requested MIDI permissions are not currently eligible for back/forward cache.",requestedAudioCapturePermission:"Pages that have requested audio capture permissions are not currently eligible for back/forward cache.",requestedVideoCapturePermission:"Pages that have requested video capture permissions are not currently eligible for back/forward cache.",requestedBackForwardCacheBlockedSensors:"Pages that have requested sensor permissions are not currently eligible for back/forward cache.",requestedBackgroundWorkPermission:"Pages that have requested background sync or fetch permissions are not currently eligible for back/forward cache.",broadcastChannel:"The page cannot be cached because it has a BroadcastChannel instance with registered listeners.",indexedDBConnection:"Pages that have an open IndexedDB connection are not currently eligible for back/forward cache.",webXR:"Pages that use WebXR are not currently eligible for back/forward cache.",sharedWorker:"Pages that use SharedWorker are not currently eligible for back/forward cache.",sharedWorkerMessage:"The page was evicted from the cache because it received a message from a SharedWorker",webLocks:"Pages that use WebLocks are not currently eligible for back/forward cache.",webHID:"Pages that use WebHID are not currently eligible for back/forward cache.",webShare:"Pages that use WebShare are not currently eligible for back/forwad cache.",requestedStorageAccessGrant:"Pages that have requested storage access are not currently eligible for back/forward cache.",webNfc:"Pages that use WebNfc are not currently eligible for back/forwad cache.",outstandingNetworkRequestFetch:"Pages with an in-flight fetch network request are not currently eligible for back/forward cache.",outstandingNetworkRequestXHR:"Pages with an in-flight XHR network request are not currently eligible for back/forward cache.",appBanner:"Pages that requested an AppBanner are not currently eligible for back/forward cache.",printing:"Pages that show Printing UI are not currently eligible for back/forward cache.",webDatabase:"Pages that use WebDatabase are not currently eligible for back/forward cache.",pictureInPicture:"Pages that use Picture-in-Picture are not currently eligible for back/forward cache.",speechRecognizer:"Pages that use SpeechRecognizer are not currently eligible for back/forward cache.",idleManager:"Pages that use IdleManager are not currently eligible for back/forward cache.",paymentManager:"Pages that use PaymentManager are not currently eligible for back/forward cache.",speechSynthesis:"Pages that use SpeechSynthesis are not currently eligible for back/forward cache.",keyboardLock:"Pages that use Keyboard lock are not currently eligible for back/forward cache.",webOTPService:"Pages that use WebOTPService are not currently eligible for bfcache.",outstandingNetworkRequestDirectSocket:"Pages with an in-flight network request are not currently eligible for back/forward cache.",injectedJavascript:"Pages that `JavaScript` is injected into by extensions are not currently eligible for back/forward cache.",injectedStyleSheet:"Pages that a `StyleSheet` is injected into by extensions are not currently eligible for back/forward cache.",contentDiscarded:"Undefined",contentSecurityHandler:"Pages that use SecurityHandler are not eligible for back/forward cache.",contentWebAuthenticationAPI:"Pages that use WebAuthetication API are not eligible for back/forward cache.",contentFileChooser:"Pages that use FileChooser API are not eligible for back/forward cache.",contentSerial:"Pages that use Serial API are not eligible for back/forward cache.",contentFileSystemAccess:"Pages that use File System Access API are not eligible for back/forward cache.",contentMediaDevicesDispatcherHost:"Pages that use Media Device Dispatcher are not eligible for back/forward cache.",contentWebBluetooth:"Pages that use WebBluetooth API are not eligible for back/forward cache.",contentWebUSB:"Pages that use WebUSB API are not eligible for back/forward cache.",contentMediaSession:"Pages that use MediaSession API and set a playback state are not eligible for back/forward cache.",contentMediaSessionService:"Pages that use MediaSession API and set action handlers are not eligible for back/forward cache.",contentMediaPlay:"A media player was playing upon navigating away.",contentScreenReader:"Back/forward cache is disabled due to screen reader.",embedderPopupBlockerTabHelper:"Popup blocker was present upon navigating away.",embedderSafeBrowsingTriggeredPopupBlocker:"Safe Browsing considered this page to be abusive and blocked popup.",embedderSafeBrowsingThreatDetails:"Safe Browsing details were shown upon navigating away.",embedderAppBannerManager:"App Banner was present upon navigating away.",embedderDomDistillerViewerSource:"DOM Distiller Viewer was present upon navigating away.",embedderDomDistillerSelfDeletingRequestDelegate:"DOM distillation was in progress upon navigating away.",embedderOomInterventionTabHelper:"Out-Of-Memory Intervention bar was present upon navigating away.",embedderOfflinePage:"The offline page was shown upon navigating away.",embedderChromePasswordManagerClientBindCredentialManager:"Chrome Password Manager was present upon navigating away.",embedderPermissionRequestManager:"There were permission requests upon navigating away.",embedderModalDialog:"Modal dialog such as form resubmission or http password dialog was shown for the page upon navigating away.",embedderExtensions:"Back/forward cache is disabled due to extensions.",embedderExtensionMessaging:"Back/forward cache is disabled due to extensions using messaging API.",embedderExtensionMessagingForOpenPort:"Extensions with long-lived connection should close the connection before entering back/forward cache.",embedderExtensionSentMessageToCachedFrame:"Extensions with long-lived connection attempted to send messages to frames in back/forward cache.",errorDocument:"Back/forward cache is disabled due to a document error.",fencedFramesEmbedder:"Pages using FencedFrames cannot be stored in bfcache.",keepaliveRequest:"Back/forward cache is disabled due to a keepalive request.",jsNetworkRequestReceivedCacheControlNoStoreResource:"Back/forward cache is disabled because some JavaScript network request received resource with `Cache-Control: no-store` header.",indexedDBEvent:"Back/forward cache is disabled due to an IndexedDB event.",cookieDisabled:"Back/forward cache is disabled because cookies are disabled on a page that uses `Cache-Control: no-store`.",webRTCUsedWithCCNS:"Back/forward cache is disabled because WebRTC has been used.",webTransportUsedWithCCNS:"Back/forward cache is disabled because WebTransport has been used.",webSocketUsedWithCCNS:"Back/forward cache is disabled because WebSocket has been used."},Kt=w.i18n.registerUIStrings("panels/application/components/BackForwardCacheStrings.ts",r),o=w.i18n.getLazilyComputedLocalizedString.bind(void 0,Kt),we={NotPrimaryMainFrame:{name:o(r.notMainFrame)},BackForwardCacheDisabled:{name:o(r.backForwardCacheDisabled)},RelatedActiveContentsExist:{name:o(r.relatedActiveContentsExist)},HTTPStatusNotOK:{name:o(r.HTTPStatusNotOK)},SchemeNotHTTPOrHTTPS:{name:o(r.schemeNotHTTPOrHTTPS)},Loading:{name:o(r.loading)},WasGrantedMediaAccess:{name:o(r.wasGrantedMediaAccess)},HTTPMethodNotGET:{name:o(r.HTTPMethodNotGET)},SubframeIsNavigating:{name:o(r.subframeIsNavigating)},Timeout:{name:o(r.timeout)},CacheLimit:{name:o(r.cacheLimit)},JavaScriptExecution:{name:o(r.JavaScriptExecution)},RendererProcessKilled:{name:o(r.rendererProcessKilled)},RendererProcessCrashed:{name:o(r.rendererProcessCrashed)},GrantedMediaStreamAccess:{name:o(r.grantedMediaStreamAccess)},CacheFlushed:{name:o(r.cacheFlushed)},ServiceWorkerVersionActivation:{name:o(r.serviceWorkerVersionActivation)},SessionRestored:{name:o(r.sessionRestored)},ServiceWorkerPostMessage:{name:o(r.serviceWorkerPostMessage)},EnteredBackForwardCacheBeforeServiceWorkerHostAdded:{name:o(r.enteredBackForwardCacheBeforeServiceWorkerHostAdded)},ServiceWorkerClaim:{name:o(r.serviceWorkerClaim)},HaveInnerContents:{name:o(r.haveInnerContents)},TimeoutPuttingInCache:{name:o(r.timeoutPuttingInCache)},BackForwardCacheDisabledByLowMemory:{name:o(r.backForwardCacheDisabledByLowMemory)},BackForwardCacheDisabledByCommandLine:{name:o(r.backForwardCacheDisabledByCommandLine)},NetworkRequestDatapipeDrainedAsBytesConsumer:{name:o(r.networkRequestDatapipeDrainedAsBytesConsumer)},NetworkRequestRedirected:{name:o(r.networkRequestRedirected)},NetworkRequestTimeout:{name:o(r.networkRequestTimeout)},NetworkExceedsBufferLimit:{name:o(r.networkExceedsBufferLimit)},NavigationCancelledWhileRestoring:{name:o(r.navigationCancelledWhileRestoring)},BackForwardCacheDisabledForPrerender:{name:o(r.backForwardCacheDisabledForPrerender)},UserAgentOverrideDiffers:{name:o(r.userAgentOverrideDiffers)},ForegroundCacheLimit:{name:o(r.foregroundCacheLimit)},BackForwardCacheDisabledForDelegate:{name:o(r.backForwardCacheDisabledForDelegate)},UnloadHandlerExistsInMainFrame:{name:o(r.unloadHandlerExistsInMainFrame)},UnloadHandlerExistsInSubFrame:{name:o(r.unloadHandlerExistsInSubFrame)},ServiceWorkerUnregistration:{name:o(r.serviceWorkerUnregistration)},NoResponseHead:{name:o(r.noResponseHead)},CacheControlNoStore:{name:o(r.cacheControlNoStore)},CacheControlNoStoreCookieModified:{name:o(r.cacheControlNoStore)},CacheControlNoStoreHTTPOnlyCookieModified:{name:o(r.cacheControlNoStore)},DisableForRenderFrameHostCalled:{name:o(r.ineligibleAPI)},BlocklistedFeatures:{name:o(r.ineligibleAPI)},SchedulerTrackedFeatureUsed:{name:o(r.ineligibleAPI)},DomainNotAllowed:{name:o(r.internalError)},ConflictingBrowsingInstance:{name:o(r.internalError)},NotMostRecentNavigationEntry:{name:o(r.internalError)},IgnoreEventAndEvict:{name:o(r.internalError)},BrowsingInstanceNotSwapped:{name:o(r.internalError)},ActivationNavigationsDisallowedForBug1234857:{name:o(r.internalError)},Unknown:{name:o(r.internalError)},RenderFrameHostReused_SameSite:{name:o(r.internalError)},RenderFrameHostReused_CrossSite:{name:o(r.internalError)},WebSocket:{name:o(r.webSocket)},WebTransport:{name:o(r.webTransport)},WebRTC:{name:o(r.webRTC)},MainResourceHasCacheControlNoStore:{name:o(r.mainResourceHasCacheControlNoStore)},MainResourceHasCacheControlNoCache:{name:o(r.mainResourceHasCacheControlNoCache)},SubresourceHasCacheControlNoStore:{name:o(r.subresourceHasCacheControlNoStore)},SubresourceHasCacheControlNoCache:{name:o(r.subresourceHasCacheControlNoCache)},ContainsPlugins:{name:o(r.containsPlugins)},DocumentLoaded:{name:o(r.documentLoaded)},DedicatedWorkerOrWorklet:{name:o(r.dedicatedWorkerOrWorklet)},OutstandingNetworkRequestOthers:{name:o(r.outstandingNetworkRequestOthers)},OutstandingIndexedDBTransaction:{name:o(r.outstandingIndexedDBTransaction)},RequestedNotificationsPermission:{name:o(r.requestedNotificationsPermission)},RequestedMIDIPermission:{name:o(r.requestedMIDIPermission)},RequestedAudioCapturePermission:{name:o(r.requestedAudioCapturePermission)},RequestedVideoCapturePermission:{name:o(r.requestedVideoCapturePermission)},RequestedBackForwardCacheBlockedSensors:{name:o(r.requestedBackForwardCacheBlockedSensors)},RequestedBackgroundWorkPermission:{name:o(r.requestedBackgroundWorkPermission)},BroadcastChannel:{name:o(r.broadcastChannel)},IndexedDBConnection:{name:o(r.indexedDBConnection)},WebXR:{name:o(r.webXR)},SharedWorker:{name:o(r.sharedWorker)},SharedWorkerMessage:{name:o(r.sharedWorkerMessage)},WebLocks:{name:o(r.webLocks)},WebHID:{name:o(r.webHID)},WebShare:{name:o(r.webShare)},RequestedStorageAccessGrant:{name:o(r.requestedStorageAccessGrant)},WebNfc:{name:o(r.webNfc)},OutstandingNetworkRequestFetch:{name:o(r.outstandingNetworkRequestFetch)},OutstandingNetworkRequestXHR:{name:o(r.outstandingNetworkRequestXHR)},AppBanner:{name:o(r.appBanner)},Printing:{name:o(r.printing)},WebDatabase:{name:o(r.webDatabase)},PictureInPicture:{name:o(r.pictureInPicture)},SpeechRecognizer:{name:o(r.speechRecognizer)},IdleManager:{name:o(r.idleManager)},PaymentManager:{name:o(r.paymentManager)},SpeechSynthesis:{name:o(r.speechSynthesis)},KeyboardLock:{name:o(r.keyboardLock)},WebOTPService:{name:o(r.webOTPService)},OutstandingNetworkRequestDirectSocket:{name:o(r.outstandingNetworkRequestDirectSocket)},InjectedJavascript:{name:o(r.injectedJavascript)},InjectedStyleSheet:{name:o(r.injectedStyleSheet)},Dummy:{name:o(r.internalError)},ContentDiscarded:{name:o(r.contentDiscarded)},ContentSecurityHandler:{name:o(r.contentSecurityHandler)},ContentWebAuthenticationAPI:{name:o(r.contentWebAuthenticationAPI)},ContentFileChooser:{name:o(r.contentFileChooser)},ContentSerial:{name:o(r.contentSerial)},ContentFileSystemAccess:{name:o(r.contentFileSystemAccess)},ContentMediaDevicesDispatcherHost:{name:o(r.contentMediaDevicesDispatcherHost)},ContentWebBluetooth:{name:o(r.contentWebBluetooth)},ContentWebUSB:{name:o(r.contentWebUSB)},ContentMediaSession:{name:o(r.contentMediaSession)},ContentMediaSessionService:{name:o(r.contentMediaSessionService)},ContentMediaPlay:{name:o(r.contentMediaPlay)},ContentScreenReader:{name:o(r.contentScreenReader)},EmbedderPopupBlockerTabHelper:{name:o(r.embedderPopupBlockerTabHelper)},EmbedderSafeBrowsingTriggeredPopupBlocker:{name:o(r.embedderSafeBrowsingTriggeredPopupBlocker)},EmbedderSafeBrowsingThreatDetails:{name:o(r.embedderSafeBrowsingThreatDetails)},EmbedderAppBannerManager:{name:o(r.embedderAppBannerManager)},EmbedderDomDistillerViewerSource:{name:o(r.embedderDomDistillerViewerSource)},EmbedderDomDistillerSelfDeletingRequestDelegate:{name:o(r.embedderDomDistillerSelfDeletingRequestDelegate)},EmbedderOomInterventionTabHelper:{name:o(r.embedderOomInterventionTabHelper)},EmbedderOfflinePage:{name:o(r.embedderOfflinePage)},EmbedderChromePasswordManagerClientBindCredentialManager:{name:o(r.embedderChromePasswordManagerClientBindCredentialManager)},EmbedderPermissionRequestManager:{name:o(r.embedderPermissionRequestManager)},EmbedderModalDialog:{name:o(r.embedderModalDialog)},EmbedderExtensions:{name:o(r.embedderExtensions)},EmbedderExtensionMessaging:{name:o(r.embedderExtensionMessaging)},EmbedderExtensionMessagingForOpenPort:{name:o(r.embedderExtensionMessagingForOpenPort)},EmbedderExtensionSentMessageToCachedFrame:{name:o(r.embedderExtensionSentMessageToCachedFrame)},ErrorDocument:{name:o(r.errorDocument)},FencedFramesEmbedder:{name:o(r.fencedFramesEmbedder)},KeepaliveRequest:{name:o(r.keepaliveRequest)},JsNetworkRequestReceivedCacheControlNoStoreResource:{name:o(r.jsNetworkRequestReceivedCacheControlNoStoreResource)},IndexedDBEvent:{name:o(r.indexedDBEvent)},CookieDisabled:{name:o(r.cookieDisabled)},WebRTCUsedWithCCNS:{name:o(r.webRTCUsedWithCCNS)},WebTransportUsedWithCCNS:{name:o(r.webTransportUsedWithCCNS)},WebSocketUsedWithCCNS:{name:o(r.webSocketUsedWithCCNS)},HTTPAuthRequired:{name:w.i18n.lockedLazyString("HTTPAuthRequired")},CookieFlushed:{name:w.i18n.lockedLazyString("CookieFlushed")},SmartCard:{name:w.i18n.lockedLazyString("SmartCard")},LiveMediaStreamTrack:{name:w.i18n.lockedLazyString("LiveMediaStreamTrack")},UnloadHandler:{name:w.i18n.lockedLazyString("UnloadHandler")},ParserAborted:{name:w.i18n.lockedLazyString("ParserAborted")},BroadcastChannelOnMessage:{name:w.i18n.lockedLazyString("BroadcastChannelOnMessage")},RequestedByWebViewClient:{name:w.i18n.lockedLazyString("RequestedByWebViewClient")},PostMessageByWebViewClient:{name:w.i18n.lockedLazyString("PostMessageByWebViewClient")},WebViewSettingsChanged:{name:w.i18n.lockedLazyString("WebViewSettingsChanged")},WebViewJavaScriptObjectChanged:{name:w.i18n.lockedLazyString("WebViewJavaScriptObjectChanged")},WebViewMessageListenerInjected:{name:w.i18n.lockedLazyString("WebViewMessageListenerInjected")},WebViewSafeBrowsingAllowlistChanged:{name:w.i18n.lockedLazyString("WebViewSafeBrowsingAllowlistChanged")},WebViewDocumentStartJavascriptChanged:{name:w.i18n.lockedLazyString("WebViewDocumentStartJavascriptChanged")},CacheControlNoStoreDeviceBoundSessionTerminated:{name:o(r.cacheControlNoStore)},CacheLimitPrunedOnModerateMemoryPressure:{name:w.i18n.lockedLazyString("CacheLimitPrunedOnModerateMemoryPressure")},CacheLimitPrunedOnCriticalMemoryPressure:{name:w.i18n.lockedLazyString("CacheLimitPrunedOnCriticalMemoryPressure")}};var Ye=`:host{overflow:auto}devtools-report-value{overflow:hidden}.inline-icon{vertical-align:sub}.gray-text{color:var(--sys-color-token-subtle);margin:0 0 5px 56px;display:flex;flex-direction:row;align-items:center;flex:auto;overflow-wrap:break-word;overflow:hidden;grid-column-start:span 2}.details-list{margin-left:56px;grid-column-start:span 2}.help-outline-icon{margin:0 2px}.circled-exclamation-icon{margin-right:10px;flex-shrink:0}.status{margin-right:11px;flex-shrink:0}.report-line{grid-column-start:span 2;display:flex;align-items:center;margin:0 30px;line-height:26px}.report-key{color:var(--sys-color-token-subtle);min-width:auto;overflow-wrap:break-word;align-self:start}.report-value{padding:0 6px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.link,
.devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}devtools-report-value:has(devtools-tree-outline){margin-left:var(--sys-size-7)}.cache-status-section:focus-visible{outline:0}.tree-outline li .selection{margin-left:-5px}@media (forced-colors: active){.link,
  .devtools-link{color:linktext;text-decoration-color:linktext}}
/*# sourceURL=${import.meta.resolve("./backForwardCacheView.css")} */`;var c={mainFrame:"Main Frame",backForwardCacheTitle:"Back/forward cache",unavailable:"unavailable",url:"URL",unknown:"Unknown Status",normalNavigation:"Not served from back/forward cache: to trigger back/forward cache, use Chrome\u2019s back/forward buttons, or use the test button below to automatically navigate away and back.",restoredFromBFCache:"Successfully served from back/forward cache.",pageSupportNeeded:"Actionable",testCompleted:"Back/forward cache test completed.",pageSupportNeededExplanation:"These reasons are actionable i.e. they can be cleaned up to make the page eligible for back/forward cache.",circumstantial:"Not Actionable",circumstantialExplanation:"These reasons are not actionable i.e. caching was prevented by something outside of the direct control of the page.",supportPending:"Pending Support",runTest:"Test back/forward cache",runningTest:"Running test",learnMore:"Learn more: back/forward cache eligibility",neverUseUnload:"Learn more: Never use unload handler",supportPendingExplanation:"Chrome support for these reasons is pending i.e. they will not prevent the page from being eligible for back/forward cache in a future version of Chrome.",blockingExtensionId:"Extension id: ",framesTitle:"Frames",issuesInSingleFrame:"{n, plural, =1 {# issue found in 1 frame.} other {# issues found in 1 frame.}}",issuesInMultipleFrames:"{n, plural, =1 {# issue found in {m} frames.} other {# issues found in {m} frames.}}",framesPerIssue:"{n, plural, =1 {# frame} other {# frames}}",blankURLTitle:"Blank URL [{PH1}]",filesPerIssue:"{n, plural, =1 {# file} other {# files}}"},jt=Se.i18n.registerUIStrings("panels/application/components/BackForwardCacheView.ts",c),u=Se.i18n.getLocalizedString.bind(void 0,jt),{widget:_t}=_.Widget;function Gt(t,e,a,i,n){if(!t)return p`
      <devtools-report-key>
        ${u(c.mainFrame)}
      </devtools-report-key>
      <devtools-report-value>
        ${u(c.unavailable)}
      </devtools-report-value>`;let l=i==="Running",s=Qe.ParsedURL.schemeIs(t.url,"devtools:");return p`
    ${Xt(t.backForwardCacheDetails.restoredFromCache)}
    <devtools-report-key>${u(c.url)}</devtools-report-key>
    <devtools-report-value>${t.url}</devtools-report-value>
    ${Jt(e)}
    <devtools-report-section>
      <devtools-button
        aria-label=${u(c.runTest)}
        .disabled=${l||s}
        .spinner=${l}
        .variant=${"primary"}
        @click=${n}
        jslog=${x.action("back-forward-cache.run-test").track({click:!0})}>
        ${l?p`
          ${u(c.runningTest)}`:`
          ${u(c.runTest)}
        `}
      </devtools-button>
    </devtools-report-section>
    <devtools-report-divider>
    </devtools-report-divider>
    ${Yt(t.backForwardCacheDetails.explanations,t.backForwardCacheDetails.explanationsTree,a)}
    <devtools-report-section>
      <devtools-link href="https://web.dev/bfcache/" class="link"
      jslogcontext="learn-more.eligibility">
        ${u(c.learnMore)}
      </devtools-link>
    </devtools-report-section>`}function Jt(t){if(!t||t.frameCount===0&&t.issueCount===0)return P;function e(i){return p`
      <li role="treeitem" class="text-ellipsis">
        ${i.iconName?p`
          <devtools-icon class="inline-icon extra-large" .name=${i.iconName} style="margin-bottom: -3px;">
          </devtools-icon>
        `:P}
        ${i.text}
        ${i.children?.length?p`
          <ul role="group">
            ${i.children.map(n=>e(n))}
          </ul>`:P}
      </li>`}let a="";return t.frameCount===1?a=u(c.issuesInSingleFrame,{n:t.issueCount}):a=u(c.issuesInMultipleFrames,{n:t.issueCount,m:t.frameCount}),p`
    <devtools-report-key jslog=${x.section("frames")}>${u(c.framesTitle)}</devtools-report-key>
    <devtools-report-value>
      <devtools-tree .template=${p`
        <ul role="tree">
          <li role="treeitem" class="text-ellipsis">
            ${a}
            <ul role="group">
              ${e(t.node)}
            </ul>
          </li>
        </ul>
      `}>
      </devtools-tree>
    </devtools-report-value>`}function Xt(t){switch(t){case!0:return p`
        <devtools-report-section autofocus tabindex="-1">
          <div class="status extra-large">
            <devtools-icon class="inline-icon extra-large" name="check-circle" style="color: var(--icon-checkmark-green);">
            </devtools-icon>
          </div>
          ${u(c.restoredFromBFCache)}
        </devtools-report-section>`;case!1:return p`
        <devtools-report-section autofocus tabindex="-1">
          <div class="status">
            <devtools-icon class="inline-icon extra-large" name="clear">
            </devtools-icon>
          </div>
          ${u(c.normalNavigation)}
        </devtools-report-section>`}return p`
    <devtools-report-section autofocus tabindex="-1">
      ${u(c.unknown)}
    </devtools-report-section>`}function Yt(t,e,a){if(t.length===0)return P;let i=t.filter(s=>s.type==="PageSupportNeeded"),n=t.filter(s=>s.type==="SupportPending"),l=t.filter(s=>s.type==="Circumstantial");return p`
    ${ke(u(c.pageSupportNeeded),u(c.pageSupportNeededExplanation),i,a)}
    ${ke(u(c.supportPending),u(c.supportPendingExplanation),n,a)}
    ${ke(u(c.circumstantial),u(c.circumstantialExplanation),l,a)}`}function ke(t,e,a,i){return p`
    ${a.length>0?p`
      <devtools-report-section-header>
        ${t}
        <div class="help-outline-icon">
          <devtools-icon class="inline-icon medium" name="help" title=${e}>
          </devtools-icon>
        </div>
      </devtools-report-section-header>
      ${a.map(n=>rr(n,i.get(n.reason)))}
    `:P}`}function Qt(t){if(t.reason==="EmbedderExtensionSentMessageToCachedFrame"&&t.context){let e="chrome://extensions/?id="+t.context;return p`${u(c.blockingExtensionId)}
      <devtools-link .href=${e} allow-privileged>${t.context}</devtools-link>`}return P}function Zt(t){if(t===void 0||t.length===0)return P;let e=[p`<div>${u(c.framesPerIssue,{n:t.length})}</div>`];return e.push(...t.map(a=>p`<div class="text-ellipsis" title=${a}
    jslog=${x.treeItem().track({resize:!0})}>${a}</div>`)),p`
      <div class="details-list"
      jslog=${x.tree("frames-per-issue")}>
        <devtools-expandable-list .data=${{rows:e,title:u(c.framesPerIssue,{n:t.length})}}
        jslog=${x.treeItem().track({resize:!0})}></devtools-expandable-list>
      </div>
    `}function er(t){return t.reason==="UnloadHandlerExistsInMainFrame"||t.reason==="UnloadHandlerExistsInSubFrame"?p`
        <devtools-link href="https://web.dev/bfcache/#never-use-the-unload-event" class="link"
        jslogContext=${"learn-more.never-use-unload"}>
          ${u(c.neverUseUnload)}
        </devtools-link>`:P}function tr(t){if(t===void 0||t.length===0)return P;let e=50,a=[p`<div>${u(c.filesPerIssue,{n:t.length})}</div>`];return a.push(...t.map(i=>p`
          ${_t(Ze.Linkifier.ScriptLocationLink,{sourceURL:i.url,lineNumber:i.lineNumber,options:{columnNumber:i.columnNumber,showColumnNumber:!0,maxLength:e}})}`)),p`
      <div class="details-list">
        <devtools-expandable-list .data=${{rows:a}}></devtools-expandable-list>
      </div>
    `}function rr(t,e){return p`
    <devtools-report-section>
      ${t.reason in we?p`
          <div class="circled-exclamation-icon">
            <devtools-icon class="inline-icon medium" style="color: var(--icon-warning)" name="warning">
            </devtools-icon>
          </div>
          <div>
            ${we[t.reason].name()}
            ${er(t)}
            ${Qt(t)}
          </div>`:P}
    </devtools-report-section>
    <div class="gray-text">
      ${t.reason}
    </div>
    ${tr(t.details)}
    ${Zt(e)}`}var or=(t,e,a)=>{zt(p`
    <style>${Ye}</style>
    <devtools-report .data=${{reportTitle:u(c.backForwardCacheTitle)}} jslog=${x.pane("back-forward-cache")}>

      ${Gt(t.frame,t.frameTreeData,t.reasonToFramesMap,t.screenStatus,t.navigateAwayAndBack)}
    </devtools-report>
  `,a)},ye=class extends _.Widget.Widget{#e="Result";#t=0;#r;constructor(e=or){super({useShadowDom:!0,delegatesFocus:!0}),this.#r=e}wasShown(){super.wasShown(),d.TargetManager.TargetManager.instance().addModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.PrimaryPageChanged,this.requestUpdate,this),d.TargetManager.TargetManager.instance().addModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.BackForwardCacheDetailsUpdated,this.requestUpdate,this),this.requestUpdate()}willHide(){d.TargetManager.TargetManager.instance().removeModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.PrimaryPageChanged,this.requestUpdate,this),d.TargetManager.TargetManager.instance().removeModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.BackForwardCacheDetailsUpdated,this.requestUpdate,this),super.willHide()}#o(){return d.TargetManager.TargetManager.instance().primaryPageTarget()?.model(d.ResourceTreeModel.ResourceTreeModel)||null}#i(){return this.#o()?.mainFrame||null}async performUpdate(){let e=new Map,a=this.#i(),i=a?.backForwardCacheDetails?.explanationsTree;i&&this.#d(i,{blankCount:1},e);let n=this.#c(i,{blankCount:1});n.node.iconName="frame";let l={frame:a,frameTreeData:n,reasonToFramesMap:e,screenStatus:this.#e,navigateAwayAndBack:this.#l.bind(this)};this.#r(l,void 0,this.contentElement)}#a(){d.TargetManager.TargetManager.instance().removeModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.FrameNavigated,this.#a,this),this.#e="Result",this.requestUpdate(),this.updateComplete.then(()=>{_.ARIAUtils.LiveAnnouncer.alert(u(c.testCompleted)),this.contentElement.focus()})}async#n(){d.TargetManager.TargetManager.instance().removeModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.FrameNavigated,this.#n,this),await this.#s(50)}async#s(e){let i=d.TargetManager.TargetManager.instance().primaryPageTarget()?.model(d.ResourceTreeModel.ResourceTreeModel),n=await i?.navigationHistory();!i||!n||(n.currentIndex===this.#t?window.setTimeout(this.#s.bind(this,e*2),e):(d.TargetManager.TargetManager.instance().addModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.FrameNavigated,this.#a,this),i.navigateToHistoryEntry(n.entries[n.currentIndex-1])))}async#l(){let a=d.TargetManager.TargetManager.instance().primaryPageTarget()?.model(d.ResourceTreeModel.ResourceTreeModel),i=await a?.navigationHistory();!a||!i||(this.#t=i.currentIndex,this.#e="Running",this.requestUpdate(),d.TargetManager.TargetManager.instance().addModelListener(d.ResourceTreeModel.ResourceTreeModel,d.ResourceTreeModel.Events.FrameNavigated,this.#n,this),a.navigate("chrome://terms"))}#c(e,a){if(!e)return{node:{text:""},frameCount:0,issueCount:0};let i=1,n=0,l=[],s="";e.url.length?s=e.url:(s=u(c.blankURLTitle,{PH1:a.blankCount}),a.blankCount+=1);for(let f of e.explanations){let C={text:f.reason};n+=1,l.push(C)}for(let f of e.children){let C=this.#c(f,a);C.issueCount>0&&(l.push(C.node),n+=C.issueCount,i+=C.frameCount)}let h={text:`(${n}) ${s}`};return l.length?(h={...h,children:l},h.iconName="iframe"):e.url.length||(a.blankCount-=1),{node:h,frameCount:i,issueCount:n}}#d(e,a,i){let n=e.url;n.length===0&&(n=u(c.blankURLTitle,{PH1:a.blankCount}),a.blankCount+=1),e.explanations.forEach(l=>{let s=i.get(l.reason);s===void 0?(s=[n],i.set(l.reason,s)):s.push(n)}),e.children.map(l=>{this.#d(l,a,i)})}};var ot={};$(ot,{BounceTrackingMitigationsView:()=>Ce,DEFAULT_VIEW:()=>rt,i18nString:()=>I});import"./../../../ui/components/report_view/report_view.js";import"./../../../ui/legacy/components/data_grid/data_grid.js";import"./../../../ui/kit/kit.js";import*as $e from"./../../../core/i18n/i18n.js";import*as Te from"./../../../core/sdk/sdk.js";import"./../../../ui/components/buttons/buttons.js";import*as re from"./../../../ui/legacy/legacy.js";import*as q from"./../../../ui/lit/lit.js";import*as oe from"./../../../ui/visual_logging/visual_logging.js";var tt=`devtools-data-grid{margin-top:0}.link,
.devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}@media (forced-colors: active){.link,
  .devtools-link{color:linktext;text-decoration-color:linktext}}
/*# sourceURL=${import.meta.resolve("./bounceTrackingMitigationsView.css")} */`;var{html:L}=q,M={bounceTrackingMitigationsTitle:"Bounce tracking mitigations",forceRun:"Force run",runningMitigations:"Running",stateDeletedFor:"State was deleted for the following sites:",checkingPotentialTrackers:"Checking for potential bounce tracking sites.",learnMore:"Learn more: Bounce Tracking Mitigations",noPotentialBounceTrackersIdentified:"State was not cleared for any potential bounce tracking sites. Either none were identified or third-party cookies are not blocked.",featureDisabled:"Bounce tracking mitigations are disabled."},ar=$e.i18n.registerUIStrings("panels/application/components/BounceTrackingMitigationsView.ts",M),I=$e.i18n.getLocalizedString.bind(void 0,ar),ir=t=>{let e=t.screenStatus==="Running";return L`
    <devtools-button
      aria-label=${I(M.forceRun)}
      .disabled=${e}
      .spinner=${e}
      .variant=${"primary"}
      @click=${t.runMitigations}
      jslog=${oe.action("force-run").track({click:!0})}>
      ${e?L`
        ${I(M.runningMitigations)}`:`
        ${I(M.forceRun)}
      `}
    </devtools-button>
  `},nr=t=>t.seenButtonClick?t.trackingSites.length===0?L`
      <devtools-report-section>
      ${t.screenStatus==="Running"?L`
        ${I(M.checkingPotentialTrackers)}`:`
        ${I(M.noPotentialBounceTrackersIdentified)}
      `}
      </devtools-report-section>
    `:L`
    <devtools-report-section>
      <devtools-data-grid striped inline>
        <table>
          <tr>
            <th id="sites" weight="10" sortable>
              ${I(M.stateDeletedFor)}
            </th>
          </tr>
          ${t.trackingSites.map(e=>L`
            <tr><td>${e}</td></tr>`)}
        </table>
      </devtools-data-grid>
    </devtools-report-section>
  `:q.nothing,sr=t=>t.screenStatus==="Initializing"?q.nothing:t.screenStatus==="Disabled"?L`
      <devtools-report-section>
        ${I(M.featureDisabled)}
      </devtools-report-section>
    `:L`
    <devtools-report-section>
      ${ir(t)}
    </devtools-report-section>
    ${nr(t)}
    <devtools-report-divider>
    </devtools-report-divider>
    <devtools-report-section>
      <devtools-link href="https://privacycg.github.io/nav-tracking-mitigations/#bounce-tracking-mitigations" class="link"
      jslogcontext="learn-more">
        ${I(M.learnMore)}
      </devtools-link>
    </devtools-report-section>
  `,rt=(t,e,a)=>{q.render(L`
    <style>${tt}</style>
    <style>${re.inspectorCommonStyles}</style>
    <devtools-report .data=${{reportTitle:I(M.bounceTrackingMitigationsTitle)}}
                      jslog=${oe.pane("bounce-tracking-mitigations")}>
      ${sr(t)}
    </devtools-report>
  `,a,{container:{classes:["overflow-auto"]}})},Ce=class extends re.Widget.Widget{#e=[];#t="Initializing";#r=!1;#o;constructor(e,a=rt){super(e,{useShadowDom:"pure"}),this.#o=a;let i=Te.TargetManager.TargetManager.instance().primaryPageTarget();i?i.systemInfo().invoke_getFeatureState({featureState:"DIPS"}).then(n=>{this.#t=n.featureEnabled?"Result":"Disabled",this.requestUpdate()}):this.#t="Result"}wasShown(){super.wasShown(),this.requestUpdate()}performUpdate(){this.#o({screenStatus:this.#t,trackingSites:this.#e,seenButtonClick:this.#r,runMitigations:this.#i.bind(this)},void 0,this.contentElement)}async#i(){let e=Te.TargetManager.TargetManager.instance().primaryPageTarget();if(!e)return;this.#r=!0,this.#t="Running",this.requestUpdate();let a=await e.storageAgent().invoke_runBounceTrackingMitigations();this.#e=[],a.deletedSites.forEach(i=>{this.#e.push(i)}),this.#a()}#a(){this.#t="Result",this.requestUpdate()}};var nt={};$(nt,{CrashReportContextGrid:()=>De,DEFAULT_VIEW:()=>it,i18nString:()=>J});import"./../../../ui/legacy/components/data_grid/data_grid.js";import*as xe from"./../../../core/host/host.js";import*as Pe from"./../../../core/i18n/i18n.js";import*as ae from"./../../../ui/legacy/legacy.js";import{html as at,render as lr}from"./../../../ui/lit/lit.js";var G={key:"Key",value:"Value",copyKey:"Copy key",copyValue:"Copy value"},dr=Pe.i18n.registerUIStrings("panels/application/components/CrashReportContextGrid.ts",G),J=Pe.i18n.getLocalizedString.bind(void 0,dr),it=(t,e,a)=>{lr(at`
      <style>
        :host {
          display: block;
        }

        div {
          overflow: auto;
        }

        td {
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
      </style>
      <style>${ae.inspectorCommonStyles}</style>
      <div>
        <devtools-data-grid striped inline>
          <table>
            <thead>
              <tr>
                <th id="key" weight="50">${J(G.key)}</th>
                <th id="value" weight="50">${J(G.value)}</th>
              </tr>
            </thead>
            <tbody>
              ${t.entries.map(i=>at`
                <tr class=${t.selectedKey===i.key?"selected":""}
                    @select=${()=>t.onSelect(i.key)}
                    @contextmenu=${n=>t.onContextMenu(n,i.key,i.value)}>
                  <td title=${i.key}>${i.key}</td>
                  <td title=${i.value}>${i.value}</td>
                </tr>
              `)}
            </tbody>
          </table>
        </devtools-data-grid>
      </div>
    `,a)},De=class extends ae.Widget.Widget{#e=[];#t=[];#r;#o=[];#i;constructor(e,a=it){super(e,{useShadowDom:!0}),this.#i=a}set data(e){this.#e=e.entries,this.#r=e.selectedKey,this.#o=e.filters||[],this.requestUpdate()}#a(){if(this.#o.length===0){this.#t=this.#e;return}this.#t=this.#e.filter(e=>this.#o.every(a=>{let i=a.regex;if(!i)return!0;let n=i.test(e.key)||i.test(e.value);return a.negative?!n:n}))}#n(e,a,i){let l=e.detail;l.defaultSection().appendItem(J(G.copyKey),()=>{xe.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(a)},{jslogContext:"copy-key"}),l.defaultSection().appendItem(J(G.copyValue),()=>{xe.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(i)},{jslogContext:"copy-value"})}performUpdate(){this.#a(),this.#i({entries:this.#t,selectedKey:this.#r,onSelect:e=>this.element.dispatchEvent(new CustomEvent("select",{detail:e})),onContextMenu:(e,a,i)=>this.#n(e,a,i)},void 0,this.contentElement)}};var ct={};$(ct,{DEFAULT_VIEW:()=>dt,EndpointsGrid:()=>Re,i18nString:()=>Ie});import"./../../../ui/legacy/components/data_grid/data_grid.js";import*as A from"./../../../core/i18n/i18n.js";import*as ne from"./../../../ui/legacy/legacy.js";import*as cr from"./../../../ui/lit/lit.js";import*as lt from"./../../../ui/visual_logging/visual_logging.js";var st=`@scope to (devtools-widget > *){:scope{overflow:auto;height:100%}.endpoints-container{height:100%;display:flex;flex-direction:column;width:100%}.endpoints-header{font-size:15px;background-color:var(--sys-color-surface2);padding:1px 4px;flex-shrink:0}devtools-data-grid{flex:auto}}
/*# sourceURL=${import.meta.resolve("./endpointsGrid.css")} */`;var Me={noEndpointsToDisplay:"No endpoints to display",endpointsDescription:"Here you will find the list of endpoints that receive the reports"},ur=A.i18n.registerUIStrings("panels/application/components/EndpointsGrid.ts",Me),Ie=A.i18n.getLocalizedString.bind(void 0,ur),{render:mr,html:ie}=cr,dt=(t,e,a)=>{mr(ie`
    <style>${st}</style>
    <style>${ne.inspectorCommonStyles}</style>
    <div class="endpoints-container" jslog=${lt.section("endpoints")}>
      <div class="endpoints-header">${A.i18n.lockedString("Endpoints")}</div>
      ${t.endpoints.size>0?ie`
        <devtools-data-grid striped>
         <table>
          <tr>
            <th id="origin" weight="30">${A.i18n.lockedString("Origin")}</th>
            <th id="name" weight="20">${A.i18n.lockedString("Name")}</th>
            <th id="url" weight="30">${A.i18n.lockedString("URL")}</th>
          </tr>
          ${Array.from(t.endpoints).map(([i,n])=>n.map(l=>ie`<tr>
                <td>${i}</td>
                <td>${l.groupName}</td>
                <td>${l.url}</td>
              </tr>`)).flat()}
          </table>
        </devtools-data-grid>
      `:ie`
        <div class="empty-state">
          <span class="empty-state-header">${Ie(Me.noEndpointsToDisplay)}</span>
          <span class="empty-state-description">${Ie(Me.endpointsDescription)}</span>
        </div>
      `}
    </div>
  `,a)},Re=class extends ne.Widget.Widget{endpoints=new Map;#e;constructor(e,a=dt){super(e),this.#e=a,this.requestUpdate()}performUpdate(){this.#e({endpoints:this.endpoints},void 0,this.contentElement)}};var pt={};$(pt,{PermissionsPolicySection:()=>Fe,renderIconLink:()=>Le});import"./../../../ui/kit/kit.js";import"./../../../ui/components/report_view/report_view.js";import*as Be from"./../../../core/common/common.js";import*as le from"./../../../core/i18n/i18n.js";import*as mt from"./../../../core/sdk/sdk.js";import*as gt from"./../../network/forward/forward.js";import"./../../../ui/components/buttons/buttons.js";import*as ht from"./../../../ui/legacy/legacy.js";import{html as N,nothing as X,render as gr}from"./../../../ui/lit/lit.js";import*as se from"./../../../ui/visual_logging/visual_logging.js";var ut=`@scope to (devtools-widget > *){:scope{display:contents}.text-ellipsis{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.link,
  .devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}button.link{border:none;background:none;font-family:inherit;font-size:inherit}.policies-list{padding-top:3px}.permissions-row{display:flex;line-height:22px}.permissions-row div{padding-right:5px}.feature-name{width:135px}.allowed-icon{vertical-align:sub}.block-reason{width:215px}.disabled-features-button{padding-left:var(--sys-size-3)}}
/*# sourceURL=${import.meta.resolve("./permissionsPolicySection.css")} */`;var D={showDetails:"Show details",hideDetails:"Hide details",allowedFeatures:"Allowed Features",disabledFeatures:"Disabled Features",clickToShowHeader:'Click to reveal the request whose "`Permissions-Policy`" HTTP header disables this feature.',clickToShowIframe:"Click to reveal the top-most iframe which does not allow this feature in the elements panel.",disabledByIframe:'missing in iframe "`allow`" attribute',disabledByHeader:'disabled by "`Permissions-Policy`" header',disabledByFencedFrame:"disabled inside a `fencedframe`"},hr=le.i18n.registerUIStrings("panels/application/components/PermissionsPolicySection.ts",D),R=le.i18n.getLocalizedString.bind(void 0,hr);function Le(t,e,a,i){return N`
    <devtools-button
      .iconName=${t}
      title=${e}
      aria-label=${e}
      .variant=${"icon"}
      .size=${"SMALL"}
      @click=${a}
      jslog=${se.action().track({click:!0}).context(i)}>
    </devtools-button>`}function pr(t){return t.length?N`
    <devtools-report-key>${R(D.allowedFeatures)}</devtools-report-key>
    <devtools-report-value>${t.map(({feature:e})=>e).join(", ")}</devtools-report-value>`:X}function fr(t,e,a,i,n){if(!t.length)return X;if(!e)return N`
      <devtools-report-key>${R(D.disabledFeatures)}</devtools-report-key>
      <devtools-report-value>
        ${t.map(({policy:s})=>s.feature).join(", ")}
        <devtools-button
            class="disabled-features-button"
            .variant=${"outlined"}
            @click=${a}
            jslog=${se.action("show-disabled-features-details").track({click:!0})}>
          ${R(D.showDetails)}
        </devtools-button>
      </devtools-report-value>`;let l=t.map(({policy:s,blockReason:h,linkTargetDOMNode:f,linkTargetRequest:C})=>{let fe=(()=>{switch(h){case"IframeAttribute":return R(D.disabledByIframe);case"Header":return R(D.disabledByHeader);case"InFencedFrameTree":return R(D.disabledByFencedFrame);default:return""}})();return N`
      <div class="permissions-row">
        <div>
          <devtools-icon class="allowed-icon extra-large" name="cross-circle">
          </devtools-icon>
        </div>
        <div class="feature-name text-ellipsis">${s.feature}</div>
        <div class="block-reason">${fe}</div>
        <div>
          ${f?Le("code-circle",R(D.clickToShowIframe),()=>i(f),"reveal-in-elements"):X}
          ${C?Le("arrow-up-down-circle",R(D.clickToShowHeader),()=>n(C),"reveal-in-network"):X}
        </div>
      </div>`});return N`
    <devtools-report-key>${R(D.disabledFeatures)}</devtools-report-key>
    <devtools-report-value class="policies-list">
      ${l}
      <div class="permissions-row">
        <devtools-button
            .variant=${"outlined"}
            @click=${a}
            jslog=${se.action("hide-disabled-features-details").track({click:!0})}>
          ${R(D.hideDetails)}
        </devtools-button>
      </div>
    </devtools-report-value>`}var vr=(t,e,a)=>{gr(N`
    <style>${ut}</style>
    <devtools-report-section-header>
      ${le.i18n.lockedString("Permissions Policy")}
    </devtools-report-section-header>
    ${pr(t.allowed)}
    ${t.allowed.length>0&&t.disallowed.length>0?N`<devtools-report-divider class="subsection-divider"></devtools-report-divider>`:X}
    ${fr(t.disallowed,t.showDetails,t.onToggleShowDetails,t.onRevealDOMNode,t.onRevealHeader)}
    <devtools-report-divider></devtools-report-divider>`,a)},Fe=class extends ht.Widget.Widget{#e=[];#t=!1;#r;constructor(e,a=vr){super(e,{useShadowDom:!1}),this.#r=a}set policies(e){this.#e=e,this.requestUpdate()}get policies(){return this.#e}set showDetails(e){this.#t=e,this.requestUpdate()}get showDetails(){return this.#t}#o(){this.showDetails=!this.showDetails}async#i(e){await Be.Revealer.reveal(e)}async#a(e){if(!e)return;let a=e.responseHeaderValue("permissions-policy")?"permissions-policy":"feature-policy",i=gt.UIRequestLocation.UIRequestLocation.responseHeaderMatch(e,{name:a,value:""});await Be.Revealer.reveal(i)}async performUpdate(){let e=mt.FrameManager.FrameManager.instance(),a=this.#e.sort((s,h)=>s.feature.localeCompare(h.feature)),i=a.filter(s=>s.allowed).sort((s,h)=>s.feature.localeCompare(h.feature)),n=a.filter(s=>!s.allowed).sort((s,h)=>s.feature.localeCompare(h.feature)),l=this.#t?await Promise.all(n.map(async s=>{let h=s.locator?e.getFrame(s.locator.frameId):void 0,f=s.locator?.blockReason,C=await(f==="IframeAttribute"&&h?.getOwnerDOMNodeOrDocument()||void 0),fe=h?.resourceForURL(h.url),Ht=f==="Header"&&fe?.request||void 0;return{policy:s,blockReason:f,linkTargetDOMNode:C,linkTargetRequest:Ht}})):n.map(s=>({policy:s}));this.#r({allowed:i,disallowed:l,showDetails:this.#t,onToggleShowDetails:this.#o.bind(this),onRevealDOMNode:this.#i.bind(this),onRevealHeader:this.#a.bind(this)},void 0,this.contentElement)}};var yt={};$(yt,{ProtocolHandlersView:()=>Ee});import"./../../../ui/kit/kit.js";import*as K from"./../../../core/host/host.js";import*as Ue from"./../../../core/i18n/i18n.js";import*as vt from"./../../../core/platform/platform.js";import"./../../../ui/components/buttons/buttons.js";import*as bt from"./../../../ui/components/input/input.js";import*as wt from"./../../../ui/i18n/i18n.js";import*as de from"./../../../ui/legacy/legacy.js";import{html as V,i18nTemplate as br,nothing as wr,render as kr}from"./../../../ui/lit/lit.js";import*as kt from"./../../../ui/visual_logging/visual_logging.js";var ft=`:host{display:flex;flex-direction:column}.devtools-link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px}.devtools-link:focus-visible{outline-width:unset}input.devtools-text-input[type="text"]{padding:3px 6px;margin-left:4px;margin-right:4px;width:250px;height:25px}input.devtools-text-input[type="text"]::placeholder{color:var(--sys-color-token-subtle)}.protocol-handlers-row{margin:var(--sys-size-3) 0}.inline-icon{width:16px;height:16px;&[name="check-circle"]{color:var(--icon-checkmark-green)}}@media (forced-colors: active){.devtools-link:not(.devtools-link-prevent-click){color:linktext}.devtools-link:focus-visible{background:Highlight;color:HighlightText}}
/*# sourceURL=${import.meta.resolve("./protocolHandlersView.css")} */`;var yr="https://web.dev/url-protocol-handler/",B={protocolDetected:"Found valid protocol handler registration in the {PH1}. With the app installed, test the registered protocols.",protocolNotDetected:"Define protocol handlers in the {PH1} to register your app as a handler for custom protocols when your app is installed.",needHelpReadOur:"Need help? Read {PH1}.",protocolHandlerRegistrations:"URL protocol handler registration for PWAs",manifest:"manifest",testProtocol:"Test protocol",dropdownLabel:"Select protocol handler",textboxLabel:"Query parameter or endpoint for protocol handler",textboxPlaceholder:"Enter URL"},Ae=Ue.i18n.registerUIStrings("panels/application/components/ProtocolHandlersView.ts",B),O=Ue.i18n.getLocalizedString.bind(void 0,Ae),Sr=br.bind(void 0,Ae);function Tr(t,e){let a=t.length>0?B.protocolDetected:B.protocolNotDetected;return V`
    <div class="protocol-handlers-row status">
      <devtools-icon class="inline-icon"
                     name=${t.length>0?"check-circle":"info"}>
      </devtools-icon>
      ${wt.getFormatLocalizedStringTemplate(Ae,a,{PH1:V`
        <devtools-link href=${e} jslogcontext="manifest">${O(B.manifest)}</devtools-link>
        `})}
    </div>`}function Cr(t,e,a,i,n){return t.length===0?wr:V`
    <div class="protocol-handlers-row">
      <select class="protocol-select" @change=${a}
              aria-label=${O(B.dropdownLabel)}>
        ${t.filter(l=>l.protocol).map(({protocol:l})=>V`
          <option value=${l} jslog=${kt.item(l).track({click:!0})}>
            ${l}://
          </option>`)}
      </select>
      <input .value=${e} class="devtools-text-input" type="text"
             @change=${i} aria-label=${O(B.textboxLabel)}
             placeholder=${O(B.textboxPlaceholder)} />
      <devtools-button .variant=${"primary"} @click=${n}>
        ${O(B.testProtocol)}
      </devtools-button>
    </div>`}var $r=(t,e,a)=>{kr(V`
    <style>${ft}</style>
    <style>${de.inspectorCommonStyles}</style>
    <style>${bt.textInputStyles}</style>
    ${Tr(t.protocolHandler,t.manifestLink)}
    <div class="protocol-handlers-row">
      ${Sr(B.needHelpReadOur,{PH1:V`
        <devtools-link href=${yr} class="devtools-link" autofocus jslogcontext="learn-more">
          ${O(B.protocolHandlerRegistrations)}
        </devtools-link>`})}
    </div>
    ${Cr(t.protocolHandler,t.queryInputState,t.protocolSelectHandler,t.queryInputChangeHandler,t.testProtocolClickHandler)}
  `,a,{container:{classes:["vbox"]}})},Ee=class extends de.Widget.Widget{#e=[];#t=vt.DevToolsPath.EmptyUrlString;#r="";#o="";#i;constructor(e,a=$r){super(e,{useShadowDom:!1}),this.#i=a}set protocolHandlers(e){this.#e=e,this.requestUpdate()}get protocolHandlers(){return this.#e}set manifestLink(e){let a=this.#t!==e;this.#t=e,a&&(this.#o="",this.#r=this.#e[0]?.protocol??""),this.requestUpdate()}get manifestLink(){return this.#t}#a=e=>{this.#r=e.target.value};#n=e=>{this.#o=e.target.value,this.requestUpdate()};#s=()=>{let e=`${this.#r}://${this.#o}`;K.InspectorFrontendHost.InspectorFrontendHostInstance.openInNewTab(e),K.userMetrics.actionTaken(K.UserMetrics.Action.CaptureTestProtocolClicked)};performUpdate(){this.#i({protocolHandler:this.#e,manifestLink:this.#t,queryInputState:this.#o,protocolSelectHandler:this.#a,queryInputChangeHandler:this.#n,testProtocolClickHandler:this.#s},void 0,this.contentElement)}};var Ct={};$(Ct,{DEFAULT_VIEW:()=>Tt,ReportsGrid:()=>He,i18nString:()=>W});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/components/data_grid/data_grid.js";import*as U from"./../../../core/i18n/i18n.js";import*as ce from"./../../../core/root/root.js";import*as ue from"./../../../ui/legacy/legacy.js";import*as xr from"./../../../ui/lit/lit.js";import*as St from"./../../../ui/visual_logging/visual_logging.js";var Ne=`@scope to (devtools-widget > *){:scope{overflow:auto;height:100%}.reporting-container{height:100%;display:flex;flex-direction:column;width:100%}.reporting-header{font-size:15px;background-color:var(--sys-color-surface2);padding:1px 4px;flex-shrink:0}devtools-data-grid{flex:auto}.inline-icon{vertical-align:text-bottom}}
/*# sourceURL=${import.meta.resolve("./reportsGrid.css")} */`;var H={noReportsToDisplay:"No reports to display",reportingApiDescription:"Here you will find reporting api reports that are generated by the page.",learnMore:"Learn more",status:"Status",destination:"Destination",generatedAt:"Generated at"},Dr=U.i18n.registerUIStrings("panels/application/components/ReportsGrid.ts",H),W=U.i18n.getLocalizedString.bind(void 0,Dr),{render:Pr,html:z}=xr,Mr="https://developer.chrome.com/docs/capabilities/web-apis/reporting-api",Tt=(t,e,a)=>{Pr(z`
    <style>${Ne}</style>
    <style>${ue.inspectorCommonStyles}</style>
    <div class="reporting-container" jslog=${St.section("reports")}>
      <div class="reporting-header">${U.i18n.lockedString("Reports")}</div>
      ${t.reports.length>0?z`
        <devtools-data-grid striped>
          <table>
            <tr>
              ${t.protocolMonitorExperimentEnabled?z`
                <th id="id" weight="30">${U.i18n.lockedString("ID")}</th>
              `:""}
              <th id="url" weight="30">${U.i18n.lockedString("URL")}</th>
              <th id="type" weight="20">${U.i18n.lockedString("Type")}</th>
              <th id="status" weight="20">
                <style>${Ne}</style>
                <span class="status-header">${W(H.status)}</span>
                <devtools-link href="https://web.dev/reporting-api/#report-status"
                jslogcontext="report-status">
                  <devtools-icon class="inline-icon medium" name="help" style="color: var(--icon-link);"
                  ></devtools-icon>
                </devtools-link>
              </th>
              <th id="destination" weight="20">${W(H.destination)}</th>
              <th id="timestamp" weight="20">${W(H.generatedAt)}</th>
              <th id="body" weight="20">${U.i18n.lockedString("Body")}</th>
            </tr>
            ${t.reports.map(i=>z`
              <tr @select=${()=>t.onSelect(i.id)}>
                ${t.protocolMonitorExperimentEnabled?z`<td>${i.id}</td>`:""}
                <td>${i.initiatorUrl}</td>
                <td>${i.type}</td>
                <td>${i.status}</td>
                <td>${i.destination}</td>
                <td>${new Date(i.timestamp*1e3).toLocaleString()}</td>
                <td>${JSON.stringify(i.body)}</td>
              </tr>
            `)}
          </table>
        </devtools-data-grid>
      `:z`
        <div class="empty-state">
          <span class="empty-state-header">${W(H.noReportsToDisplay)}</span>
          <div class="empty-state-description">
            <span>${W(H.reportingApiDescription)}</span>
            <devtools-link
              class="devtools-link"
              href=${Mr}
              jslogcontext="learn-more"
            >${W(H.learnMore)}</devtools-link>
          </div>
        </div>
      `}
    </div>
  `,a)},He=class extends ue.Widget.Widget{reports=[];#e=!1;#t;onReportSelected=()=>{};constructor(e,a=Tt){super(e),this.#t=a,this.#e=ce.Runtime.experiments.isEnabled(ce.ExperimentNames.ExperimentName.PROTOCOL_MONITOR),this.requestUpdate()}performUpdate(){let e={reports:this.reports,protocolMonitorExperimentEnabled:this.#e,onSelect:this.onReportSelected};this.#t(e,void 0,this.contentElement)}};var Pt={};$(Pt,{ServiceWorkerRouterView:()=>We});import*as xt from"./../../../ui/legacy/legacy.js";import{html as Dt,render as Ir}from"./../../../ui/lit/lit.js";var $t=`:host{display:block;white-space:normal;max-width:400px}.router-rules{border:1px solid var(--sys-color-divider);border-spacing:0;padding-left:10px;padding-right:10px;line-height:initial;margin-top:0;padding-bottom:12px;text-wrap:balance}.router-rule{display:flex;margin-top:12px;flex-direction:column}.rule-id{color:var(--sys-color-token-subtle)}.item{display:flex;flex-direction:column;padding-left:10px}.condition,
.source{list-style:none;display:flex;margin-top:4px;flex-direction:row}.condition > *,
.source > *{word-break:break-all;line-height:1.5em}.rule-type{flex:0 0 18%}
/*# sourceURL=${import.meta.resolve("./serviceWorkerRouterView.css")} */`;function Rr(t){return Dt`
    <li class="router-rule">
      <div class="rule-id">Rule ${t.id}</div>
      <ul class="item">
        <li class="condition">
          <div class="rule-type">Condition</div>
          <div class="rule-value">${t.condition}</div>
        </li>
        <li class="source">
          <div class="rule-type">Source</div>
          <div class="rule-value">${t.source}</div>
        </li>
      </ul>
    </li>`}var Br=(t,e,a)=>{Ir(Dt`
    <style>${$t}</style>
    <ul class="router-rules">
      ${t.rules.map(Rr)}
    </ul>`,a)},We=class extends xt.Widget.Widget{#e=[];#t;constructor(e,a=Br){super(e,{useShadowDom:!0}),this.#t=a}set rules(e){this.#e=e,this.#e.length>0&&this.requestUpdate()}get rules(){return this.#e}performUpdate(){this.#t({rules:this.#e},void 0,this.contentElement)}};var Ut={};$(Ut,{StorageBucketRevealInfo:()=>me,StorageMetadataView:()=>ge});import"./../../../ui/components/report_view/report_view.js";import"./../../../ui/kit/kit.js";import*as It from"./../../../core/common/common.js";import*as Y from"./../../../core/i18n/i18n.js";import*as Rt from"./../../../core/sdk/sdk.js";import"./../../../ui/components/buttons/buttons.js";import*as Bt from"./../../../ui/components/legacy_wrapper/legacy_wrapper.js";import*as Lt from"./../../../ui/components/render_coordinator/render_coordinator.js";import*as Ft from"./../../../ui/legacy/legacy.js";import{html as y,nothing as T,render as Lr}from"./../../../ui/lit/lit.js";import*as Et from"./../../../ui/visual_logging/visual_logging.js";var Mt=`.default-bucket{font-style:italic}
/*# sourceURL=${import.meta.resolve("./storageMetadataView.css")} */`;var m={origin:"Frame origin",topLevelSite:"Top-level site",opaque:"(opaque)",isOpaque:"Is opaque",isThirdParty:"Is third-party",yes:"Yes",no:"No",yesBecauseTopLevelIsOpaque:"Yes, because the top-level site is opaque",yesBecauseKeyIsOpaque:"Yes, because the storage key is opaque",yesBecauseOriginNotInTopLevelSite:"Yes, because the origin is outside of the top-level site",yesBecauseAncestorChainHasCrossSite:"Yes, because the ancestry chain contains a third-party origin",loading:"Loading\u2026",bucketName:"Bucket name",defaultBucket:"Default bucket",persistent:"Is persistent",durability:"Durability",quota:"Quota",expiration:"Expiration",none:"None",deleteBucket:"Delete bucket",confirmBucketDeletion:'Delete the "{PH1}" bucket?',bucketWillBeRemoved:"The selected storage bucket and contained data will be removed."},Fr=Y.i18n.registerUIStrings("panels/application/components/StorageMetadataView.ts",m),g=Y.i18n.getLocalizedString.bind(void 0,Fr),me=class{bucketInfo;constructor(e){this.bucketInfo=e}},ge=class extends Bt.LegacyWrapper.WrappableComponent{#e=this.attachShadow({mode:"open"});#t;#r=null;#o=null;#i=!1;setStorageKey(e){this.#r=Rt.StorageKeyManager.parseStorageKey(e),this.render()}setStorageBucket(e){this.#o=e,this.setStorageKey(e.bucket.storageKey)}setShowOnlyBucket(e){this.#i=e}enableStorageBucketControls(e){this.#t=e,this.#r&&this.render()}render(){return Lt.write("StorageMetadataView render",async()=>{Lr(y`
        <style>${Mt}</style>
        <devtools-report .data=${{reportTitle:this.getTitle()??g(m.loading)}}>
          ${await this.renderReportContent()}
        </devtools-report>`,this.#e,{host:this})})}getTitle(){if(!this.#r)return;let e=this.#r.origin,a=this.#o?.bucket.name||g(m.defaultBucket);return this.#t?`${a} - ${e}`:e}key(e){return y`<devtools-report-key>${e}</devtools-report-key>`}value(e){return y`<devtools-report-value>${e}</devtools-report-value>`}async renderReportContent(){if(!this.#r)return T;let e=this.#r.origin,a=!!this.#r.components.get("3"),i=!!this.#r.components.get("1"),n=!!this.#r.components.get("4"),l=this.#r.components.get("0"),s=a?g(m.yesBecauseAncestorChainHasCrossSite):i?g(m.yesBecauseKeyIsOpaque):n?g(m.yesBecauseTopLevelIsOpaque):l&&e!==l?g(m.yesBecauseOriginNotInTopLevelSite):null;return y`
        ${l&&e!==l?y`${this.key(g(m.origin))}
            ${this.value(y`<div class="text-ellipsis" title=${e}>${e}</div>`)}`:T}
        ${l||n?this.key(g(m.topLevelSite)):T}
        ${l?this.value(l):T}
        ${n?this.value(g(m.opaque)):T}
        ${s?y`
          ${this.key(g(m.isThirdParty))}${this.value(s)}`:T}
        ${i||n?this.key(g(m.isOpaque)):T}
        ${i?this.value(g(m.yes)):T}
        ${n?this.value(g(m.yesBecauseTopLevelIsOpaque)):T}
        ${this.#o?this.#a():T}
        ${this.#t?this.#s():T}`}#a(){if(!this.#o)throw new Error("Should not call #renderStorageBucketInfo if #bucket is null.");let{bucket:{name:e},persistent:a,durability:i,quota:n}=this.#o,l=!e,s=()=>l?y`<span class="default-bucket">${g(m.defaultBucket)}</span>`:this.#i?y`<devtools-link
        @click=${f=>{f.preventDefault(),It.Revealer.reveal(new me(this.#o))}}
        title=${e}
        jslog=${Et.action("storage-bucket").track({click:!0})}
      >${e}</devtools-link>`:y`${e}`;return this.#i?y`
        ${this.key(g(m.bucketName))}
        ${this.value(s())}`:y`
      ${this.key(g(m.bucketName))}
      ${this.value(s())}
      ${this.key(g(m.persistent))}
      ${this.value(g(a?m.yes:m.no))}
      ${this.key(g(m.durability))}
      ${this.value(i)}
      ${n!==0?y`
        ${this.key(g(m.quota))}
        ${this.value(Y.ByteUtilities.bytesToString(n))}
      `:T}
      ${this.key(g(m.expiration))}
      ${this.value(this.#n())}`}#n(){if(!this.#o)throw new Error("Should not call #getExpirationString if #bucket is null.");let{expiration:e}=this.#o;return e===0?g(m.none):new Date(e*1e3).toLocaleString()}#s(){return y`
    <devtools-report-divider></devtools-report-divider>
    <devtools-report-section>
      <devtools-button aria-label=${g(m.deleteBucket)}
                       .variant=${"outlined"}
                       @click=${this.#l}>
        ${g(m.deleteBucket)}
      </devtools-button>
    </devtools-report-section>`}async#l(){if(!this.#t||!this.#o)throw new Error("Should not call #deleteBucket if #storageBucketsModel or #storageBucket is null.");await Ft.UIUtils.ConfirmDialog.show(g(m.bucketWillBeRemoved),g(m.confirmBucketDeletion,{PH1:this.#o.bucket.name||""}),this,{jslogContext:"delete-bucket-confirmation"})&&this.#t.deleteBucket(this.#o.bucket)}};customElements.define("devtools-storage-metadata-view",ge);var Nt={};$(Nt,{TrustTokensView:()=>Ve,i18nString:()=>E});import"./../../../ui/kit/kit.js";import"./../../../ui/legacy/components/data_grid/data_grid.js";import*as Ke from"./../../../core/i18n/i18n.js";import*as Oe from"./../../../core/sdk/sdk.js";import"./../../../ui/components/buttons/buttons.js";import*as pe from"./../../../ui/legacy/legacy.js";import*as ze from"./../../../ui/lit/lit.js";import*as Q from"./../../../ui/visual_logging/visual_logging.js";var At=`:host{padding:20px;height:100%;display:flex}.heading{font-size:15px}devtools-data-grid{margin-top:20px;& devtools-button{width:14px;height:14px}}devtools-icon{width:14px;height:14px}.no-tt-message{margin-top:20px}
/*# sourceURL=${import.meta.resolve("./trustTokensView.css")} */`;var Er="https://developers.google.com/privacy-sandbox/protections/private-state-tokens",{html:he}=ze,F={issuer:"Issuer",storedTokenCount:"Stored token count",allStoredTrustTokensAvailableIn:"All stored private state tokens available in this browser instance.",noTrustTokens:"No private state tokens detected",trustTokensDescription:"On this page you can view all available private state tokens in the current browsing context.",deleteTrustTokens:"Delete all stored private state tokens issued by {PH1}.",trustTokens:"Private state tokens",learnMore:"Learn more"},Ur=Ke.i18n.registerUIStrings("panels/application/components/TrustTokensView.ts",F),E=Ke.i18n.getLocalizedString.bind(void 0,Ur),Ar=1e3;function Nr(t){return t.tokens.length===0?he`
        <div jslog=${Q.pane("trust-tokens")}>
          <div class="empty-state" jslog=${Q.section().context("empty-view")}>
            <div class="empty-state-header">${E(F.noTrustTokens)}</div>
            <div class="empty-state-description">
              <span>${E(F.trustTokensDescription)}</span>
              <devtools-link
                class="devtools-link"
                href=${Er}
                .jslogContext=${"learn-more"}
              >${E(F.learnMore)}</devtools-link>
            </div>
          </div>
        </div>
      `:he`
      <div jslog=${Q.pane("trust-tokens")}>
        <span class="heading">${E(F.trustTokens)}</span>
        <devtools-icon name="info" title=${E(F.allStoredTrustTokensAvailableIn)}></devtools-icon>
        <devtools-data-grid striped inline>
          <table>
            <tr>
              <th id="issuer" weight="10" sortable>${E(F.issuer)}</th>
              <th id="count" weight="5" sortable>${E(F.storedTokenCount)}</th>
              <th id="delete-button" weight="1" sortable></th>
            </tr>
            ${t.tokens.filter(e=>e.count>0).map(e=>he`
                <tr>
                  <td>${qe(e.issuerOrigin)}</td>
                  <td>${e.count}</td>
                  <td>
                    <devtools-button .iconName=${"bin"}
                                    .jslogContext=${"delete-all"}
                                    .size=${"SMALL"}
                                    .title=${E(F.deleteTrustTokens,{PH1:qe(e.issuerOrigin)})}
                                    .variant=${"icon"}
                                    @click=${()=>t.deleteClickHandler(qe(e.issuerOrigin))}></devtools-button>
                  </td>
                </tr>
              `)}
          </table>
        </devtools-data-grid>
      </div>
    `}var Hr=(t,e,a)=>{ze.render(he`
    <style>${At}</style>
    <style>${pe.inspectorCommonStyles}</style>
    ${Nr(t)}
  `,a)},Ve=class extends pe.Widget.VBox{#e=0;#t=[];#r;constructor(e,a=Hr){super(e,{useShadowDom:!0}),this.#r=a}wasShown(){super.wasShown(),this.requestUpdate(),this.#e=window.setInterval(this.requestUpdate.bind(this),Ar)}willHide(){super.willHide(),window.clearInterval(this.#e),this.#e=0}async performUpdate(){let e=Oe.TargetManager.TargetManager.instance().primaryPageTarget();if(!e)return;let{tokens:a}=await e.storageAgent().invoke_getTrustTokens();a.sort((i,n)=>i.issuerOrigin.localeCompare(n.issuerOrigin)),this.#t=a,this.#r({tokens:this.#t,deleteClickHandler:this.#o.bind(this)},void 0,this.contentElement)}#o(e){Oe.TargetManager.TargetManager.instance().primaryPageTarget()?.storageAgent().invoke_clearTrustTokens({issuerOrigin:e})}};function qe(t){return t.replace(/\/$/,"")}export{Xe as AdsView,et as BackForwardCacheView,ot as BounceTrackingMitigationsView,nt as CrashReportContextGrid,ct as EndpointsGrid,pt as PermissionsPolicySection,yt as ProtocolHandlersView,Ct as ReportsGrid,Pt as ServiceWorkerRouterView,Ut as StorageMetadataView,Nt as TrustTokensView};
//# sourceMappingURL=components.js.map
