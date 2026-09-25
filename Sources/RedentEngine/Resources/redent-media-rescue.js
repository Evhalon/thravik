// Redent media rescue. Runs in the isolated "redent" world of every frame.
//
// Some servers answer a player's own requests with a sign-in page: WebKit's
// media loader goes out without the session the page's fetches carry, and gets
// HTML where it wanted video. Octane attachments fail this way in Safari too.
// When a player gives up on a same-origin file, fetch it once the way the page
// itself would, and play it from memory. Media events do not bubble, so the
// listeners are attached in the capture phase.
(function () {
  'use strict';
  try {
    if (window.__redentMediaRescue) return;
    window.__redentMediaRescue = true;
    // Held in memory whole, so a feature film is left to fail as it did.
    var MAX_BYTES = 512 * 1024 * 1024;
    var MEDIA_ERR_NETWORK = 2;
    var MEDIA_ERR_SRC_NOT_SUPPORTED = 4;
    var NETWORK_NO_SOURCE = 3;
    var TYPES_BY_EXTENSION = {
      mp4: 'video/mp4', m4v: 'video/mp4', mov: 'video/quicktime', webm: 'video/webm',
      mp3: 'audio/mpeg', m4a: 'audio/mp4', aac: 'audio/aac', wav: 'audio/wav'
    };
    var tried = new WeakMap();

    function isMedia(el) {
      return !!el && (el.tagName === 'VIDEO' || el.tagName === 'AUDIO');
    }

    function sameOriginURL(raw) {
      try {
        var url = new URL(raw, location.href);
        var web = url.protocol === 'http:' || url.protocol === 'https:';
        return web && url.origin === location.origin ? url : null;
      } catch (e) { return null; }
    }

    function typeFor(url, served) {
      if (/^(video|audio)\//.test(served)) return served;
      if (served && served !== 'application/octet-stream') return null;
      var extension = url.pathname.split('.').pop().toLowerCase();
      return TYPES_BY_EXTENSION[extension] || null;
    }

    function fetchPlayable(url) {
      return fetch(url.href, { credentials: 'include' }).then(function (response) {
        var served = (response.headers.get('Content-Type') || '').split(';')[0].trim().toLowerCase();
        var type = typeFor(url, served);
        var length = Number(response.headers.get('Content-Length') || 0);
        if (!response.ok || !type || length > MAX_BYTES) return null;
        return response.blob().then(function (blob) {
          return blob.size > 0 && blob.size <= MAX_BYTES ? blob.slice(0, blob.size, type) : null;
        });
      });
    }

    function rescue(el, raw) {
      var url = sameOriginURL(raw);
      if (!url || tried.get(el) === url.href) return;
      tried.set(el, url.href);
      var resume = !!el.__redentWantsPlay || el.autoplay;
      var failedSource = el.currentSrc;
      fetchPlayable(url).then(function (blob) {
        // The page may have moved the player on while the file came down.
        if (!blob || el.currentSrc !== failedSource) return;
        if (el.__redentRescuedURL) URL.revokeObjectURL(el.__redentRescuedURL);
        el.__redentRescuedURL = URL.createObjectURL(blob);
        // The src attribute outranks any <source> children.
        el.src = el.__redentRescuedURL;
        if (resume) el.play().catch(function () {});
      }).catch(function () {});
    }

    function rescuesAfterError(el) {
      var code = el.error && el.error.code;
      return code === MEDIA_ERR_NETWORK || code === MEDIA_ERR_SRC_NOT_SUPPORTED;
    }

    document.addEventListener('play', function (event) {
      if (isMedia(event.target)) event.target.__redentWantsPlay = true;
    }, true);

    document.addEventListener('error', function (event) {
      var target = event.target;
      if (isMedia(target)) {
        if (rescuesAfterError(target)) rescue(target, target.currentSrc || target.src);
        return;
      }
      // A failing <source> reports on itself; only once the player has run out
      // of alternatives is the first one worth fetching.
      if (!target || target.tagName !== 'SOURCE' || !isMedia(target.parentElement)) return;
      var player = target.parentElement;
      setTimeout(function () {
        if (player.networkState !== NETWORK_NO_SOURCE) return;
        var first = player.querySelector('source[src]');
        if (first) rescue(player, first.src);
      }, 0);
    }, true);
  } catch (e) {}
})();
