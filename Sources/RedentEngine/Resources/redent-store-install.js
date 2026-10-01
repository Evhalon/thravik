// The Chrome Web Store disables its install button outside Chrome; this puts
// one beside it that hands the extension to Thravik's own review step.
(function () {
  'use strict';
  var hosts = ['chromewebstore.google.com', 'chrome.google.com'];
  if (window.redentStoreInstall || hosts.indexOf(location.hostname) < 0) return;
  window.redentStoreInstall = true;
  var marker = 'data-redent-store-install';

  function isDetailPage() {
    return /\/detail\//.test(location.pathname);
  }

  // The label is localized ("Add to Chrome", "Aggiungi a Chrome"…), but every
  // language keeps the product name.
  function storeButton() {
    var buttons = document.querySelectorAll('button:not([' + marker + '])');
    for (var i = 0; i < buttons.length; i++) {
      var button = buttons[i];
      var disabled = button.disabled || button.getAttribute('aria-disabled') === 'true';
      if (disabled && /Chrome/.test(button.textContent || '')) return button;
    }
    return null;
  }

  function relabel(button) {
    var walker = document.createTreeWalker(button, NodeFilter.SHOW_TEXT);
    var labelled = false;
    for (var node = walker.nextNode(); node; node = walker.nextNode()) {
      if (!node.nodeValue.trim()) continue;
      node.nodeValue = labelled ? '' : 'Add to Thravik';
      labelled = true;
    }
  }

  // A clone keeps the store's own look; its js* hooks and disabled styling go,
  // so the page's event delegation never claims it.
  function replacement(original) {
    var button = original.cloneNode(true);
    [button].concat(Array.prototype.slice.call(button.querySelectorAll('*'))).forEach(function (el) {
      Array.prototype.slice.call(el.attributes).forEach(function (attr) {
        if (/^js|^data-|^aria-disabled$|^disabled$/.test(attr.name)) el.removeAttribute(attr.name);
      });
      Array.prototype.slice.call(el.classList).forEach(function (name) {
        if (/disabled/i.test(name)) el.classList.remove(name);
      });
    });
    button.setAttribute(marker, '');
    button.type = 'button';
    relabel(button);
    button.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      // A page script calling click() is not the user asking.
      if (!event.isTrusted) return;
      try { window.webkit.messageHandlers.redentBridge.postMessage({ type: 'extensionInstallRequested' }); }
      catch (e) {}
    }, true);
    return button;
  }

  function apply() {
    if (!isDetailPage()) return;
    var original = storeButton();
    if (!original || !original.parentNode) return;
    // The store re-renders the button on its own; the old copy goes with it.
    document.querySelectorAll('button[' + marker + '=""]').forEach(function (old) { old.remove(); });
    original.parentNode.insertBefore(replacement(original), original);
    original.style.setProperty('display', 'none', 'important');
    original.setAttribute(marker, 'hidden');
  }

  var scheduled = false;
  new MutationObserver(function () {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(function () { scheduled = false; apply(); });
  }).observe(document.documentElement, { childList: true, subtree: true });
  apply();
})();
