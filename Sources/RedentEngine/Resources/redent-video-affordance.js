// A page-local affordance stays reachable when browser chrome is collapsed.
(function () {
  'use strict';
  if (window.redentVideoAffordance) return;
  var video = null, floating = false;
  var root = document.createElement('div');
  root.setAttribute('data-redent-video-affordance', '');
  root.hidden = true;
  root.style.cssText = 'all:initial!important;display:none!important;' +
    'position:fixed!important;z-index:2147483647!important;' +
    'transform:translateX(-100%)!important;pointer-events:auto!important;';
  var shadow = root.attachShadow({ mode: 'closed' });
  var style = document.createElement('style');
  style.textContent = 'button{all:initial;display:flex;align-items:center;gap:6px;' +
    'padding:8px 10px;border-radius:10px;color:white;cursor:pointer;' +
    'font:500 12px -apple-system,sans-serif;background:rgba(18,18,20,.78);' +
    'backdrop-filter:blur(16px);box-shadow:inset 0 0 0 1px rgba(255,255,255,.2),0 3px 12px #0004}' +
    'button:hover{background:rgba(45,45,48,.9)}button:focus-visible{outline:2px solid white;outline-offset:3px}' +
    'button[data-compact]{padding:6px}button[data-compact] span{display:none}' +
    'svg{width:16px;height:16px;flex:none}';
  var button = document.createElement('button');
  button.type = 'button';
  button.setAttribute('aria-label', 'Float video');
  button.title = 'Float video (Control–Command–V)';
  button.innerHTML = '<svg viewBox="0 0 20 20" fill="none" aria-hidden="true">' +
    '<rect x="2" y="3" width="16" height="13" rx="2" stroke="currentColor" stroke-width="1.3"/>' +
    '<rect x="10" y="9" width="6" height="5" rx="1" fill="currentColor"/></svg><span>Float video</span>';
  shadow.append(style, button);
  document.documentElement.appendChild(root);

  function position() {
    if (!video || floating || !video.isConnected) { visibility(false); return; }
    var rect = video.getBoundingClientRect();
    visibility(rect.width >= 32 && rect.height >= 32 && rect.bottom > 0 &&
      rect.top < window.innerHeight && rect.right > 0 && rect.left < window.innerWidth);
    if (root.hidden) return;
    button.toggleAttribute('data-compact', rect.width < 160 || rect.height < 70);
    var inset = Math.min(12, Math.max(2, (Math.min(rect.width, rect.height) - 28) / 2));
    root.style.setProperty('left', Math.min(rect.right - inset, window.innerWidth - 4) + 'px', 'important');
    root.style.setProperty('top', Math.max(rect.top + inset, 4) + 'px', 'important');
  }

  function visibility(visible) {
    root.hidden = !visible;
    root.style.setProperty('display', visible ? 'block' : 'none', 'important');
  }

  var resize = new ResizeObserver(position);
  window.redentVideoAffordance = {
    update: function (target, isFloating) {
      if (target !== video) {
        if (video) resize.unobserve(video);
        video = target;
        if (video) resize.observe(video);
      }
      floating = isFloating;
      position();
    }
  };

  document.addEventListener('scroll', position, true);
  window.addEventListener('resize', position);
  root.addEventListener('click', function (event) {
    if (!event.isTrusted || floating || !video || !video.isConnected) return;
    event.preventDefault();
    event.stopPropagation();
    try { window.webkit.messageHandlers.redentBridge.postMessage({ type: 'floatVideoRequested' }); }
    catch (error) {}
  });
})();
