// Redent tab audio. Runs in the isolated "redent" world of every frame. Tells
// native code whether this frame is playing sound, and mutes on request. Media
// events do not bubble, so every listener is attached in the capture phase.
(function () {
  'use strict';
  try {
    if (window.__redentMedia) return;
    window.__redentMedia = true;
    var BRIDGE = 'redentBridge';
    var RELAY = '__REDENT_MEDIA_RELAY__';
    var EVENTS = ['play', 'playing', 'pause', 'ended', 'volumechange', 'emptied', 'loadedmetadata'];
    var frameID = Math.random().toString(36).slice(2) + Date.now().toString(36);
    var state = { muted: false, audible: false };

    function post(payload) {
      try {
        var handlers = window.webkit && window.webkit.messageHandlers;
        if (handlers && handlers[BRIDGE]) handlers[BRIDGE].postMessage(payload);
      } catch (e) {}
    }

    function isMainFrame() {
      try { return window.top === window; } catch (e) { return false; }
    }

    // A video that has decoded seconds of frames and not one byte of audio has
    // no sound to mute; everything else counts once it plays at any volume.
    function wantsSound(el) {
      if (el.paused || el.ended || el.volume === 0) return false;
      if (el.muted && !el.__redentMuted) return false;
      var silent = el.tagName === 'VIDEO' && el.webkitAudioDecodedByteCount === 0 && el.currentTime > 2;
      return !silent;
    }

    function report() {
      var media = document.querySelectorAll('audio, video');
      var audible = false;
      for (var i = 0; i < media.length && !audible; i++) audible = wantsSound(media[i]);
      if (audible === state.audible) return;
      state.audible = audible;
      post({ type: 'mediaAudible', frame: frameID, audible: audible });
    }

    function mute(el) {
      if (!state.muted || el.muted) return;
      el.muted = true;
      el.__redentMuted = true;
    }

    function relay(muted) {
      var frames = document.querySelectorAll('iframe, frame');
      for (var i = 0; i < frames.length; i++) {
        try { frames[i].contentWindow.postMessage({ redentRelay: RELAY, muted: muted }, '*'); } catch (e) {}
      }
    }

    function setMuted(muted) {
      state.muted = !!muted;
      var media = document.querySelectorAll('audio, video');
      for (var i = 0; i < media.length; i++) {
        var el = media[i];
        if (state.muted) { mute(el); continue; }
        if (el.__redentMuted) { el.muted = false; el.__redentMuted = false; }
      }
      relay(state.muted);
      report();
    }

    EVENTS.forEach(function (name) {
      document.addEventListener(name, function (event) {
        var target = event.target;
        if (name === 'play' && target && target.tagName) mute(target);
        report();
      }, true);
    });

    window.addEventListener('message', function (event) {
      var data = event.data;
      if (event.source !== window.parent || !data || data.redentRelay !== RELAY) return;
      setMuted(data.muted);
    });

    window.addEventListener('pagehide', function () {
      if (state.audible) post({ type: 'mediaAudible', frame: frameID, audible: false });
    });

    if (isMainFrame()) {
      window.redentSetMuted = setMuted;
      post({ type: 'mediaReset' });
    }
  } catch (e) {}
})();
