// Isolated-world now playing, main frame only. Reads MediaSession metadata
// and toggles media elements. Next/previous stay native-hidden: page action
// handlers are not reachable from this world. Event driven; never polls.
(function () {
  'use strict';
  if (window.redentNowPlaying) return;

  var last = '';
  var retry = null;
  var pausedByUser = [];

  function cleaned(value) {
    return typeof value === 'string' ? value.trim().slice(0, 200) : '';
  }

  function artworkURL(metadata) {
    if (!metadata || !metadata.artwork || !metadata.artwork.length) return '';
    try {
      var src = metadata.artwork[0].src;
      if (typeof src !== 'string') return '';
      if (src.indexOf('https:') === 0 || src.indexOf('http:') === 0) return src.slice(0, 2048);
      return '';
    } catch (error) { return ''; }
  }

  function snapshot(ended) {
    var title = '';
    var artist = '';
    var artwork = '';
    try {
      var metadata = navigator.mediaSession && navigator.mediaSession.metadata;
      if (metadata) {
        title = cleaned(metadata.title);
        artist = cleaned(metadata.artist);
        artwork = artworkURL(metadata);
      }
    } catch (error) {}
    return { type: 'mediaSession', title: title, artist: artist, artwork: artwork, ended: ended };
  }

  function post(ended) {
    var payload = snapshot(ended);
    var key = JSON.stringify(payload);
    if (key === last) return;
    last = key;
    try {
      var handlers = window.webkit && window.webkit.messageHandlers;
      if (handlers && handlers.redentBridge) handlers.redentBridge.postMessage(payload);
    } catch (error) {}
  }

  function isMedia(node) {
    return node && node.tagName && (node.tagName === 'AUDIO' || node.tagName === 'VIDEO');
  }

  function resumable() {
    var media = document.querySelectorAll('audio, video');
    for (var index = 0; index < media.length; index++) {
      if (!media[index].ended && media[index].currentSrc) return media[index];
    }
    return null;
  }

  function onMedia(event) {
    if (!isMedia(event.target)) return;
    var finished = event.type === 'ended' || event.type === 'emptied';
    post(finished && !resumable());
    if (event.type !== 'playing') return;
    // Sites often set MediaSession metadata just after playback starts.
    clearTimeout(retry);
    retry = setTimeout(function () { post(false); }, 1500);
  }

  ['playing', 'pause', 'ended', 'loadedmetadata', 'emptied'].forEach(function (name) {
    document.addEventListener(name, onMedia, true);
  });

  function pauseAll() {
    var media = document.querySelectorAll('audio, video');
    var playing = [];
    for (var index = 0; index < media.length; index++) {
      if (!media[index].paused && !media[index].ended) playing.push(media[index]);
    }
    playing.forEach(function (element) { element.pause(); });
    return playing;
  }

  function resume() {
    var targets = pausedByUser.filter(function (element) { return element.isConnected && !element.ended; });
    if (!targets.length && resumable()) targets = [resumable()];
    pausedByUser = [];
    targets.forEach(function (element) {
      var started = element.play();
      if (started && started.catch) started.catch(function () {});
    });
    return targets.length ? 'playing' : 'none';
  }

  window.redentNowPlaying = {
    toggle: function () {
      var paused = pauseAll();
      if (!paused.length) return resume();
      pausedByUser = paused;
      return 'paused';
    },
    pause: function () { pausedByUser = []; pauseAll(); }
  };
})();
