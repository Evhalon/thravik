// Keeps the original media element and its page alive; nothing is copied or fetched.
(function () {
  'use strict';
  if (window.redentFloatVideo) return;
  var active = null;
  var saved = [];
  var sheet = null;
  var oldMarker = null;
  var lastState = '';
  var sourceBounds = null;

  function playback(video) {
    if (!video) return { elapsed: 0, duration: 0, seekStart: 0, seekEnd: 0, volume: 1, muted: false, live: false };
    var duration = Number.isFinite(video.duration) ? Math.max(0, video.duration) : 0;
    var ranges = video.seekable;
    return { elapsed: Number.isFinite(video.currentTime) ? Math.max(0, video.currentTime) : 0,
      duration: duration, seekStart: ranges.length ? ranges.start(0) : 0,
      seekEnd: ranges.length ? ranges.end(ranges.length - 1) : duration,
      volume: video.volume, muted: video.muted, live: video.duration === Infinity };
  }

  function candidate() {
    if (active && active.isConnected) return active;
    var videos = document.querySelectorAll('video');
    var best = null, score = 0;
    for (var i = 0; i < videos.length; i++) {
      var video = videos[i], rect = video.getBoundingClientRect();
      if (video.readyState < 1 || rect.width < 32 || rect.height < 32) continue;
      var area = rect.width * rect.height * (video.paused ? 1 : 10);
      if (area > score) { best = video; score = area; }
    }
    return best;
  }

  function report() {
    if (active && !active.isConnected) restore();
    var video = candidate();
    if (window.redentVideoAffordance) window.redentVideoAffordance.update(video, !!active);
    var state = {
      type: 'videoState', available: !!video,
      playing: !!video && !video.paused && !video.ended,
      aspect: video && video.videoHeight ? video.videoWidth / video.videoHeight : 16 / 9
    };
    Object.assign(state, playback(video));
    var key = JSON.stringify(state);
    if (key === lastState) return;
    lastState = key;
    try { window.webkit.messageHandlers.redentBridge.postMessage(state); } catch (error) {}
  }

  function remember(node) {
    saved.push({ node: node, style: node.getAttribute('style') });
  }

  function set(node, properties) {
    Object.keys(properties).forEach(function (key) {
      node.style.setProperty(key, properties[key], 'important');
    });
  }

  function open() {
    if (active) return true;
    var video = candidate();
    if (!video) return false;
    var rect = video.getBoundingClientRect();
    sourceBounds = { x: rect.x, y: rect.y, width: rect.width, height: rect.height, viewportWidth: window.innerWidth };
    active = video;
    oldMarker = video.getAttribute('data-redent-floating-video');
    video.setAttribute('data-redent-floating-video', '');
    var parent = video.parentElement;
    while (parent) {
      remember(parent);
      set(parent, { transform: 'none', filter: 'none', perspective: 'none', contain: 'none',
        overflow: 'visible', 'clip-path': 'none', opacity: '1', position: 'static' });
      parent = parent.parentElement;
    }
    remember(video);
    set(video, { position: 'fixed', inset: '0', width: '100vw', height: '100vh',
      'min-width': '0', 'min-height': '0', 'max-width': 'none', 'max-height': 'none',
      margin: '0', padding: '0', border: '0', transform: 'none', 'object-fit': 'contain',
      visibility: 'visible', display: 'block', opacity: '1', 'z-index': '2147483647' });
    sheet = document.createElement('style');
    sheet.textContent = 'html,body{background:black!important;overflow:hidden!important}' +
      'body *{visibility:hidden!important}[data-redent-floating-video]{visibility:visible!important}';
    document.documentElement.appendChild(sheet);
    report();
    return true;
  }

  function restore() {
    if (sheet) sheet.remove();
    sheet = null;
    saved.forEach(function (entry) {
      if (entry.style === null) entry.node.removeAttribute('style');
      else entry.node.setAttribute('style', entry.style);
    });
    saved = [];
    if (active) {
      if (oldMarker === null) active.removeAttribute('data-redent-floating-video');
      else active.setAttribute('data-redent-floating-video', oldMarker);
    }
    active = null;
    if (window.redentVideoAffordance) window.redentVideoAffordance.update(candidate(), false);
  }

  window.redentFloatVideo = {
    open: open, restore: restore,
    sourceBounds: function () { return sourceBounds; },
    pause: function () { var video = candidate(); if (video) video.pause(); },
    toggle: function () {
      var video = candidate();
      if (!video) return false;
      if (video.paused) return video.play().then(function () { return true; });
      video.pause(); return false;
    },
    seek: function (seconds) {
      var video = candidate();
      if (!video || !Number.isFinite(seconds)) return false;
      var state = playback(video);
      if (state.seekEnd <= state.seekStart) return false;
      video.currentTime = Math.min(Math.max(seconds, state.seekStart), state.seekEnd);
      report(); return true;
    },
    volume: function (level) {
      var video = candidate();
      if (!video || !Number.isFinite(level)) return false;
      video.volume = Math.min(Math.max(level, 0), 1);
      if (level > 0) video.muted = false;
      report(); return true;
    },
    mute: function (muted) {
      var video = candidate();
      if (!video) return false;
      video.muted = typeof muted === 'boolean' ? muted : !video.muted;
      report(); return true;
    }
  };
  ['loadedmetadata', 'playing', 'pause', 'ended', 'emptied', 'resize', 'durationchange', 'volumechange', 'seeked'].forEach(function (event) {
    document.addEventListener(event, report, true);
  });
  document.addEventListener('timeupdate', function () { if (active) report(); }, true);
  var observer = new MutationObserver(report);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.addEventListener('pagehide', function () { observer.disconnect(); restore(); });
  report();
})();
