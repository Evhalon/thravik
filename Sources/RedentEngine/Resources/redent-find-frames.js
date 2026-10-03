(function () {
  'use strict';
  var pending = new Map();

  function path() {
    var indices = [];
    var child = window;
    while (child !== child.top && indices.length <= 32) {
      var parent = child.parent;
      var index = 0;
      while (index < parent.frames.length && parent.frames[index] !== child) index++;
      indices.unshift(index);
      child = parent;
    }
    return indices;
  }

  async function announce(session) {
    try {
      return await window.webkit.messageHandlers.redentFindFrames.postMessage({
        type: 'findFrameReady', path: path(), session: session
      });
    } catch (_) { return false; }
  }

  async function register(session) {
    if (typeof session !== 'string' || session.length > 64) return;
    if (!await announce(session) || !window.frames.length) return;
    var request = crypto.randomUUID();
    return new Promise(function (resolve) {
      var children = new Set();
      for (var index = 0; index < window.frames.length; index++) children.add(window.frames[index]);
      var timer = setTimeout(finish, 100);
      function finish() {
        clearTimeout(timer);
        pending.delete(request);
        resolve();
      }
      pending.set(request, function (source) {
        children.delete(source);
        if (!children.size) finish();
      });
      // Only readiness crosses the page's message channel. Queries and page
      // text stay in native calls addressed to the isolated content world.
      children.forEach(function (child) {
        child.postMessage({ redentFindRegister: request, session: session }, '*');
      });
    });
  }

  window.addEventListener('message', function (event) {
    var message = event.data;
    if (!message || typeof message !== 'object') return;
    if (typeof message.redentFindRegistered === 'string') {
      var complete = pending.get(message.redentFindRegistered);
      if (complete) complete(event.source);
    }
    if (event.source !== window.parent || window === window.top) return;
    if (typeof message.redentFindRegister !== 'string') return;
    register(message.session).then(function () {
      event.source.postMessage({ redentFindRegistered: message.redentFindRegister }, '*');
    });
  });

  window.redentFindRegister = register;
})();
