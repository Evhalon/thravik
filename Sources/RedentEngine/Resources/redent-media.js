// Redent tab audio. Runs in the isolated "redent" world of every frame. Tells
// native code whether this frame is playing sound, and applies the tab's mute
// and volume. Media events do not bubble, so every listener is attached in the
// capture phase.
(function () {
  'use strict';
  try {
    if (window.__redentMedia) return;
    window.__redentMedia = true;
    var BRIDGE = 'redentBridge';
    var RELAY = '__REDENT_MEDIA_RELAY__';
    var EVENTS = ['play', 'playing', 'pause', 'ended', 'volumechange', 'emptied', 'loadedmetadata'];
    var frameID = Math.random().toString(36).slice(2) + Date.now().toString(36);
    var state = { muted: false, volume: 1, audible: false };

    function post(payload) {
      try {
        var handlers = window.webkit && window.webkit.messageHandlers;
        if (handlers && handlers[BRIDGE]) handlers[BRIDGE].postMessage(payload);
      } catch (e) {}
    }

    function isMainFrame() {
      try { return window.top === window; } catch (e) { return false; }
    }

    // The volume the page asked for, before the tab's own level scales it.
    function pageVolume(el) {
      return typeof el.__redentPageVolume === 'number' ? el.__redentPageVolume : el.volume;
    }

    // A video that has decoded seconds of frames and not one byte of audio has
    // no sound to mute; everything else counts once it plays at any volume.
    function wantsSound(el) {
      if (el.paused || el.ended || pageVolume(el) === 0) return false;
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

    function applyMute(el) {
      if (state.muted && !el.muted) { el.muted = true; el.__redentMuted = true; }
      if (!state.muted && el.__redentMuted) { el.muted = false; el.__redentMuted = false; }
    }

    // Scales rather than replaces: the site's own slider keeps working, and
    // its level is what the tab's level multiplies.
    function applyVolume(el) {
      if (state.volume >= 1 && typeof el.__redentPageVolume !== 'number') return;
      var base = pageVolume(el);
      var target = Math.max(0, Math.min(1, base * state.volume));
      el.__redentPageVolume = base;
      el.__redentApplied = target;
      if (Math.abs(el.volume - target) > 0.0001) el.volume = target;
      if (state.volume >= 1) { delete el.__redentPageVolume; delete el.__redentApplied; }
    }

    // A volume change that is not the one this script just made came from the page.
    function adoptPageVolume(el) {
      if (typeof el.__redentApplied !== 'number' || Math.abs(el.volume - el.__redentApplied) < 0.0001) return;
      el.__redentPageVolume = el.volume;
      applyVolume(el);
    }

    function applyAll() {
      var media = document.querySelectorAll('audio, video');
      for (var i = 0; i < media.length; i++) { applyMute(media[i]); applyVolume(media[i]); }
    }

    function relay() {
      var frames = document.querySelectorAll('iframe, frame');
      var message = { redentRelay: RELAY, muted: state.muted, volume: state.volume };
      for (var i = 0; i < frames.length; i++) {
        try { frames[i].contentWindow.postMessage(message, '*'); } catch (e) {}
      }
    }

    function setAudio(muted, volume) {
      state.muted = !!muted;
      var level = Number(volume);
      state.volume = isFinite(level) ? Math.max(0, Math.min(1, level)) : 1;
      applyAll();
      relay();
      report();
    }

    EVENTS.forEach(function (name) {
      document.addEventListener(name, function (event) {
        var target = event.target;
        if (target && target.tagName && (target.tagName === 'AUDIO' || target.tagName === 'VIDEO')) {
          if (name === 'volumechange') adoptPageVolume(target);
          if (name === 'play' || name === 'loadedmetadata') { applyMute(target); applyVolume(target); }
        }
        report();
      }, true);
    });

    window.addEventListener('message', function (event) {
      var data = event.data;
      if (event.source !== window.parent || !data || data.redentRelay !== RELAY) return;
      setAudio(data.muted, data.volume);
    });

    window.addEventListener('pagehide', function () {
      if (state.audible) post({ type: 'mediaAudible', frame: frameID, audible: false });
    });

    if (isMainFrame()) {
      window.redentSetAudio = setAudio;
      post({ type: 'mediaReset' });
    }
  } catch (e) {}
})();
