// Redent Quiet mode. Runs in the isolated "redent" world of every frame from
// document start. Declines cookie banners by pressing the site's own reject
// control, and stops media that starts making sound before the user has
// touched the page. It never presses an accept or agree control: a banner it
// cannot decline stays for the user to answer.
(function () {
  'use strict';
  try {
    if (window.__redentQuiet) return;
    window.__redentQuiet = true;
    var BRIDGE = 'redentBridge';
    var MEDIA_HOSTS = __REDENT_MEDIA_HOSTS__;
    var RELAY = '__REDENT_QUIET_RELAY__';
    // A frame asks its parent once, as it starts: a click on a "play" facade
    // that then builds the player's iframe is the user asking for sound.
    var HANDSHAKE_MS = 3000;
    // Banners arrive late, but a page still mutating a minute in is a feed,
    // not a consent flow.
    var SEARCH_WINDOW_MS = 20000;

    // Consent platforms' own reject or "necessary only" controls.
    var REJECT_SELECTORS = [
      '#onetrust-reject-all-handler',
      '#CybotCookiebotDialogBodyButtonDecline',
      '#CybotCookiebotDialogBodyLevelButtonLevelOptinDeclineAll',
      '#didomi-notice-disagree-button',
      '.iubenda-cs-reject-btn',
      '#truste-consent-required',
      '[data-testid="uc-deny-all-button"]',
      '.cky-btn-reject',
      '.cmplz-deny',
      '.klaro .cn-decline',
      '#axeptio_btn_dismiss',
      '.fc-cta-do-not-consent',
      '.osano-cm-denyAll',
      '#cookiescript_reject',
      '.cc-window .cc-deny',
      '#tarteaucitronAllDenied2',
      '.moove-gdpr-infobar-reject-btn',
      '#wt-cli-reject-btn',
      '#cookie_action_close_header_reject',
      '.sp_choice_type_REJECT_ALL',
      '#sp-cc-rejectall-link'
    ];

    // Whole-label matches only, so "Reject" inside "Manage preferences" or an
    // "Accept all" button can never qualify.
    var REJECT_LABELS = [
      'reject', 'reject all', 'reject all cookies', 'reject cookies', 'reject optional cookies',
      'decline', 'decline all', 'decline cookies', 'deny', 'deny all', 'refuse', 'refuse all',
      'necessary only', 'only necessary', 'only necessary cookies', 'necessary cookies only',
      'use necessary cookies only', 'essential only', 'only essential', 'essential cookies only',
      'continue without accepting',
      'rifiuta', 'rifiuta tutto', 'rifiuta tutti', 'rifiuta tutti i cookie', 'rifiuta e chiudi',
      'nega', 'solo necessari', 'solo cookie necessari', 'accetta solo necessari',
      'accetta solo i necessari', 'accetta solo i cookie necessari', 'continua senza accettare',
      'ablehnen', 'alle ablehnen', 'alles ablehnen', 'nur notwendige', 'nur notwendige cookies',
      'nur erforderliche', 'nur erforderliche cookies',
      'refuser', 'tout refuser', 'refuser tout', 'refuser et fermer', 'continuer sans accepter',
      'rechazar', 'rechazar todo', 'rechazar todas', 'solo necesarias',
      'rejeitar', 'rejeitar tudo', 'recusar', 'weigeren', 'alles weigeren', 'alleen noodzakelijke'
    ];
    var CONSENT_CONTAINER = /cookie|consent|gdpr|cmp|privacy[-_]?banner/i;
    var state = { declined: false, startedAt: Date.now(), stopped: [], acted: false };

    function post(payload) {
      try {
        var handlers = window.webkit && window.webkit.messageHandlers;
        if (handlers && handlers[BRIDGE]) handlers[BRIDGE].postMessage(payload);
      } catch (e) {}
    }

    function isMainFrame() {
      try { return window.top === window; } catch (e) { return false; }
    }

    function collect(selector, root) {
      var scope = root || document;
      var found = Array.prototype.slice.call(scope.querySelectorAll(selector));
      var all = scope.querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        if (all[i].shadowRoot) found = found.concat(collect(selector, all[i].shadowRoot));
      }
      return found;
    }

    function isVisible(el) {
      if (!el || !el.isConnected || el.disabled) return false;
      var style = window.getComputedStyle(el);
      if (!style || style.display === 'none' || style.visibility === 'hidden') return false;
      var rects = el.getClientRects();
      return rects.length > 0 && rects[0].width > 0 && rects[0].height > 0;
    }

    function label(el) {
      var text = el.tagName === 'INPUT' ? el.value : (el.innerText || el.textContent);
      return String(text || '').toLowerCase().replace(/\s+/g, ' ').replace(/[.!…]+$/, '').trim();
    }

    function insideConsentContainer(el) {
      var node = el;
      for (var depth = 0; node && depth < 10; depth++) {
        // Custom elements such as <reddit-cookie-banner> name themselves.
        var marker = (node.localName || '') + ' ' + (node.id || '') + ' '
          + (typeof node.className === 'string' ? node.className : '') + ' '
          + (node.getAttribute && (node.getAttribute('aria-label') || ''));
        if (CONSENT_CONTAINER.test(marker)) return true;
        node = node.parentElement || (node.getRootNode && node.getRootNode().host);
      }
      return false;
    }

    function findRejectControl() {
      var known = collect(REJECT_SELECTORS.join(', ')).filter(isVisible)[0];
      if (known) return known;
      var candidates = collect('button, [role="button"], a, input[type="button"], input[type="submit"]');
      for (var i = 0; i < candidates.length; i++) {
        var el = candidates[i];
        if (REJECT_LABELS.indexOf(label(el)) === -1) continue;
        if (isVisible(el) && insideConsentContainer(el)) return el;
      }
      return null;
    }

    function declineBanner() {
      if (state.declined || Date.now() - state.startedAt > SEARCH_WINDOW_MS) return;
      var control = findRejectControl();
      if (!control) return;
      state.declined = true;
      control.click();
      post({ type: 'quietAction', kind: 'cookieBanner' });
    }

    var debounceTimer = null;
    var observer = new MutationObserver(function () {
      if (state.declined || Date.now() - state.startedAt > SEARCH_WINDOW_MS) return observer.disconnect();
      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(declineBanner, 300);
    });

    function startBannerWatch() {
      declineBanner();
      try { observer.observe(document.documentElement, { childList: true, subtree: true }); } catch (e) {}
      setTimeout(function () { observer.disconnect(); }, SEARCH_WINDOW_MS);
    }

    // Embedded players answer to the page around them: a video on a news
    // site is stopped, the same player on the video site itself is the point.
    function topHost() {
      try {
        var origins = window.location.ancestorOrigins;
        var top = origins && origins.length ? origins[origins.length - 1] : window.location.origin;
        return new URL(top).hostname.toLowerCase();
      } catch (e) { return String(window.location.hostname).toLowerCase(); }
    }

    function isMediaSite(host) {
      return MEDIA_HOSTS.some(function (domain) { return host === domain || host.endsWith('.' + domain); });
    }

    var mediaExempt = isMediaSite(topHost());

    // Real input only. `navigator.userActivation` cannot be used: WebKit
    // counts every script the browser itself evaluates in the page — the
    // favicon lookup, the tab's audio level — as the user having acted.
    function relayActed(message) {
      var frames = document.querySelectorAll('iframe, frame');
      for (var i = 0; i < frames.length; i++) {
        try { frames[i].contentWindow.postMessage(message, '*'); } catch (e) {}
      }
    }

    function markActed() {
      if (state.acted) return;
      state.acted = true;
      relayActed({ redentQuiet: RELAY, acted: true });
    }

    ['pointerdown', 'keydown', 'touchstart'].forEach(function (name) {
      window.addEventListener(name, function (event) { if (event.isTrusted) markActed(); }, true);
    });

    function resumeStopped() {
      state.stopped.forEach(function (el) {
        if (el.isConnected && el.paused) el.play().catch(function () {});
      });
    }

    window.addEventListener('message', function (event) {
      var data = event.data;
      if (!data || data.redentQuiet !== RELAY) return;
      if (data.ask) {
        if (state.acted && event.source) event.source.postMessage({ redentQuiet: RELAY, acted: true, reply: true }, '*');
        return;
      }
      if (event.source !== window.parent || !data.acted) return;
      markActed();
      if (data.reply && Date.now() - state.startedAt < HANDSHAKE_MS) resumeStopped();
    });

    function wantsSound(el) {
      if (el.volume === 0) return false;
      return !el.muted || !!el.__redentMuted;
    }

    document.addEventListener('play', function (event) {
      var el = event.target;
      if (mediaExempt || !el || (el.tagName !== 'VIDEO' && el.tagName !== 'AUDIO')) return;
      if (state.acted || !wantsSound(el)) return;
      el.pause();
      if (state.stopped.indexOf(el) !== -1) return;
      state.stopped.push(el);
      post({ type: 'quietAction', kind: 'autoplay' });
    }, true);

    if (isMainFrame()) {
      post({ type: 'quietReset' });
    } else {
      try { window.parent.postMessage({ redentQuiet: RELAY, ask: true }, '*'); } catch (e) {}
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', startBannerWatch);
    } else {
      startBannerWatch();
    }
  } catch (e) {}
})();
