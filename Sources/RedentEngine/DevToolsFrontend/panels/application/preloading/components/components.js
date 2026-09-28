var xt=Object.defineProperty;var x=(t,e)=>{for(var i in e)xt(t,i,{get:e[i],enumerable:!0})};var ze={};x(ze,{DEFAULT_VIEW:()=>je,MismatchedPreloadingGrid:()=>_,i18nString:()=>I});import"./../../../../ui/legacy/components/data_grid/data_grid.js";import*as ie from"./../../../../core/i18n/i18n.js";import"./../../../../core/sdk/sdk.js";import*as D from"./../../../../third_party/diff/diff.js";import*as Ve from"./../../../../ui/legacy/legacy.js";import*as Lt from"./../../../../ui/lit/lit.js";import*as g from"./../../../../core/i18n/i18n.js";import*as Be from"./../../../../core/platform/platform.js";import{assertNotNullOrUndefined as Me}from"./../../../../core/platform/platform.js";import"./../../../../core/sdk/sdk.js";import*as Ae from"./../../../../models/bindings/bindings.js";var r={PrefetchFailedIneligibleRedirect:"The prefetch was redirected, but the redirect URL is not eligible for prefetch.",PrefetchFailedInvalidRedirect:"The prefetch was redirected, but there was a problem with the redirect.",PrefetchFailedMIMENotSupported:"The prefetch failed because the response\u2019s Content-Type header was not supported.",PrefetchFailedNetError:"The prefetch failed because of a network error.",PrefetchFailedNon2XX:"The prefetch failed because of a non-2xx HTTP response status code.",PrefetchFailedNon2XXWithStatusCode:"The prefetch failed because of a non-2xx HTTP response status code ({PH1}).",PrefetchIneligibleRetryAfter:"A previous prefetch to the origin got a HTTP 503 response with an Retry-After header that has not elapsed yet.",PrefetchIsPrivacyDecoy:"The URL was not eligible to be prefetched because there was a registered service worker or cross-site cookies for that origin, but the prefetch was put on the network anyways and not used, to disguise that the user had some kind of previous relationship with the origin.",PrefetchIsStale:"Too much time elapsed between the prefetch and usage, so the prefetch was discarded.",PrefetchNotEligibleBrowserContextOffTheRecord:"The prefetch was not performed because the browser is in Incognito or Guest mode.",PrefetchNotEligibleDataSaverEnabled:"The prefetch was not performed because the operating system is in Data Saver mode.",PrefetchNotEligibleExistingProxy:"The URL is not eligible to be prefetched, because in the default network context it is configured to use a proxy server.",PrefetchNotEligibleHostIsNonUnique:"The URL was not eligible to be prefetched because its host was not unique (e.g., a non publicly routable IP address or a hostname which is not registry-controlled), but the prefetch was required to be proxied.",PrefetchNotEligibleNonDefaultStoragePartition:"The URL was not eligible to be prefetched because it uses a non-default storage partition.",PrefetchNotEligibleSameSiteCrossOriginPrefetchRequiredProxy:"The URL was not eligible to be prefetched because the default network context cannot be configured to use the prefetch proxy for a same-site cross-origin prefetch request.",PrefetchNotEligibleSchemeIsNotHttps:"The URL was not eligible to be prefetched because its scheme was not https:.",PrefetchNotEligibleUserHasCookies:"The URL was not eligible to be prefetched because it was cross-site, but the user had cookies for that origin.",PrefetchNotEligibleUserHasServiceWorker:"The URL was not eligible to be prefetched because there was a registered service worker for that origin, which is currently not supported.",PrefetchNotUsedCookiesChanged:"The prefetch was not used because it was a cross-site prefetch, and cookies were added for that URL while the prefetch was ongoing, so the prefetched response is now out-of-date.",PrefetchProxyNotAvailable:"A network error was encountered when trying to set up a connection to the prefetching proxy.",PrefetchNotUsedProbeFailed:"The prefetch was blocked by your Internet Service Provider or network administrator.",PrefetchEvictedForNewerPrefetch:"The prefetch was discarded because the initiating page has too many prefetches ongoing, and this was one of the oldest.",PrefetchEvictedAfterCandidateRemoved:"The prefetch was discarded because no speculation rule in the initating page triggers a prefetch for this URL anymore.",PrefetchNotEligibleBatterySaverEnabled:"The prefetch was not performed because the Battery Saver setting was enabled.",PrefetchNotEligiblePreloadingDisabled:"The prefetch was not performed because speculative loading was disabled.",PrefetchEvictedAfterBrowsingDataRemoved:"The prefetch was discarded because browsing data was removed.",prerenderFinalStatusLowEndDevice:"The prerender was not performed because this device does not have enough total system memory to support prerendering.",prerenderFinalStatusInvalidSchemeRedirect:"The prerendering navigation failed because it redirected to a URL whose scheme was not http: or https:.",prerenderFinalStatusInvalidSchemeNavigation:"The URL was not eligible to be prerendered because its scheme was not http: or https:.",prerenderFinalStatusNavigationRequestBlockedByCsp:"The prerendering navigation was blocked by a Content Security Policy.",prerenderFinalStatusMojoBinderPolicy:"The prerendered page used a forbidden JavaScript API that is currently not supported. (Internal Mojo interface: {PH1})",prerenderFinalStatusRendererProcessCrashed:"The prerendered page crashed.",prerenderFinalStatusRendererProcessKilled:"The prerendered page was killed.",prerenderFinalStatusDownload:"The prerendered page attempted to initiate a download, which is currently not supported.",prerenderFinalStatusNavigationBadHttpStatus:"The prerendering navigation failed because of a non-2xx HTTP response status code.",prerenderFinalStatusNavigationBadHttpStatusWithStatusCode:"The prerendering navigation failed because of a non-2xx HTTP response status code ({PH1}).",prerenderFinalStatusClientCertRequested:"The prerendering navigation required a HTTP client certificate.",prerenderFinalStatusNavigationRequestNetworkError:"The prerendering navigation encountered a network error.",prerenderFinalStatusSslCertificateError:"The prerendering navigation failed because of an invalid SSL certificate.",prerenderFinalStatusLoginAuthRequested:"The prerendering navigation required HTTP authentication, which is currently not supported.",prerenderFinalStatusUaChangeRequiresReload:"Changing User Agent occurred in prerendering navigation.",prerenderFinalStatusBlockedByClient:"Some resource load was blocked.",prerenderFinalStatusAudioOutputDeviceRequested:"The prerendered page requested audio output, which is currently not supported.",prerenderFinalStatusMixedContent:"The prerendered page contained mixed content.",prerenderFinalStatusTriggerBackgrounded:"The initiating page was backgrounded, so the prerendered page was discarded.",prerenderFinalStatusMemoryLimitExceeded:"The prerender was not performed because the browser exceeded the prerendering memory limit.",prerenderFinalStatusDataSaverEnabled:"The prerender was not performed because the user requested that the browser use less data.",prerenderFinalStatusHasEffectiveUrl:"The initiating page cannot perform prerendering, because it has an effective URL that is different from its normal URL. (For example, the New Tab Page, or hosted apps.)",prerenderFinalStatusTimeoutBackgrounded:"The initiating page was backgrounded for a long time, so the prerendered page was discarded.",prerenderFinalStatusCrossSiteRedirectInInitialNavigation:"The prerendering navigation failed because the prerendered URL redirected to a cross-site URL.",prerenderFinalStatusCrossSiteNavigationInInitialNavigation:"The prerendering navigation failed because it targeted a cross-site URL.",prerenderFinalStatusSameSiteCrossOriginRedirectNotOptInInInitialNavigation:"The prerendering navigation failed because the prerendered URL redirected to a cross-origin same-site URL, but the destination response did not include the appropriate Supports-Loading-Mode header.",prerenderFinalStatusSameSiteCrossOriginNavigationNotOptInInInitialNavigation:"The prerendering navigation failed because it was to a cross-origin same-site URL, but the destination response did not include the appropriate Supports-Loading-Mode header.",prerenderFinalStatusActivationNavigationParameterMismatch:"The prerender was not used because during activation time, different navigation parameters (e.g., HTTP headers) were calculated than during the original prerendering navigation request.",prerenderFinalStatusPrimaryMainFrameRendererProcessCrashed:"The initiating page crashed.",prerenderFinalStatusPrimaryMainFrameRendererProcessKilled:"The initiating page was killed.",prerenderFinalStatusActivationFramePolicyNotCompatible:"The prerender was not used because the sandboxing flags or permissions policy of the initiating page was not compatible with those of the prerendering page.",prerenderFinalStatusPreloadingDisabled:"The prerender was not performed because the user disabled preloading in their browser settings.",prerenderFinalStatusBatterySaverEnabled:"The prerender was not performed because the user requested that the browser use less battery.",prerenderFinalStatusActivatedDuringMainFrameNavigation:"Prerendered page activated during initiating page\u2019s main frame navigation.",prerenderFinalStatusCrossSiteRedirectInMainFrameNavigation:"The prerendered page navigated to a URL which redirected to a cross-site URL.",prerenderFinalStatusCrossSiteNavigationInMainFrameNavigation:"The prerendered page navigated to a cross-site URL.",prerenderFinalStatusSameSiteCrossOriginRedirectNotOptInInMainFrameNavigation:"The prerendered page navigated to a URL which redirected to a cross-origin same-site URL, but the destination response did not include the appropriate Supports-Loading-Mode header.",prerenderFinalStatusSameSiteCrossOriginNavigationNotOptInInMainFrameNavigation:"The prerendered page navigated to a cross-origin same-site URL, but the destination response did not include the appropriate Supports-Loading-Mode header.",prerenderFinalStatusMemoryPressureOnTrigger:"The prerender was not performed because the browser was under critical memory pressure.",prerenderFinalStatusMemoryPressureAfterTriggered:"The prerendered page was unloaded because the browser came under critical memory pressure.",prerenderFinalStatusPrerenderingDisabledByDevTools:"The prerender was not performed because DevTools has been used to disable prerendering.",prerenderFinalStatusSpeculationRuleRemoved:'The prerendered page was unloaded because the initiating page removed the corresponding prerender rule from `<script type="speculationrules">`.',prerenderFinalStatusActivatedWithAuxiliaryBrowsingContexts:"The prerender was not used because during activation time, there were other windows with an active opener reference to the initiating page, which is currently not supported.",prerenderFinalStatusMaxNumOfRunningEagerPrerendersExceeded:'The prerender whose eagerness is "`eager`" was not performed because the initiating page already has too many prerenders ongoing. Remove other speculation rules with "`eager`" to enable further prerendering.',prerenderFinalStatusMaxNumOfRunningEmbedderPrerendersExceeded:"The browser-triggered prerender was not performed because the initiating page already has too many prerenders ongoing.",prerenderFinalStatusMaxNumOfRunningNonEagerPrerendersExceeded:'The old non-eager prerender (with a "`moderate`" or "`conservative`" eagerness and triggered by hovering or clicking links) was automatically canceled due to starting a new non-eager prerender. It can be retriggered by interacting with the link again.',prerenderFinalStatusPrerenderingUrlHasEffectiveUrl:"The prerendering navigation failed because it has an effective URL that is different from its normal URL. (For example, the New Tab Page, or hosted apps.)",prerenderFinalStatusRedirectedPrerenderingUrlHasEffectiveUrl:"The prerendering navigation failed because it redirected to an effective URL that is different from its normal URL. (For example, the New Tab Page, or hosted apps.)",prerenderFinalStatusActivationUrlHasEffectiveUrl:"The prerender was not used because during activation time, navigation has an effective URL that is different from its normal URL. (For example, the New Tab Page, or hosted apps.)",prerenderFinalStatusJavaScriptInterfaceAdded:"The prerendered page was unloaded because a new JavaScript interface has been injected by WebView.addJavascriptInterface().",prerenderFinalStatusJavaScriptInterfaceRemoved:"The prerendered page was unloaded because a JavaScript interface has been removed by WebView.removeJavascriptInterface().",prerenderFinalStatusAllPrerenderingCanceled:"All prerendered pages were unloaded by the browser for some reason (For example, WebViewCompat.addWebMessageListener() was called during prerendering.)",prerenderFinalStatusWindowClosed:"The prerendered page was unloaded because it called window.close().",prerenderFinalStatusBrowsingDataRemoved:"The prerendered page was unloaded because browsing data was removed.",statusNotTriggered:"Not triggered",statusPending:"Pending",statusRunning:"Running",statusReady:"Ready",statusSuccess:"Success",statusFailure:"Failure"},He=g.i18n.registerUIStrings("panels/application/preloading/components/PreloadingString.ts",r),h=g.i18n.getLazilyComputedLocalizedString.bind(void 0,He),a=g.i18n.getLocalizedString.bind(void 0,He),l={PrefetchFailedIneligibleRedirect:{name:h(r.PrefetchFailedIneligibleRedirect)},PrefetchFailedInvalidRedirect:{name:h(r.PrefetchFailedInvalidRedirect)},PrefetchFailedMIMENotSupported:{name:h(r.PrefetchFailedMIMENotSupported)},PrefetchFailedNetError:{name:h(r.PrefetchFailedNetError)},PrefetchFailedNon2XX:{name:h(r.PrefetchFailedNon2XX)},PrefetchIneligibleRetryAfter:{name:h(r.PrefetchIneligibleRetryAfter)},PrefetchIsPrivacyDecoy:{name:h(r.PrefetchIsPrivacyDecoy)},PrefetchIsStale:{name:h(r.PrefetchIsStale)},PrefetchNotEligibleBrowserContextOffTheRecord:{name:h(r.PrefetchNotEligibleBrowserContextOffTheRecord)},PrefetchNotEligibleDataSaverEnabled:{name:h(r.PrefetchNotEligibleDataSaverEnabled)},PrefetchNotEligibleExistingProxy:{name:h(r.PrefetchNotEligibleExistingProxy)},PrefetchNotEligibleHostIsNonUnique:{name:h(r.PrefetchNotEligibleHostIsNonUnique)},PrefetchNotEligibleNonDefaultStoragePartition:{name:h(r.PrefetchNotEligibleNonDefaultStoragePartition)},PrefetchNotEligibleSameSiteCrossOriginPrefetchRequiredProxy:{name:h(r.PrefetchNotEligibleSameSiteCrossOriginPrefetchRequiredProxy)},PrefetchNotEligibleSchemeIsNotHttps:{name:h(r.PrefetchNotEligibleSchemeIsNotHttps)},PrefetchNotEligibleUserHasCookies:{name:h(r.PrefetchNotEligibleUserHasCookies)},PrefetchNotEligibleUserHasServiceWorker:{name:h(r.PrefetchNotEligibleUserHasServiceWorker)},PrefetchNotUsedCookiesChanged:{name:h(r.PrefetchNotUsedCookiesChanged)},PrefetchProxyNotAvailable:{name:h(r.PrefetchProxyNotAvailable)},PrefetchNotUsedProbeFailed:{name:h(r.PrefetchNotUsedProbeFailed)},PrefetchEvictedForNewerPrefetch:{name:h(r.PrefetchEvictedForNewerPrefetch)},PrefetchEvictedAfterCandidateRemoved:{name:h(r.PrefetchEvictedAfterCandidateRemoved)},PrefetchNotEligibleBatterySaverEnabled:{name:h(r.PrefetchNotEligibleBatterySaverEnabled)},PrefetchNotEligiblePreloadingDisabled:{name:h(r.PrefetchNotEligiblePreloadingDisabled)},PrefetchNotEligibleUserHasServiceWorkerNoFetchHandler:{name:()=>g.i18n.lockedString("Unknown")},PrefetchNotEligibleRedirectFromServiceWorker:{name:()=>g.i18n.lockedString("Unknown")},PrefetchNotEligibleRedirectToServiceWorker:{name:()=>g.i18n.lockedString("Unknown")},PrefetchEvictedAfterBrowsingDataRemoved:{name:h(r.PrefetchEvictedAfterBrowsingDataRemoved)},PrefetchNotEligibleBlockedByConnectionAllowlist:{name:()=>g.i18n.lockedString("Unknown")},PrefetchCancelledOnUserNavigation:{name:()=>g.i18n.lockedString("Unknown")},PrefetchNotEligibleCrossOrigin:{name:()=>g.i18n.lockedString("Unknown")}};function j({prefetchStatus:t},e){switch(t){case null:return null;case"PrefetchNotStarted":return null;case"PrefetchNotFinishedInTime":return null;case"PrefetchResponseUsed":return null;case"PrefetchAllowed":case"PrefetchHeldback":return null;case"PrefetchSuccessfulButNotUsed":return null;case"PrefetchFailedIneligibleRedirect":return l.PrefetchFailedIneligibleRedirect.name();case"PrefetchFailedInvalidRedirect":return l.PrefetchFailedInvalidRedirect.name();case"PrefetchFailedMIMENotSupported":return l.PrefetchFailedMIMENotSupported.name();case"PrefetchFailedNetError":return l.PrefetchFailedNetError.name();case"PrefetchFailedNon2XX":return e!==void 0?a(r.PrefetchFailedNon2XXWithStatusCode,{PH1:String(e)}):l.PrefetchFailedNon2XX.name();case"PrefetchIneligibleRetryAfter":return l.PrefetchIneligibleRetryAfter.name();case"PrefetchEvictedForNewerPrefetch":return l.PrefetchEvictedForNewerPrefetch.name();case"PrefetchEvictedAfterCandidateRemoved":return l.PrefetchEvictedAfterCandidateRemoved.name();case"PrefetchIsPrivacyDecoy":return l.PrefetchIsPrivacyDecoy.name();case"PrefetchIsStale":return l.PrefetchIsStale.name();case"PrefetchNotEligibleBrowserContextOffTheRecord":return l.PrefetchNotEligibleBrowserContextOffTheRecord.name();case"PrefetchNotEligibleDataSaverEnabled":return l.PrefetchNotEligibleDataSaverEnabled.name();case"PrefetchNotEligibleExistingProxy":return l.PrefetchNotEligibleExistingProxy.name();case"PrefetchNotEligibleHostIsNonUnique":return l.PrefetchNotEligibleHostIsNonUnique.name();case"PrefetchNotEligibleNonDefaultStoragePartition":return l.PrefetchNotEligibleNonDefaultStoragePartition.name();case"PrefetchNotEligibleSameSiteCrossOriginPrefetchRequiredProxy":return l.PrefetchNotEligibleSameSiteCrossOriginPrefetchRequiredProxy.name();case"PrefetchNotEligibleSchemeIsNotHttps":return l.PrefetchNotEligibleSchemeIsNotHttps.name();case"PrefetchNotEligibleUserHasCookies":return l.PrefetchNotEligibleUserHasCookies.name();case"PrefetchNotEligibleUserHasServiceWorker":return l.PrefetchNotEligibleUserHasServiceWorker.name();case"PrefetchNotUsedCookiesChanged":return l.PrefetchNotUsedCookiesChanged.name();case"PrefetchProxyNotAvailable":return l.PrefetchProxyNotAvailable.name();case"PrefetchNotUsedProbeFailed":return l.PrefetchNotUsedProbeFailed.name();case"PrefetchNotEligibleBatterySaverEnabled":return l.PrefetchNotEligibleBatterySaverEnabled.name();case"PrefetchNotEligiblePreloadingDisabled":return l.PrefetchNotEligiblePreloadingDisabled.name();case"PrefetchNotEligibleUserHasServiceWorkerNoFetchHandler":return l.PrefetchNotEligibleUserHasServiceWorkerNoFetchHandler.name();case"PrefetchNotEligibleRedirectFromServiceWorker":return l.PrefetchNotEligibleRedirectFromServiceWorker.name();case"PrefetchNotEligibleRedirectToServiceWorker":return l.PrefetchNotEligibleRedirectToServiceWorker.name();case"PrefetchEvictedAfterBrowsingDataRemoved":return l.PrefetchEvictedAfterBrowsingDataRemoved.name();case"PrefetchNotEligibleBlockedByConnectionAllowlist":return l.PrefetchNotEligibleBlockedByConnectionAllowlist.name();case"PrefetchCancelledOnUserNavigation":return l.PrefetchCancelledOnUserNavigation.name();case"PrefetchNotEligibleCrossOrigin":return l.PrefetchNotEligibleCrossOrigin.name();default:return g.i18n.lockedString(`Unknown failure reason: ${t}`)}}function z(t,e){switch(t.prerenderStatus){case null:case"Activated":return null;case"Destroyed":return g.i18n.lockedString("Unknown");case"LowEndDevice":return a(r.prerenderFinalStatusLowEndDevice);case"InvalidSchemeRedirect":return a(r.prerenderFinalStatusInvalidSchemeRedirect);case"InvalidSchemeNavigation":return a(r.prerenderFinalStatusInvalidSchemeNavigation);case"NavigationRequestBlockedByCsp":return a(r.prerenderFinalStatusNavigationRequestBlockedByCsp);case"MojoBinderPolicy":return Me(t.disallowedMojoInterface),a(r.prerenderFinalStatusMojoBinderPolicy,{PH1:t.disallowedMojoInterface});case"RendererProcessCrashed":return a(r.prerenderFinalStatusRendererProcessCrashed);case"RendererProcessKilled":return a(r.prerenderFinalStatusRendererProcessKilled);case"Download":return a(r.prerenderFinalStatusDownload);case"TriggerDestroyed":return g.i18n.lockedString("Internal error");case"NavigationNotCommitted":return g.i18n.lockedString("Internal error");case"NavigationBadHttpStatus":return e!==void 0?a(r.prerenderFinalStatusNavigationBadHttpStatusWithStatusCode,{PH1:String(e)}):a(r.prerenderFinalStatusNavigationBadHttpStatus);case"ClientCertRequested":return a(r.prerenderFinalStatusClientCertRequested);case"NavigationRequestNetworkError":return a(r.prerenderFinalStatusNavigationRequestNetworkError);case"CancelAllHostsForTesting":throw new Error("unreachable");case"DidFailLoad":return g.i18n.lockedString("Unknown");case"Stop":return g.i18n.lockedString("Unknown");case"SslCertificateError":return a(r.prerenderFinalStatusSslCertificateError);case"LoginAuthRequested":return a(r.prerenderFinalStatusLoginAuthRequested);case"UaChangeRequiresReload":return a(r.prerenderFinalStatusUaChangeRequiresReload);case"BlockedByClient":return a(r.prerenderFinalStatusBlockedByClient);case"AudioOutputDeviceRequested":return a(r.prerenderFinalStatusAudioOutputDeviceRequested);case"MixedContent":return a(r.prerenderFinalStatusMixedContent);case"TriggerBackgrounded":return a(r.prerenderFinalStatusTriggerBackgrounded);case"MemoryLimitExceeded":return a(r.prerenderFinalStatusMemoryLimitExceeded);case"DataSaverEnabled":return a(r.prerenderFinalStatusDataSaverEnabled);case"TriggerUrlHasEffectiveUrl":return a(r.prerenderFinalStatusHasEffectiveUrl);case"ActivatedBeforeStarted":return g.i18n.lockedString("Internal error");case"InactivePageRestriction":return g.i18n.lockedString("Internal error");case"StartFailed":return g.i18n.lockedString("Internal error");case"TimeoutBackgrounded":return a(r.prerenderFinalStatusTimeoutBackgrounded);case"CrossSiteRedirectInInitialNavigation":return a(r.prerenderFinalStatusCrossSiteRedirectInInitialNavigation);case"CrossSiteNavigationInInitialNavigation":return a(r.prerenderFinalStatusCrossSiteNavigationInInitialNavigation);case"SameSiteCrossOriginRedirectNotOptInInInitialNavigation":return a(r.prerenderFinalStatusSameSiteCrossOriginRedirectNotOptInInInitialNavigation);case"SameSiteCrossOriginNavigationNotOptInInInitialNavigation":return a(r.prerenderFinalStatusSameSiteCrossOriginNavigationNotOptInInInitialNavigation);case"ActivationNavigationParameterMismatch":return a(r.prerenderFinalStatusActivationNavigationParameterMismatch);case"ActivatedInBackground":return g.i18n.lockedString("Internal error");case"EmbedderHostDisallowed":throw new Error("unreachable");case"ActivationNavigationDestroyedBeforeSuccess":return g.i18n.lockedString("Internal error");case"TabClosedByUserGesture":throw new Error("unreachable");case"TabClosedWithoutUserGesture":throw new Error("unreachable");case"PrimaryMainFrameRendererProcessCrashed":return a(r.prerenderFinalStatusPrimaryMainFrameRendererProcessCrashed);case"PrimaryMainFrameRendererProcessKilled":return a(r.prerenderFinalStatusPrimaryMainFrameRendererProcessKilled);case"ActivationFramePolicyNotCompatible":return a(r.prerenderFinalStatusActivationFramePolicyNotCompatible);case"PreloadingDisabled":return a(r.prerenderFinalStatusPreloadingDisabled);case"BatterySaverEnabled":return a(r.prerenderFinalStatusBatterySaverEnabled);case"ActivatedDuringMainFrameNavigation":return a(r.prerenderFinalStatusActivatedDuringMainFrameNavigation);case"PreloadingUnsupportedByWebContents":throw new Error("unreachable");case"CrossSiteRedirectInMainFrameNavigation":return a(r.prerenderFinalStatusCrossSiteRedirectInMainFrameNavigation);case"CrossSiteNavigationInMainFrameNavigation":return a(r.prerenderFinalStatusCrossSiteNavigationInMainFrameNavigation);case"SameSiteCrossOriginRedirectNotOptInInMainFrameNavigation":return a(r.prerenderFinalStatusSameSiteCrossOriginRedirectNotOptInInMainFrameNavigation);case"SameSiteCrossOriginNavigationNotOptInInMainFrameNavigation":return a(r.prerenderFinalStatusSameSiteCrossOriginNavigationNotOptInInMainFrameNavigation);case"MemoryPressureOnTrigger":return a(r.prerenderFinalStatusMemoryPressureOnTrigger);case"MemoryPressureAfterTriggered":return a(r.prerenderFinalStatusMemoryPressureAfterTriggered);case"PrerenderingDisabledByDevTools":return a(r.prerenderFinalStatusPrerenderingDisabledByDevTools);case"SpeculationRuleRemoved":return a(r.prerenderFinalStatusSpeculationRuleRemoved);case"ActivatedWithAuxiliaryBrowsingContexts":return a(r.prerenderFinalStatusActivatedWithAuxiliaryBrowsingContexts);case"MaxNumOfRunningEagerPrerendersExceeded":return a(r.prerenderFinalStatusMaxNumOfRunningEagerPrerendersExceeded);case"MaxNumOfRunningEmbedderPrerendersExceeded":return a(r.prerenderFinalStatusMaxNumOfRunningEmbedderPrerendersExceeded);case"MaxNumOfRunningNonEagerPrerendersExceeded":return a(r.prerenderFinalStatusMaxNumOfRunningNonEagerPrerendersExceeded);case"PrerenderingUrlHasEffectiveUrl":return a(r.prerenderFinalStatusPrerenderingUrlHasEffectiveUrl);case"RedirectedPrerenderingUrlHasEffectiveUrl":return a(r.prerenderFinalStatusRedirectedPrerenderingUrlHasEffectiveUrl);case"ActivationUrlHasEffectiveUrl":return a(r.prerenderFinalStatusActivationUrlHasEffectiveUrl);case"JavaScriptInterfaceAdded":return a(r.prerenderFinalStatusJavaScriptInterfaceAdded);case"JavaScriptInterfaceRemoved":return a(r.prerenderFinalStatusJavaScriptInterfaceRemoved);case"AllPrerenderingCanceled":return a(r.prerenderFinalStatusAllPrerenderingCanceled);case"WindowClosed":return a(r.prerenderFinalStatusWindowClosed);case"BrowsingDataRemoved":return a(r.prerenderFinalStatusBrowsingDataRemoved);case"SlowNetwork":case"OtherPrerenderedPageActivated":case"V8OptimizerDisabled":case"PrerenderFailedDuringPrefetch":return"";default:return g.i18n.lockedString(`Unknown failure reason: ${t.prerenderStatus}`)}}function ge(t,e){let i=t.url===void 0?e:t.url;return Ae.ResourceUtils.displayNameForURL(i)}function re(t,e){return!t.errorMessage&&t.tag?'"'+t.tag+'"':ge(t,e)}function H(t){switch(t){case"Prefetch":return g.i18n.lockedString("Prefetch");case"Prerender":return g.i18n.lockedString("Prerender");case"PrerenderUntilScript":return g.i18n.lockedString("Prerender until script")}}function Oe(t){switch(t.status){case"NotSupported":return 0;case"Pending":return 1;case"Running":return 2;case"Ready":return 3;case"Success":return 4;case"Failure":switch(t.action){case"Prefetch":return 5;case"Prerender":return 6;case"PrerenderUntilScript":return 7}case"NotTriggered":return 8;default:Be.assertNever(t.status,"Unknown Preloading attempt status")}}function Dt(t){switch(t){case"NotTriggered":return a(r.statusNotTriggered);case"Pending":return a(r.statusPending);case"Running":return a(r.statusRunning);case"Ready":return a(r.statusReady);case"Success":return a(r.statusSuccess);case"Failure":return a(r.statusFailure);case"NotSupported":return g.i18n.lockedString("Internal error")}}function qe(t,e){let i=Dt(t.status);if(t.status!=="Failure")return i;switch(t.action){case"Prefetch":{let o=j(t,e)??g.i18n.lockedString("Internal error");return i+" - "+o}case"Prerender":case"PrerenderUntilScript":{let o=z(t,e);return Me(o),i+" - "+o}}}var{charDiff:$t}=D.Diff.DiffWrapper,{render:Ct,html:O,Directives:{styleMap:he}}=Lt,T={url:"URL",action:"Action",status:"Status",statusNotTriggered:"Not triggered",statusPending:"Pending",statusRunning:"Running",statusReady:"Ready",statusSuccess:"Success",statusFailure:"Failure"},Bt=ie.i18n.registerUIStrings("panels/application/preloading/components/MismatchedPreloadingGrid.ts",T),I=ie.i18n.getLocalizedString.bind(void 0,Bt),fe=class{static status(e){switch(e){case"NotTriggered":return I(T.statusNotTriggered);case"Pending":return I(T.statusPending);case"Running":return I(T.statusRunning);case"Ready":return I(T.statusReady);case"Success":return I(T.statusSuccess);case"Failure":return I(T.statusFailure);case"NotSupported":return ie.i18n.lockedString("Internal error")}}},je=(t,e,i)=>{Ct(O`
    <devtools-data-grid striped inline>
      <table>
        <tr>
          <th id="url" weight="40" sortable>
            ${I(T.url)}
          </th>
          <th id="action" weight="15" sortable>
            ${I(T.action)}
          </th>
          <th id="status" weight="15" sortable>
            ${I(T.status)}
          </th>
        </tr>
        ${t.rows.map(o=>({row:o,diffScore:D.Diff.DiffWrapper.characterScore(o.url,t.pageURL)})).sort((o,u)=>u.diffScore-o.diffScore).map(({row:o})=>O`
              <tr>
                <td>
                  <div>${$t(o.url,t.pageURL).map(u=>{let s=u[1];switch(u[0]){case D.Diff.Operation.Equal:return O`<span>${s}</span>`;case D.Diff.Operation.Insert:return O`<span style=${he({color:"var(--sys-color-green)","text-decoration":"line-through"})}
                              >${s}</span>`;case D.Diff.Operation.Delete:return O`<span style=${he({color:"var(--sys-color-error)"})}>${s}</span>`;case D.Diff.Operation.Edit:return O`<span style=${he({color:"var(--sys-color-green","text-decoration":"line-through"})}
                          >${s}</span>`;default:throw new Error("unreachable")}})}
                  </div>
                </td>
                <td>${H(o.action)}</td>
                <td>${fe.status(o.status)}</td>
              </tr>
            `)}
      </table>
    </devtools-data-grid>`,i,{container:{classes:["devtools-resources-mismatched-preloading-grid"]}})},_=class extends Ve.Widget.Widget{#t=null;#e;constructor(e,i=je){super(e,{useShadowDom:"pure"}),this.#e=i}wasShown(){super.wasShown(),this.requestUpdate()}set data(e){this.#t=e,this.requestUpdate()}performUpdate(){this.#t&&this.#e(this.#t,{},this.contentElement)}};var Ke={};x(Ke,{PreloadingDetailsReportView:()=>ve});import"./../../../../ui/components/report_view/report_view.js";import"./../../../../ui/components/request_link_icon/request_link_icon.js";import*as _e from"./../../../../core/common/common.js";import*as X from"./../../../../core/i18n/i18n.js";import{assertNotNullOrUndefined as E}from"./../../../../core/platform/platform.js";import*as K from"./../../../../core/sdk/sdk.js";import*as oe from"./../../../../models/logs/logs.js";import"./../../../../ui/components/buttons/buttons.js";import*as L from"./../../../../ui/legacy/legacy.js";import*as y from"./../../../../ui/lit/lit.js";import*as G from"./../../../../ui/visual_logging/visual_logging.js";import*as ae from"./../helper/helper.js";var me=`@scope to (devtools-widget > *){devtools-report{flex-grow:1;button.link{color:var(--sys-color-primary);text-decoration:underline;padding:0;border:none;background:none;font-family:inherit;font-size:inherit;height:16px}button.link devtools-icon{vertical-align:sub}}.link{color:var(--sys-color-primary);text-decoration:underline;cursor:pointer}}
/*# sourceURL=${import.meta.resolve("./preloadingDetailsReportView.css")} */`;var{html:R}=y,f={noElementSelected:"No element selected",selectAnElementForMoreDetails:"Select an element for more details",detailsDetailedInformation:"Detailed information",detailsAction:"Action",detailsStatus:"Status",detailsTargetHint:"Target hint",detailsFormSubmission:"Form submission",detailsFailureReason:"Failure reason",detailsRuleSet:"Rule set",yes:"Yes",no:"No",automaticallyFellBackToPrefetch:"(automatically fell back to prefetch)",detailedStatusNotTriggered:"Speculative load attempt is not yet triggered.",detailedStatusPending:"Speculative load attempt is eligible but pending.",detailedStatusRunning:"Speculative load is running.",detailedStatusReady:"Speculative load finished and the result is ready for the next navigation.",detailedStatusSuccess:"Speculative load finished and used for a navigation.",detailedStatusFailure:"Speculative load failed.",detailedStatusFallbackToPrefetch:"Speculative load failed, but fallback to prefetch succeeded.",buttonInspect:"Inspect",buttonClickToInspect:"Click to inspect prerendered page",buttonClickToRevealRuleSet:"Click to reveal rule set"},Mt=X.i18n.registerUIStrings("panels/application/preloading/components/PreloadingDetailsReportView.ts",f),m=X.i18n.getLocalizedString.bind(void 0,Mt),ne=class{static detailedStatus({status:e}){switch(e){case"NotTriggered":return m(f.detailedStatusNotTriggered);case"Pending":return m(f.detailedStatusPending);case"Running":return m(f.detailedStatusRunning);case"Ready":return m(f.detailedStatusReady);case"Success":return m(f.detailedStatusSuccess);case"Failure":return m(f.detailedStatusFailure);case"NotSupported":return X.i18n.lockedString("Internal error")}}static detailedTargetHint(e){switch(E(e.targetHint),e.targetHint){case"Blank":return"_blank";case"Self":return"_self"}}},At=(t,e,i)=>{if(t.data===null){y.render(R`
      <style>${me}</style>
      <style>${L.inspectorCommonStyles}</style>
      <div class="empty-state">
        <span class="empty-state-header">${m(f.noElementSelected)}</span>
        <span class="empty-state-description">${m(f.selectAnElementForMoreDetails)}</span>
      </div>
    `,i);return}let o=t.data.pipeline,u=t.data.pageURL,s=o.getPrerender()?.status==="Failure"&&(o.getPrefetch()?.status==="Ready"||o.getPrefetch()?.status==="Success"),n=d=>["Prerender","PrerenderUntilScript"].includes(d),S=()=>{E(t.data);let d=t.data.pipeline.getOriginallyTriggered(),b=t.data.pipeline.getPrefetch()?.status,P;if(d.action==="Prefetch"&&d.requestId!==void 0&&b!=="NotTriggered"){let{requestId:A,key:{url:V}}=d;P=R`
          <devtools-request-link-icon
            .data=${{affectedRequest:{requestId:A,url:V},requestResolver:t.data.requestResolver||new oe.RequestResolver.RequestResolver(oe.NetworkLog.NetworkLog.instance()),displayURL:!0,urlToDisplay:V}}
          >
          </devtools-request-link-icon>
      `}else P=R`
          <div class="text-ellipsis" title=${d.key.url}>${d.key.url}</div>
      `;return R`
        <devtools-report-key>${X.i18n.lockedString("URL")}</devtools-report-key>
        <devtools-report-value>
          ${P}
        </devtools-report-value>
    `},U=d=>{E(t.data);let b=t.data.pipeline.getOriginallyTriggered(),P=H(b.action),A=y.nothing;d&&(A=R`${m(f.automaticallyFellBackToPrefetch)}`);let V=y.nothing;return(()=>{if(!n(b.action)||K.TargetManager.TargetManager.instance().primaryPageTarget()===null)return;let pe=K.TargetManager.TargetManager.instance().targets().find(Ce=>Ce.targetInfo()?.subtype==="prerender"&&Ce.inspectedURL()===b.key.url),Et=pe===void 0;V=R`
          <devtools-button
            @click=${()=>{pe!==void 0&&L.Context.Context.instance().setFlavor(K.Target.Target,pe)}}
            .title=${m(f.buttonClickToInspect)}
            .size=${"SMALL"}
            .variant=${"outlined"}
            .disabled=${Et}
            jslog=${G.action("inspect-prerendered-page").track({click:!0})}
          >
            ${m(f.buttonInspect)}
          </devtools-button>
      `})(),R`
        <devtools-report-key>${m(f.detailsAction)}</devtools-report-key>
        <devtools-report-value>
          <div class="text-ellipsis" title="">
            ${P} ${A} ${V}
          </div>
        </devtools-report-value>
    `},w=d=>{E(t.data);let b=t.data.pipeline.getOriginallyTriggered(),P=d?m(f.detailedStatusFallbackToPrefetch):ne.detailedStatus(b);return R`
        <devtools-report-key>${m(f.detailsStatus)}</devtools-report-key>
        <devtools-report-value>
          ${P}
        </devtools-report-value>
    `},F=()=>{E(t.data);let d=t.data.pipeline.getOriginallyTriggered();if(d.action!=="Prefetch")return y.nothing;let b=ae.PreloadingForward.preloadStatusCode(d),P=j(d,b);return P===null?y.nothing:R`
        <devtools-report-key>${m(f.detailsFailureReason)}</devtools-report-key>
        <devtools-report-value>
          ${P}
        </devtools-report-value>
    `},te=()=>{E(t.data);let d=t.data.pipeline.getOriginallyTriggered();return n(d.action)&&d.key.targetHint!==void 0?R`
        <devtools-report-key>${m(f.detailsTargetHint)}</devtools-report-key>
        <devtools-report-value>
          ${ne.detailedTargetHint(d.key)}
        </devtools-report-value>
    `:y.nothing},kt=()=>{E(t.data);let d=t.data.pipeline.getOriginallyTriggered();return!(d.key.formSubmission!==void 0)||!n(d.action)?y.nothing:R`
        <devtools-report-key>${m(f.detailsFormSubmission)}</devtools-report-key>
        <devtools-report-value>
          ${d.key.formSubmission?m(f.yes):m(f.no)}
        </devtools-report-value>
    `},Ut=()=>{E(t.data);let d=t.data.pipeline.getOriginallyTriggered();if(!n(d.action))return y.nothing;let b=ae.PreloadingForward.preloadStatusCode(d),P=z(d,b);return P===null?y.nothing:R`
        <devtools-report-key>${m(f.detailsFailureReason)}</devtools-report-key>
        <devtools-report-value>
          ${P}
        </devtools-report-value>
    `},Tt=(d,b)=>{let P=()=>{_e.Revealer.reveal(new ae.PreloadingForward.RuleSetView(d.id))},A=ge(d,b);return R`
      <devtools-report-key>${m(f.detailsRuleSet)}</devtools-report-key>
      <devtools-report-value>
        <div class="text-ellipsis" title="">
          <button class="link" role="link"
            @click=${P}
            title=${m(f.buttonClickToRevealRuleSet)}
            style=${y.Directives.styleMap({color:"var(--sys-color-primary)","text-decoration":"underline"})}
            jslog=${G.action("reveal-rule-set").track({click:!0})}
          >
            ${A}
          </button>
        </div>
      </devtools-report-value>
    `};y.render(R`
    <style>${me}</style>
    <style>${L.inspectorCommonStyles}</style>
    <devtools-report
      .data=${{reportTitle:"Speculative Loading Attempt"}}
      jslog=${G.section("preloading-details")}>
      <devtools-report-section-header>${m(f.detailsDetailedInformation)}</devtools-report-section-header>

      ${S()}
      ${U(s)}
      ${w(s)}
      ${te()}
      ${kt()}
      ${F()}
      ${Ut()}

      ${t.data.ruleSets.map(d=>Tt(d,u))}
    </devtools-report>
  `,i)},ve=class extends L.Widget.VBox{#t=null;#e;constructor(e,i=At){super(e),this.#e=i}set data(e){this.#t=e,this.requestUpdate()}wasShown(){super.wasShown(),this.requestUpdate()}performUpdate(){let e={data:this.#t};this.#e(e,void 0,this.contentElement)}};var tt={};x(tt,{DEFAULT_VIEW:()=>et,PreloadingDisabledInfobar:()=>be});import"./../../../../ui/components/report_view/report_view.js";import"./../../../../ui/kit/kit.js";import*as Pe from"./../../../../core/i18n/i18n.js";import*as Je from"./../../../../core/platform/platform.js";import"./../../../../ui/components/buttons/buttons.js";import"./../../../../ui/components/dialogs/dialogs.js";import*as Ye from"./../../../../ui/legacy/legacy.js";import{html as Se,i18nTemplate as Ht,nothing as Ot,render as qt}from"./../../../../ui/lit/lit.js";import*as Qe from"./../../../../ui/visual_logging/visual_logging.js";var Ge=`#container{padding:6px 12px;border-bottom:1px solid var(--sys-color-divider);align-items:center;display:flex}#contents .key{grid-column-start:span 2;font-weight:bold}#contents .value{grid-column-start:span 2;margin-top:var(--sys-size-6)}#footer{margin-top:var(--sys-size-6);margin-bottom:var(--sys-size-2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;grid-column-start:span 2}devtools-link{color:var(--sys-color-primary);text-decoration-line:underline}
/*# sourceURL=${import.meta.resolve("./preloadingDisabledInfobar.css")} */`;var{urlString:Xe}=Je.DevToolsPath,v={infobarPreloadingIsDisabled:"Speculative loading is disabled",infobarPreloadingIsForceEnabled:"Speculative loading is force-enabled",titleReasonsPreventingPreloading:"Reasons preventing speculative loading",headerDisabledByPreference:"User settings or extensions",descriptionDisabledByPreference:"Speculative loading is disabled because of user settings or an extension. Go to {PH1} to update your preference. Go to {PH2} to disable any extension that blocks speculative loading.",preloadingPagesSettings:"Preload pages settings",extensionsSettings:"Extensions settings",headerDisabledByDataSaver:"Data Saver",descriptionDisabledByDataSaver:"Speculative loading is disabled because of the operating system\u2019s Data Saver mode.",headerDisabledByBatterySaver:"Battery Saver",descriptionDisabledByBatterySaver:"Speculative loading is disabled because of the operating system\u2019s Battery Saver mode.",headerDisabledByHoldbackPrefetchSpeculationRules:"Prefetch was disabled, but is force-enabled now",descriptionDisabledByHoldbackPrefetchSpeculationRules:"Prefetch is forced-enabled because DevTools is open. When DevTools is closed, prefetch will be disabled because this browser session is part of a holdback group used for performance comparisons.",headerDisabledByHoldbackPrerenderSpeculationRules:"Prerendering was disabled, but is force-enabled now",descriptionDisabledByHoldbackPrerenderSpeculationRules:"Prerendering is forced-enabled because DevTools is open. When DevTools is closed, prerendering will be disabled because this browser session is part of a holdback group used for performance comparisons.",footerLearnMore:"Learn more"},Ze=Pe.i18n.registerUIStrings("panels/application/preloading/components/PreloadingDisabledInfobar.ts",v),k=Pe.i18n.getLocalizedString.bind(void 0,Ze),Wt="https://developer.chrome.com/blog/prerender-pages/",et=(t,e,i)=>{let o=Ot;t.header!==null&&(o=Se`
        <style>${Ge}</style>
        <div id="container">
          <span id="header">${t.header}</span>
          <devtools-button-dialog .data=${{iconName:"info",variant:"icon",closeButton:!0,position:"auto",horizontalAlignment:"auto",closeOnESC:!0,closeOnScroll:!1,dialogTitle:k(v.titleReasonsPreventingPreloading)}}
                                  jslog=${Qe.dialog("preloading-disabled").track({resize:!0,keydown:"Escape"})}>
            <div id="contents">
              <devtools-report>
                ${t.warnings.map(({key:u,valueId:s,placeholders:n={}})=>{let S=Ht(Ze,s,Object.fromEntries(Object.entries(n).map(([U,{title:w,href:F}])=>[U,Se`<devtools-link href=${F}>${w}</devtools-link>`])));return Se`
                      <div class="key">${u}</div>
                      <div class="value">${S}</div>
                    `})}
              </devtools-report>
              <div id="footer">
                <devtools-link href=${Wt} jslogcontext="learn-more">
                  ${k(v.footerLearnMore)}
                </devtools-link>
              </div>
            </div>
          </devtools-button-dialog>
        </div>`),qt(o,i)},be=class extends Ye.Widget.VBox{#t;#e=!1;#r=!1;#i=!1;#a=!1;#n=!1;constructor(e=et){super({useShadowDom:!0}),this.#t=e}get disabledByPreference(){return this.#e}set disabledByPreference(e){this.#e!==e&&(this.#e=e,this.requestUpdate())}get disabledByDataSaver(){return this.#r}set disabledByDataSaver(e){this.#r!==e&&(this.#r=e,this.requestUpdate())}get disabledByBatterySaver(){return this.#i}set disabledByBatterySaver(e){this.#i!==e&&(this.#i=e,this.requestUpdate())}get disabledByHoldbackPrefetchSpeculationRules(){return this.#a}set disabledByHoldbackPrefetchSpeculationRules(e){this.#a!==e&&(this.#a=e,this.requestUpdate())}get disabledByHoldbackPrerenderSpeculationRules(){return this.#n}set disabledByHoldbackPrerenderSpeculationRules(e){this.#n!==e&&(this.#n=e,this.requestUpdate())}wasShown(){super.wasShown(),this.requestUpdate()}performUpdate(){let e=null;this.#e||this.#r||this.#i?e=k(v.infobarPreloadingIsDisabled):(this.#a||this.#n)&&(e=k(v.infobarPreloadingIsForceEnabled));let i=[];this.#e&&i.push({key:k(v.headerDisabledByPreference),valueId:v.descriptionDisabledByPreference,placeholders:{PH1:{title:k(v.preloadingPagesSettings),href:Xe`chrome://settings/performance`},PH2:{title:k(v.extensionsSettings),href:Xe`chrome://extensions`}}}),this.#r&&i.push({key:k(v.headerDisabledByDataSaver),valueId:v.descriptionDisabledByDataSaver}),this.#i&&i.push({key:k(v.headerDisabledByBatterySaver),valueId:v.descriptionDisabledByBatterySaver}),this.#a&&i.push({key:k(v.headerDisabledByHoldbackPrefetchSpeculationRules),valueId:v.descriptionDisabledByHoldbackPrefetchSpeculationRules}),this.#n&&i.push({key:k(v.headerDisabledByHoldbackPrerenderSpeculationRules),valueId:v.descriptionDisabledByHoldbackPrerenderSpeculationRules});let o={header:e,warnings:i};this.#t(o,void 0,this.contentElement)}};var dt={};x(dt,{PRELOADING_GRID_DEFAULT_VIEW:()=>st,PreloadingGrid:()=>we,i18nString:()=>Y});import"./../../../../ui/legacy/components/data_grid/data_grid.js";import"./../../../../ui/kit/kit.js";import*as at from"./../../../../core/common/common.js";import*as de from"./../../../../core/i18n/i18n.js";import*as nt from"./../../../../core/sdk/sdk.js";import*as ot from"./../../../../ui/legacy/legacy.js";import*as Vt from"./../../../../ui/lit/lit.js";var se=`@scope to (devtools-widget > *){.preloading-container{overflow:auto;height:100%;display:flex;flex-direction:column;devtools-data-grid{flex:auto}.inline-icon{vertical-align:text-bottom}}.preloading-header{font-size:15px;background-color:var(--sys-color-cdt-base-container);padding:1px 4px}.preloading-placeholder{flex-grow:1;display:flex;align-items:center;justify-content:center;font-size:13px;color:var(--sys-color-token-subtle)}}
/*# sourceURL=${import.meta.resolve("./preloadingGrid.css")} */`;var{PreloadingStatus:Cr}=nt.PreloadingModel,J={action:"Action",ruleSet:"Rule set",status:"Status",prefetchFallbackReady:"Prefetch fallback ready"},jt=de.i18n.registerUIStrings("panels/application/preloading/components/PreloadingGrid.ts",J),Y=de.i18n.getLocalizedString.bind(void 0,jt),{render:rt,html:ye,nothing:zt,Directives:{styleMap:it}}=Vt;function _t(t,e){let i=t.pipeline.getOriginallyTriggered().key.url;return e&&i.startsWith(e)?i.slice(e.length):i}var st=(t,e,i)=>{if(!t.rows||!t.pageURL){rt(zt,i);return}let{rows:o,pageURL:u}=t,s=u===""?null:new at.ParsedURL.ParsedURL(u).securityOrigin();rt(ye`
    <style>${se}</style>
    <div class="preloading-container">
      <devtools-data-grid striped>
        <table>
          <tr>
            <th id="url" weight="40" sortable>${de.i18n.lockedString("URL")}</th>
            <th id="action" weight="15" sortable>${Y(J.action)}</th>
            <th id="rule-set" weight="20" sortable>${Y(J.ruleSet)}</th>
            <th id="status" weight="40" sortable>${Y(J.status)}</th>
          </tr>
          ${o.map(n=>{let S=n.pipeline.getOriginallyTriggered(),U=n.pipeline.getPrefetch()?.status,F=n.pipeline.getPrerender()?.status==="Failure"&&(U==="Ready"||U==="Success"),te=n.pipeline.getOriginallyTriggered().status==="Failure";return ye`<tr @select=${()=>t.onSelect?.({rowId:n.id})}>
              <td title=${S.key.url}>${_t(n,s)}</td>
              <td>${H(S.action)}</td>
              <td>${n.ruleSets.length===0?"":re(n.ruleSets[0],u)}</td>
              <td data-value=${Oe(S)}>
                <div style=${it({color:F?"var(--sys-color-orange-bright)":te?"var(--sys-color-error)":"var(--sys-color-on-surface)"})}>
                  ${te||F?ye`
                    <devtools-icon
                      name=${F?"warning-filled":"cross-circle-filled"}
                      class='medium'
                      style=${it({"vertical-align":"sub"})}
                    ></devtools-icon>`:""}
                  ${F?Y(J.prefetchFallbackReady):qe(S,n.statusCode)}
                </div>
              </td>
            </tr>`})}
        </table>
      </devtools-data-grid>
    </div>
  `,i)},we=class extends ot.Widget.VBox{#t;#e;#r;#i;constructor(e){super(),this.#t=e??st,this.requestUpdate()}set rows(e){this.#e=e,this.requestUpdate()}set pageURL(e){this.#r=e,this.requestUpdate()}set onSelect(e){this.#i=e,this.requestUpdate()}performUpdate(){let e={rows:this.#e,pageURL:this.#r,onSelect:this.#i?.bind(this)};this.#t(e,void 0,this.contentElement)}};var ht={};x(ht,{DEFAULT_VIEW:()=>gt,RuleSetDetailsView:()=>Fe});import*as ke from"./../../../../core/i18n/i18n.js";import*as Re from"./../../../../core/sdk/sdk.js";import*as ut from"./../../../../models/formatter/formatter.js";import*as $ from"./../../../../third_party/codemirror.next/codemirror.next.js";import*as Ue from"./../../../../ui/components/code_highlighter/code_highlighter.js";import*as pt from"./../../../../ui/components/text_editor/text_editor.js";import*as ce from"./../../../../ui/legacy/legacy.js";import{html as le,nothing as Kt,render as Gt}from"./../../../../ui/lit/lit.js";var lt=`:host{height:100%}.placeholder{display:flex;height:100%}.ruleset-header-container{flex-shrink:0}.ruleset-header{padding:4px 8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;border-bottom:1px solid var(--sys-color-divider)}.ruleset-header devtools-icon{vertical-align:sub}.text-editor-container{overflow:auto}
/*# sourceURL=${import.meta.resolve("./RuleSetDetailsView.css")} */`;var Ne={noElementSelected:"No element selected",selectAnElementForMoreDetails:"Select an element for more details"},Xt=ke.i18n.registerUIStrings("panels/application/preloading/components/RuleSetDetailsView.ts",Ne),ct=ke.i18n.getLocalizedString.bind(void 0,Xt),Jt=await Ue.CodeHighlighter.languageFromMIME("application/json"),gt=(t,e,i)=>{Gt(le`
    <style>${lt}</style>
    <style>${ce.inspectorCommonStyles}</style>
    ${t?le`
        <div class="ruleset-header-container">
          <div class="ruleset-header" id="ruleset-url">${t.url}</div>
          ${t.errorMessage?le`
            <div class="ruleset-header">
              <devtools-icon name="cross-circle" class="medium">
              </devtools-icon>
              <span id="error-message-text">${t.errorMessage}</span>
            </div>
          `:Kt}
        </div>
        <div class="text-editor-container">
          <devtools-text-editor .state=${t.editorState}></devtools-text-editor>
        </div>`:le`
          <div class="placeholder">
            <div class="empty-state">
              <span class="empty-state-header">${ct(Ne.noElementSelected)}</span>
              <span class="empty-state-description">${ct(Ne.selectAnElementForMoreDetails)}</span>
            </div>
          </div>`}
    `,i)},Fe=class extends ce.Widget.VBox{#t;#e=null;#r=!0;constructor(e,i=gt){super(e,{useShadowDom:!0}),this.#t=i}wasShown(){super.wasShown(),this.requestUpdate()}set ruleSet(e){this.#e=e,this.requestUpdate()}set shouldPrettyPrint(e){this.#r=e,this.requestUpdate()}async performUpdate(){if(!this.#e){this.#t(null,{},this.contentElement);return}let e=await this.#i(),i=$.EditorState.create({doc:e,extensions:[pt.Config.baseConfiguration(e),$.lineNumbers(),$.EditorState.readOnly.of(!0),Jt,$.syntaxHighlighting(Ue.CodeHighlighter.highlightStyle)]});this.#t({url:this.#e.url||Re.TargetManager.TargetManager.instance().inspectedURL(),errorMessage:this.#e.errorMessage,editorState:i,sourceText:e},{},this.contentElement)}async#i(){return this.#r&&this.#e?.sourceText!==void 0?(await ut.ScriptFormatter.formatScriptContent(Re.TargetManager.TargetManager.instance().settings,"application/json",this.#e.sourceText)).formattedContent:this.#e?.sourceText||""}};var yt={};x(yt,{DEFAULT_VIEW:()=>Pt,RuleSetGrid:()=>Te,i18nString:()=>B});import"./../../../../ui/legacy/components/data_grid/data_grid.js";import"./../../../../ui/kit/kit.js";import*as q from"./../../../../core/common/common.js";import*as Ie from"./../../../../core/i18n/i18n.js";import{assertNotNullOrUndefined as mt}from"./../../../../core/platform/platform.js";import*as M from"./../../../../core/sdk/sdk.js";import*as vt from"./../../../../ui/legacy/legacy.js";import{Directives as Yt,html as Q,nothing as Qt,render as Zt}from"./../../../../ui/lit/lit.js";import*as Z from"./../../../../ui/visual_logging/visual_logging.js";import*as St from"./../../../network/forward/forward.js";import*as bt from"./../helper/helper.js";var ft=`:host{overflow:auto;height:100%}.ruleset-container{height:100%;display:flex;flex-direction:column}devtools-data-grid{flex:auto}.inline-icon{vertical-align:text-bottom}
/*# sourceURL=${import.meta.resolve("./ruleSetGrid.css")} */`;var{styleMap:ue}=Yt,C={ruleSet:"Rule set",status:"Status",clickToOpenInElementsPanel:"Click to open in Elements panel",clickToOpenInNetworkPanel:"Click to open in Network panel",errors:"{errorCount, plural, =1 {# error} other {# errors}}",buttonRevealPreloadsAssociatedWithRuleSet:"Reveal speculative loads associated with this rule set"},er=Ie.i18n.registerUIStrings("panels/application/preloading/components/RuleSetGrid.ts",C),B=Ie.i18n.getLocalizedString.bind(void 0,er),Pt=(t,e,i)=>{let o=Qt;if(t.data!==null){let{rows:u,pageURL:s}=t.data;o=Q`
          <style>${ft}</style>
          <div class="ruleset-container" jslog=${Z.pane("preloading-rules")}>
            <devtools-data-grid striped>
              <table>
                <tr>
                  <th id="rule-set" weight="20" sortable>
                    ${B(C.ruleSet)}
                  </th>
                  <th id="status" weight="80" sortable>
                    ${B(C.status)}
                  </th>
                </tr>
                ${u.map(({ruleSet:n,preloadsStatusSummary:S})=>{let U=re(n,s),w=n.backendNodeId!==void 0,F=n.url!==void 0&&n.requestId;return Q`
                    <tr @select=${()=>t.onSelect(n.id)}>
                      <td>
                        ${w||F?Q`
                          <button class="link" role="link"
                              @click=${()=>{w?t.onRevealInElements(n):t.onRevealInNetwork(n)}}
                              title=${B(w?C.clickToOpenInElementsPanel:C.clickToOpenInNetworkPanel)}
                              style=${ue({border:"none",background:"none",color:"var(--icon-link)",cursor:"pointer","text-decoration":"underline","padding-inline-start":"0","padding-inline-end":"0"})}
                              jslog=${Z.action(w?"reveal-in-elements":"reveal-in-network").track({click:!0})}
                            >
                              <devtools-icon name=${w?"code-circle":"arrow-up-down-circle"} class="medium"
                                style=${ue({color:"var(--icon-link)","vertical-align":"sub"})}
                              ></devtools-icon>
                              ${U}
                            </button>`:U}
                    </td>
                    <td>
                      ${n.errorType!==void 0?Q`
                        <span style=${ue({color:"var(--sys-color-error)"})}>
                          ${B(C.errors,{errorCount:1})}
                        </span>`:""} ${n.errorType!=="SourceIsNotJsonObject"&&n.errorType!=="InvalidRulesetLevelTag"?Q`
                        <button class="link" role="link"
                          @click=${()=>t.onRevealPreloadsAssociatedWithRuleSet(n)}
                          title=${B(C.buttonRevealPreloadsAssociatedWithRuleSet)}
                          style=${ue({color:"var(--sys-color-primary)","text-decoration":"underline",cursor:"pointer",border:"none",background:"none","padding-inline-start":"0","padding-inline-end":"0"})}
                          jslog=${Z.action("reveal-preloads").track({click:!0})}>
                          ${S}
                        </button>`:""}
                    </td>
                  </tr>
                `})}
              </table>
            </devtools-data-grid>
          </div>`}Zt(o,i)},Te=class extends q.ObjectWrapper.eventMixin(vt.Widget.VBox){#t;#e=null;constructor(e=Pt){super({useShadowDom:!0}),this.#t=e}get data(){return this.#e}set data(e){this.#e=e,this.requestUpdate()}performUpdate(){let e={data:this.#e,onSelect:this.dispatchEventToListeners.bind(this,"select"),onRevealInElements:this.#r.bind(this),onRevealInNetwork:this.#i.bind(this),onRevealPreloadsAssociatedWithRuleSet:this.#a.bind(this)};this.#t(e,void 0,this.contentElement)}#r(e){mt(e.backendNodeId);let i=M.TargetManager.TargetManager.instance().scopeTarget();i!==null&&q.Revealer.reveal(new M.DOMModel.DeferredDOMNode(i,e.backendNodeId))}#i(e){mt(e.requestId);let i=M.TargetManager.TargetManager.instance().scopeTarget()?.model(M.NetworkManager.NetworkManager)?.requestForId(e.requestId)||null;if(i===null)return;let o=St.UIRequestLocation.UIRequestLocation.tab(i,"preview",{clearFilter:!1});q.Revealer.reveal(o)}#a(e){q.Revealer.reveal(new bt.PreloadingForward.AttemptViewWithFilter(e.id))}};var Ft={};x(Ft,{UsedPreloadingView:()=>De});import"./../../../../ui/kit/kit.js";import"./../../../../ui/components/report_view/report_view.js";import*as W from"./../../../../core/common/common.js";import*as Le from"./../../../../core/i18n/i18n.js";import{assertNotNullOrUndefined as Rt}from"./../../../../core/platform/platform.js";import"./../../../../core/sdk/sdk.js";import*as $e from"./../../../../ui/legacy/legacy.js";import{html as N,nothing as Ee,render as tr}from"./../../../../ui/lit/lit.js";import*as ee from"./../../../../ui/visual_logging/visual_logging.js";import*as xe from"./../helper/helper.js";var wt=`:host{overflow:auto;height:100%}button{font-size:inherit}devtools-report{padding:1em 0}devtools-report-section-header{padding-bottom:0;margin-bottom:-1.5em}devtools-report-section{min-width:fit-content}devtools-report-divider{margin:1em 0}.reveal-links{white-space:nowrap}.link{border:none;background:none;color:var(--sys-color-primary);text-decoration:underline;cursor:pointer;outline-offset:2px;padding:0}.status-badge-container{white-space:nowrap;margin:8px 0 24px}.status-badge-container span{margin-right:2px}.status-badge{border-radius:4px;padding:4px;devtools-icon{width:16px;height:16px}}.status-badge-success{background:var(--sys-color-surface-green)}.status-badge-failure{background:var(--sys-color-error-container)}.status-badge-neutral{background:var(--sys-color-neutral-container)}
/*# sourceURL=${import.meta.resolve("./usedPreloadingView.css")} */`;var c={speculativeLoadingStatusForThisPage:"Speculative loading status for this page",detailsFailureReason:"Failure reason",downgradedPrefetchUsed:"The initiating page attempted to prerender this page\u2019s URL. The prerender failed, but the resulting response body was still used as a prefetch.",prefetchUsed:"This page was successfully prefetched.",prerenderUsed:"This page was successfully prerendered.",prefetchFailed:"The initiating page attempted to prefetch this page\u2019s URL, but the prefetch failed, so a full navigation was performed instead.",prerenderFailed:"The initiating page attempted to prerender this page\u2019s URL, but the prerender failed, so a full navigation was performed instead.",noPreloads:"The initiating page did not attempt to speculatively load this page\u2019s URL.",currentURL:"Current URL",preloadedURLs:"URLs being speculatively loaded by the initiating page",speculationsInitiatedByThisPage:"Speculations initiated by this page",viewAllRules:"View all speculation rules",viewAllSpeculations:"View all speculations",learnMore:"Learn more: Speculative loading on developer.chrome.com",mismatchedHeadersDetail:"Mismatched HTTP request headers",badgeSuccess:"Success",badgeFailure:"Failure",badgeNoSpeculativeLoads:"No speculative loads",badgeNotTriggeredWithCount:"{n, plural, =1 {# not triggered} other {# not triggered}}",badgeInProgressWithCount:"{n, plural, =1 {# in progress} other {# in progress}}",badgeSuccessWithCount:"{n, plural, =1 {# success} other {# success}}",badgeFailureWithCount:"{n, plural, =1 {# failure} other {# failures}}",headerName:"Header name",initialNavigationValue:"Value in initial navigation",activationNavigationValue:"Value in activation navigation",missing:"(missing)"},rr=Le.i18n.registerUIStrings("panels/application/preloading/components/UsedPreloadingView.ts",c),p=Le.i18n.getLocalizedString.bind(void 0,rr),{widget:ir}=$e.Widget;function ar({kind:t,prefetch:e,prerenderLike:i,mismatchedData:o,attemptWithMismatchedHeaders:u}){let s,n;switch(t){case"DowngradedPrerenderToPrefetchAndUsed":s={type:"success"},n=N`${p(c.downgradedPrefetchUsed)}`;break;case"PrefetchUsed":s={type:"success"},n=N`${p(c.prefetchUsed)}`;break;case"PrerenderUsed":s={type:"success"},n=N`${p(c.prerenderUsed)}`;break;case"PrefetchFailed":s={type:"failure"},n=N`${p(c.prefetchFailed)}`;break;case"PrerenderFailed":s={type:"failure"},n=N`${p(c.prerenderFailed)}`;break;case"NoPreloads":s={type:"neutral",message:p(c.badgeNoSpeculativeLoads)},n=N`${p(c.noPreloads)}`;break}let S;return t==="PrefetchFailed"?(Rt(e),S=j(e)):(t==="PrerenderFailed"||t==="DowngradedPrerenderToPrefetchAndUsed")&&(Rt(i),S=z(i)),N`
    <devtools-report-section-header>
      ${p(c.speculativeLoadingStatusForThisPage)}
    </devtools-report-section-header>
    <devtools-report-section>
      <div>
        <div class="status-badge-container">
          ${Nt(s)}
        </div>
        <div>
          ${n}
        </div>
      </div>
    </devtools-report-section>

    ${S!==void 0?N`
      <devtools-report-section-header>
        ${p(c.detailsFailureReason)}
      </devtools-report-section-header>
      <devtools-report-section>
        ${S}
      </devtools-report-section>`:Ee}

    ${o?nr(o):Ee}
    ${u?or(u):Ee}`}function nr(t){return N`
    <devtools-report-section-header>
      ${p(c.currentURL)}
    </devtools-report-section-header>
    <devtools-report-section>
      <devtools-link
        class="link devtools-link"
        href=${t.pageURL}
        jslogcontext="current-url"
      >${t.pageURL}</devtools-link>
    </devtools-report-section>

    <devtools-report-section-header>
      ${p(c.preloadedURLs)}
    </devtools-report-section-header>
    <devtools-report-section jslog=${ee.section("preloaded-urls")}>
      ${ir(_,{data:t})}
    </devtools-report-section>`}function or(t){return N`
    <devtools-report-section-header>
      ${p(c.mismatchedHeadersDetail)}
    </devtools-report-section-header>
    <devtools-report-section>
      <style>${se}</style>
      <div class="preloading-container">
        <devtools-data-grid striped inline>
          <table>
            <tr>
              <th id="header-name" weight="30" sortable>
                ${p(c.headerName)}
              </th>
              <th id="initial-value" weight="30" sortable>
                ${p(c.initialNavigationValue)}
              </th>
              <th id="activation-value" weight="30" sortable>
                ${p(c.activationNavigationValue)}
              </th>
            </tr>
            ${(t.mismatchedHeaders??[]).map(e=>N`
              <tr>
                <td>${e.headerName}</td>
                <td>${e.initialValue??p(c.missing)}</td>
                <td>${e.activationValue??p(c.missing)}</td>
              </tr>
            `)}
          </table>
        </devtools-data-grid>
      </div>
    </devtools-report-section>`}function sr({badges:t,revealRuleSetView:e,revealAttemptViewWithFilter:i}){return N`
    <devtools-report-section-header>
      ${p(c.speculationsInitiatedByThisPage)}
    </devtools-report-section-header>
    <devtools-report-section>
      <div>
        <div class="status-badge-container">
          ${t.map(Nt)}
        </div>

        <div class="reveal-links">
          <button class="link devtools-link" @click=${e}
              jslog=${ee.action("view-all-rules").track({click:!0})}>
            ${p(c.viewAllRules)}
          </button>
         ・
          <button class="link devtools-link" @click=${i}
              jslog=${ee.action("view-all-speculations").track({click:!0})}>
           ${p(c.viewAllSpeculations)}
          </button>
        </div>
      </div>
    </devtools-report-section>`}function Nt(t){let e=(i,o,u)=>N`
      <span class=${i}>
        <devtools-icon name=${o}></devtools-icon>
        <span>
          ${u}
        </span>
      </span>
    `;switch(t.type){case"success":{let i;return t.count===void 0?i=p(c.badgeSuccess):i=p(c.badgeSuccessWithCount,{n:t.count}),e("status-badge status-badge-success","check-circle",i)}case"failure":{let i;return t.count===void 0?i=p(c.badgeFailure):i=p(c.badgeFailureWithCount,{n:t.count}),e("status-badge status-badge-failure","cross-circle",i)}case"neutral":return e("status-badge status-badge-neutral","clear",t.message)}}var dr=(t,e,i)=>{tr(N`
    <style>${wt}</style>
    <devtools-report>
      ${ar(t.speculativeLoadingStatusData)}

      <devtools-report-divider></devtools-report-divider>

      ${sr(t.speculationsInitiatedSummaryData)}

      <devtools-report-divider></devtools-report-divider>

      <devtools-report-section>
        <devtools-link
          class="link devtools-link"
          href=${"https://developer.chrome.com/blog/prerender-pages/"}
          jslogcontext="learn-more"
        >${p(c.learnMore)}</devtools-link>
      </devtools-report-section>
    </devtools-report>`,i)},De=class extends $e.Widget.VBox{#t;constructor(e=dr){super({useShadowDom:!0}),this.#t=e}#e={pageURL:"",previousAttempts:[],currentAttempts:[]};set data(e){this.#e=e,this.requestUpdate()}performUpdate(){let e={speculativeLoadingStatusData:this.#a(),speculationsInitiatedSummaryData:this.#s()};this.#t(e,void 0,this.contentElement)}#r(e){return["Prerender","PrerenderUntilScript"].includes(e)}#i(e){return this.#r(e.action)}#a(){let e=W.ParsedURL.ParsedURL.urlWithoutHash(this.#e.pageURL),i=this.#e.previousAttempts.filter(n=>W.ParsedURL.ParsedURL.urlWithoutHash(n.key.url)===e),o=i.filter(n=>n.key.action==="Prefetch")[0],u=i.filter(n=>this.#r(n.action))[0],s="NoPreloads";return u?.status==="Failure"&&o?.status==="Success"?s="DowngradedPrerenderToPrefetchAndUsed":u?.status==="Success"?s="PrerenderUsed":o?.status==="Success"?s="PrefetchUsed":u?.status==="Failure"?s="PrerenderFailed":o?.status==="Failure"?s="PrefetchFailed":s="NoPreloads",{kind:s,prefetch:o,prerenderLike:u,mismatchedData:this.#n(s),attemptWithMismatchedHeaders:this.#o()}}#n(e){if(e!=="NoPreloads"||this.#e.previousAttempts.length===0)return;let i=this.#e.previousAttempts.map(o=>({url:o.key.url,action:o.key.action,status:o.status}));return{pageURL:this.#e.pageURL,rows:i}}#o(){let e=this.#e.previousAttempts.find(i=>this.#i(i)&&i.mismatchedHeaders!==null);if(e?.mismatchedHeaders){if(e.key.url!==this.#e.pageURL)throw new Error("unreachable");return e}}#s(){let e=this.#e.currentAttempts.reduce((w,F)=>(w.set(F.status,(w.get(F.status)??0)+1),w),new Map),i=e.get("NotTriggered")??0,o=e.get("Ready")??0,u=e.get("Failure")??0,s=(e.get("Pending")??0)+(e.get("Running")??0),n=[];return this.#e.currentAttempts.length===0&&n.push({type:"neutral",message:p(c.badgeNoSpeculativeLoads)}),i>0&&n.push({type:"neutral",message:p(c.badgeNotTriggeredWithCount,{n:i})}),s>0&&n.push({type:"neutral",message:p(c.badgeInProgressWithCount,{n:s})}),o>0&&n.push({type:"success",count:o}),u>0&&n.push({type:"failure",count:u}),{badges:n,revealRuleSetView:()=>{W.Revealer.reveal(new xe.PreloadingForward.RuleSetView(null))},revealAttemptViewWithFilter:()=>{W.Revealer.reveal(new xe.PreloadingForward.AttemptViewWithFilter(null))}}}};export{ze as MismatchedPreloadingGrid,Ke as PreloadingDetailsReportView,tt as PreloadingDisabledInfobar,dt as PreloadingGrid,ht as RuleSetDetailsView,yt as RuleSetGrid,Ft as UsedPreloadingView};
//# sourceMappingURL=components.js.map
