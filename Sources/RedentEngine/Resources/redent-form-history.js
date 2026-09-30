// Redent form history. Runs in the isolated "redent" content world, main frame
// only. Tells native code where the field the user is typing in sits, and
// which values a sent form carried. The suggestions themselves are drawn by
// native code and never enter the page's DOM, where the site could read them.
(function () {
  'use strict';
  try {
    var BRIDGE = 'redentBridge';
    var TEXT_TYPES = ['', 'text', 'email', 'tel', 'search', 'url', 'number'];
    var MAX_VALUE = 200;

    var active = null;
    // Kept past a blur: a click on the native menu must still reach the field
    // it was opened for, even if the page saw focus leave for a moment.
    var filling = null;
    var count = 0;
    var index = -1;
    var lastSent = { signature: '', at: 0 };

    function post(type, payload) {
      try {
        var handlers = window.webkit && window.webkit.messageHandlers;
        if (handlers && handlers[BRIDGE]) {
          handlers[BRIDGE].postMessage(Object.assign({ type: type }, payload || {}));
        }
      } catch (e) {}
    }

    function target(event) {
      var path = event.composedPath ? event.composedPath() : [];
      return path.length ? path[0] : event.target;
    }

    function attribute(el, name) {
      return String(el.getAttribute(name) || '').trim().toLowerCase();
    }

    // A site that draws its own dropdown (a datalist, a combobox, or a field
    // marked autocomplete="off") would end up with two menus stacked on top of
    // each other; that site's list wins.
    function eligible(el) {
      if (!el || el.tagName !== 'INPUT' || el.readOnly || el.disabled) return false;
      if (TEXT_TYPES.indexOf(String(el.type || '').toLowerCase()) === -1) return false;
      if (el.hasAttribute('list') || attribute(el, 'role') === 'combobox') return false;
      var aria = attribute(el, 'aria-autocomplete');
      if (aria === 'list' || aria === 'both') return false;
      var own = attribute(el, 'autocomplete');
      if (own === 'off') return false;
      return !(own === '' && el.form && attribute(el.form, 'autocomplete') === 'off');
    }

    function descriptor(el) {
      return {
        autocomplete: attribute(el, 'autocomplete'),
        inputType: String(el.type || 'text').toLowerCase(),
        name: String(el.getAttribute('name') || ''),
        identifier: String(el.id || '')
      };
    }

    function rectOf(el) {
      var rect = el.getBoundingClientRect();
      return { x: rect.left, y: rect.top, width: rect.width, height: rect.height };
    }

    function activate(el) {
      active = el;
      filling = el;
      post('formFieldActive', Object.assign(descriptor(el), {
        typed: String(el.value || '').slice(0, MAX_VALUE),
        rect: rectOf(el)
      }));
    }

    function deactivate() {
      if (!active && count === 0) return;
      active = null;
      count = 0;
      index = -1;
      post('formFieldInactive', {});
    }

    function entriesIn(scope) {
      var fields = scope.tagName === 'FORM' ? Array.prototype.slice.call(scope.elements) : [scope];
      return fields.filter(function (el) {
        return el.__redentTyped && eligible(el) && String(el.value || '').trim() !== '';
      }).map(function (el) {
        return Object.assign(descriptor(el), { value: String(el.value).slice(0, MAX_VALUE) });
      });
    }

    // Return in a field submits its form too, so the same values can arrive
    // twice within a moment; the second report is dropped.
    function reportSubmission(scope) {
      var entries = entriesIn(scope);
      if (entries.length === 0) return;
      var signature = JSON.stringify(entries);
      var now = Date.now();
      if (signature === lastSent.signature && now - lastSent.at < 1500) return;
      lastSent = { signature: signature, at: now };
      post('formSubmitted', { entries: entries });
    }

    function step(delta) {
      index = index + delta;
      if (index >= count) index = -1;
      if (index < -1) index = count - 1;
      post('formSuggestionHighlighted', { index: index });
    }

    function onKeyDown(event) {
      var el = target(event);
      if (!eligible(el)) return;
      var open = count > 0 && el === active;
      var key = event.key;
      if (open && (key === 'ArrowDown' || key === 'ArrowUp')) {
        step(key === 'ArrowDown' ? 1 : -1);
      } else if (open && key === 'Enter' && index >= 0) {
        post('formSuggestionChosen', { index: index });
      } else if (open && key === 'Escape') {
        deactivate();
      } else {
        if (key === 'ArrowDown' && !open) activate(el);
        if (key === 'Enter' && !el.form) reportSubmission(el);
        return;
      }
      event.preventDefault();
      event.stopImmediatePropagation();
    }

    // Only the user's own typing opens the menu: a page setting a value from
    // script, or Redent filling one, dispatches an untrusted event.
    document.addEventListener('input', function (event) {
      var el = target(event);
      if (!event.isTrusted || !eligible(el)) return;
      el.__redentTyped = true;
      activate(el);
    }, true);
    document.addEventListener('click', function (event) {
      var el = target(event);
      if (eligible(el) && el === document.activeElement) activate(el);
    }, true);
    document.addEventListener('focusout', function () {
      var left = active;
      setTimeout(function () {
        if (left && left === active && document.activeElement !== left) deactivate();
      }, 150);
    }, true);
    document.addEventListener('submit', function (event) {
      if (event.target && event.target.tagName === 'FORM') reportSubmission(event.target);
    }, true);
    window.addEventListener('keydown', onKeyDown, true);
    document.addEventListener('scroll', function () { if (count > 0) deactivate(); }, true);
    window.addEventListener('resize', function () { if (count > 0) deactivate(); });
    window.addEventListener('pagehide', deactivate);

    window.redentFormSuggestions = function (total) {
      count = Math.max(0, Math.floor(Number(total) || 0));
      index = -1;
    };

    window.redentFillFormField = function (value) {
      try {
        var el = filling;
        if (!el || !el.isConnected || typeof value !== 'string') return;
        var proto = Object.getPrototypeOf(el) || window.HTMLInputElement.prototype;
        var setter = Object.getOwnPropertyDescriptor(proto, 'value')
          || Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
        if (setter && setter.set) setter.set.call(el, value); else el.value = value;
        el.__redentTyped = true;
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
        el.focus();
        active = el;
        count = 0;
        index = -1;
      } catch (e) {}
    };
  } catch (e) {}
})();
