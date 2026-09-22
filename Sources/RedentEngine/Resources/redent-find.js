// Redent find-in-page. Runs in the isolated "redent" world, beside the page
// bridge. Matches are painted with the CSS Custom Highlight API, which colours
// ranges without inserting a single node into the page's DOM — no wrapper
// spans for a framework to reconcile away, and nothing left behind on close.
(function () {
  'use strict';
  try {
    var ALL = 'redent-find-all';
    var ACTIVE = 'redent-find-active';
    var CONTROL_ALL = 'redent-find-control-all';
    var CONTROL_ACTIVE = 'redent-find-control-active';
    var RULES =
      '::highlight(redent-find-all){background-color:#ffe55a;color:#101010}' +
      '::highlight(redent-find-active){background-color:#ff9632;color:#101010}' +
      '.redent-find-control-all{outline:2px solid #ffe55a!important;outline-offset:-2px}' +
      '.redent-find-control-active{outline:3px solid #ff9632!important;outline-offset:-2px}';
    // Past this many hits the counter stops being information, and painting
    // them all costs more than it tells anyone.
    var MATCH_LIMIT = 2000;
    // Elements whose text runs into its neighbours' rather than starting a
    // line of its own; anything else separates two matches.
    var INLINE = {
      A: 1, ABBR: 1, B: 1, BDI: 1, BDO: 1, CITE: 1, CODE: 1, DATA: 1, DEL: 1, DFN: 1,
      EM: 1, FONT: 1, I: 1, INS: 1, KBD: 1, MARK: 1, Q: 1, RUBY: 1, S: 1, SAMP: 1,
      SMALL: 1, SPAN: 1, STRONG: 1, SUB: 1, SUP: 1, TIME: 1, TT: 1, U: 1, VAR: 1
    };
    var SKIP = { SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, TEXTAREA: 1, TITLE: 1, SELECT: 1 };

    var state = { query: '', matches: [], index: -1, styled: false, requestID: 0, controlMarks: [] };

    function supported() {
      return typeof CSS !== 'undefined' && !!CSS.highlights && typeof Highlight === 'function';
    }

    // A constructible sheet rather than a <style> element: no node the page can
    // trip over, and no inline-style CSP to argue with.
    function installStyle() {
      if (state.styled) return;
      try {
        var sheet = new CSSStyleSheet();
        sheet.replaceSync(RULES);
        document.adoptedStyleSheets = document.adoptedStyleSheets.concat(sheet);
        state.styled = true;
      } catch (e) {}
    }

    function blockAncestor(element, root) {
      var node = element;
      while (node && node !== root && INLINE[node.nodeName]) node = node.parentElement;
      return node;
    }

    function visible(element) {
      if (!element || element.closest('[hidden],[aria-hidden="true"],[inert]')) return false;
      if (element.checkVisibility) {
        return element.checkVisibility({ contentVisibilityAuto: true, opacityProperty: true, visibilityProperty: true });
      }
      var style = window.getComputedStyle(element);
      return (style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0')
        && (!!element.offsetParent || element.nodeName === 'BODY');
    }

    function omitted(parent, root) {
      for (var node = parent; node && node !== root; node = node.parentElement) {
        if (SKIP[node.nodeName]) return true;
      }
      return false;
    }

    // The page's visible text as one string, with a map back to the nodes it
    // came from, so a match may span the <em> in the middle of a sentence.
    function readPage(root) {
      var segments = [];
      var text = '';
      var lastBlock = null;
      if (!root) return { segments: segments, text: text };
      var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
        acceptNode: function (node) {
          var parent = node.parentElement;
          if (!node.data || !parent || omitted(parent, root)) return NodeFilter.FILTER_REJECT;
          return visible(parent) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        }
      });
      for (var node = walker.nextNode(); node; node = walker.nextNode()) {
        var block = blockAncestor(node.parentElement, root);
        if (lastBlock && block !== lastBlock) text += '\n';
        lastBlock = block;
        segments.push({ node: node, start: text.length });
        text += node.data;
      }
      return { segments: segments, text: text };
    }

    function segmentAt(segments, offset) {
      var low = 0;
      var high = segments.length - 1;
      while (low < high) {
        var middle = (low + high + 1) >> 1;
        if (segments[middle].start <= offset) low = middle;
        else high = middle - 1;
      }
      return segments[low];
    }

    function rangeFor(segments, start, end) {
      try {
        var head = segmentAt(segments, start);
        var tail = segmentAt(segments, end - 1);
        var range = document.createRange();
        range.setStart(head.node, start - head.start);
        range.setEnd(tail.node, Math.min(end - tail.start, tail.node.data.length));
        return range;
      } catch (e) {
        return null;
      }
    }

    function escapeForRegExp(text) {
      return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }

    function frontmostDialog() {
      var selector = 'dialog[open],[aria-modal],[role="dialog"],[role="alertdialog"]';
      var roots = Array.prototype.filter.call(document.querySelectorAll(selector), function (element) {
        var role = element.getAttribute('role');
        var modal = (element.getAttribute('aria-modal') || '').toLowerCase() === 'true';
        return visible(element) && (element.nodeName === 'DIALOG' || modal || role === 'dialog' || role === 'alertdialog');
      });
      roots.sort(frontmostFirst);
      return roots[0] || null;
    }

    function frontmostFirst(first, second) {
      if (first.contains(second)) return 1;
      if (second.contains(first)) return -1;
      var firstDepth = layerDepth(first);
      var secondDepth = layerDepth(second);
      if (firstDepth !== secondDepth) return firstDepth - secondDepth;
      var firstZIndex = Number(window.getComputedStyle(first).zIndex) || 0;
      var secondZIndex = Number(window.getComputedStyle(second).zIndex) || 0;
      if (firstZIndex !== secondZIndex) return secondZIndex - firstZIndex;
      return first.compareDocumentPosition(second) & Node.DOCUMENT_POSITION_FOLLOWING ? 1 : -1;
    }

    function layerDepth(element) {
      var rect = element.getBoundingClientRect();
      var x = Math.max(0, Math.min(window.innerWidth - 1, rect.left + rect.width / 2));
      var y = Math.max(0, Math.min(window.innerHeight - 1, rect.top + rect.height / 2));
      var layers = document.elementsFromPoint(x, y);
      for (var index = 0; index < layers.length; index++) {
        if (element.contains(layers[index])) return index;
      }
      return Number.MAX_SAFE_INTEGER;
    }

    function rangeMatches(query, root) {
      var page = readPage(root);
      if (!page.segments.length) return [];
      // A case-insensitive RegExp over the original text, never a lower-cased
      // copy: case folding can change a string's length and slide every offset.
      var pattern = new RegExp(escapeForRegExp(query), 'gi');
      var ranges = [];
      var match = pattern.exec(page.text);
      while (match && match[0].length && ranges.length < MATCH_LIMIT) {
        var range = rangeFor(page.segments, match.index, match.index + match[0].length);
        if (range) ranges.push(range);
        match = pattern.exec(page.text);
      }
      return ranges;
    }

    function searchableValue(element) {
      if (element.nodeName === 'TEXTAREA') return element.value;
      if (element.nodeName === 'SELECT') {
        return Array.prototype.map.call(element.selectedOptions, function (option) { return option.text; }).join(' ');
      }
      var type = (element.type || 'text').toLowerCase();
      if (/^(checkbox|file|hidden|image|password|radio)$/.test(type)) return '';
      return element.value;
    }

    function controlMatches(query, root) {
      var selector = 'input,textarea,select';
      var controls = Array.prototype.slice.call(root.querySelectorAll(selector));
      if (root.matches && root.matches(selector)) controls.unshift(root);
      var pattern = new RegExp(escapeForRegExp(query), 'gi');
      var matches = [];
      for (var index = 0; index < controls.length; index++) {
        var control = controls[index];
        var value = searchableValue(control);
        var match = value && visible(control) ? pattern.exec(value) : null;
        while (match && match[0].length && matches.length < MATCH_LIMIT) {
          matches.push({ control: control });
          match = pattern.exec(value);
        }
      }
      return matches;
    }

    function findMatches(query) {
      var ranges = rangeMatches(query, document.body);
      var controls = controlMatches(query, document.body);
      return ranges.concat(controls).sort(compareMatches);
    }

    function compareMatches(first, second) {
      var firstElement = first.control || first.startContainer.parentElement;
      var secondElement = second.control || second.startContainer.parentElement;
      if (firstElement === secondElement) return 0;
      return firstElement.compareDocumentPosition(secondElement) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1;
    }

    function clearControlMarks() {
      for (var index = 0; index < state.controlMarks.length; index++) {
        var mark = state.controlMarks[index];
        mark.control.classList.remove(mark.name);
      }
      state.controlMarks = [];
    }

    // Form values are rendered without text nodes, so ranges cannot paint
    // them. These short-lived classes are cleared with the find session.
    function markControl(control, name) {
      if (control.classList.contains(name)) return;
      control.classList.add(name);
      state.controlMarks.push({ control: control, name: name });
    }

    function paint() {
      if (!state.matches.length) return clearHighlights();
      installStyle();
      var all = new Highlight();
      var active = state.matches[state.index];
      clearControlMarks();
      for (var i = 0; i < state.matches.length; i++) {
        var match = state.matches[i];
        if (match.control) markControl(match.control, CONTROL_ALL);
        else all.add(match);
      }
      all.priority = 0;
      if (all.size) CSS.highlights.set(ALL, all);
      else CSS.highlights.delete(ALL);
      if (active.control) markControl(active.control, CONTROL_ACTIVE);
      var activeRange = active.control ? new Highlight() : new Highlight(active);
      // The active match sits inside the all-matches highlight; priority is
      // what decides which colour wins on the overlap.
      activeRange.priority = 1;
      if (activeRange.size) CSS.highlights.set(ACTIVE, activeRange);
      else CSS.highlights.delete(ACTIVE);
    }

    function clearHighlights() {
      if (!supported()) return;
      CSS.highlights.delete(ALL);
      CSS.highlights.delete(ACTIVE);
      clearControlMarks();
    }

    function rectFor(match) {
      return match.control ? match.control.getBoundingClientRect() : match.getBoundingClientRect();
    }

    function onScreen(match) {
      var rect = rectFor(match);
      if (!rect.width && !rect.height) return false;
      return rect.top >= 0 && rect.bottom <= window.innerHeight;
    }

    // A fresh query starts at the first match the reader can already see, the
    // way every other browser does it, rather than jumping to the top.
    function firstVisibleIndex(matches) {
      var scanned = Math.min(matches.length, 500);
      var dialog = frontmostDialog();
      if (dialog) {
        for (var dialogIndex = 0; dialogIndex < scanned; dialogIndex++) {
          var dialogMatch = matches[dialogIndex];
          var dialogElement = dialogMatch.control || dialogMatch.startContainer.parentElement;
          if (dialog.contains(dialogElement) && rectFor(dialogMatch).bottom > 0) return dialogIndex;
        }
      }
      for (var i = 0; i < scanned; i++) {
        if (rectFor(matches[i]).bottom > 0) return i;
      }
      return 0;
    }

    function reveal(match) {
      if (onScreen(match)) return;
      var element = match.control || match.startContainer.parentElement;
      if (!element) return;
      element.scrollIntoView({ block: 'center', inline: 'nearest' });
      // scrollIntoView centres the element, which for a long paragraph can
      // still leave the match itself off screen.
      var rect = rectFor(match);
      if (rect.top < 0 || rect.bottom > window.innerHeight) {
        window.scrollBy(0, rect.top - window.innerHeight / 2);
      }
    }

    function stale() {
      var current = state.matches[state.index];
      if (!current) return true;
      return current.control ? !current.control.isConnected : !current.getClientRects().length;
    }

    window.redentFind = function (query, forward, requestID) {
      if (!supported() || typeof query !== 'string' || !query.length) return { total: 0, current: 0 };
      try {
        if (typeof requestID === 'number' && requestID < state.requestID) {
          return { total: state.matches.length, current: state.index + 1 };
        }
        if (typeof requestID === 'number') state.requestID = requestID;
        var stepping = query === state.query && state.matches.length > 0 && !stale();
        if (stepping) {
          var count = state.matches.length;
          state.index = (state.index + (forward ? 1 : -1) + count) % count;
        } else {
          state.query = query;
          state.matches = findMatches(query);
          state.index = state.matches.length ? firstVisibleIndex(state.matches) : -1;
        }
        if (!state.matches.length) {
          clearHighlights();
          return { total: 0, current: 0 };
        }
        paint();
        reveal(state.matches[state.index]);
        return { total: state.matches.length, current: state.index + 1 };
      } catch (e) {
        return { total: 0, current: 0 };
      }
    };

    window.redentFindClear = function (requestID) {
      try {
        if (typeof requestID === 'number' && requestID < state.requestID) return;
        if (typeof requestID === 'number') state.requestID = requestID;
        state.query = '';
        state.matches = [];
        state.index = -1;
        clearHighlights();
      } catch (e) {}
    };
  } catch (e) {}
})();
