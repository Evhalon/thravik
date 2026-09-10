// Redent find-in-page. Runs in the isolated "redent" world, beside the page
// bridge. Matches are painted with the CSS Custom Highlight API, which colours
// ranges without inserting a single node into the page's DOM — no wrapper
// spans for a framework to reconcile away, and nothing left behind on close.
(function () {
  'use strict';
  try {
    var ALL = 'redent-find-all';
    var ACTIVE = 'redent-find-active';
    var RULES =
      '::highlight(redent-find-all){background-color:#ffe55a;color:#101010}' +
      '::highlight(redent-find-active){background-color:#ff9632;color:#101010}';
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

    var state = { query: '', ranges: [], index: -1, styled: false };

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

    function blockAncestor(element) {
      var node = element;
      while (node && INLINE[node.nodeName]) node = node.parentElement;
      return node;
    }

    function visible(element) {
      if (element.checkVisibility) {
        return element.checkVisibility({ contentVisibilityAuto: true, visibilityProperty: true });
      }
      return !!element.offsetParent || element.nodeName === 'BODY';
    }

    // The page's visible text as one string, with a map back to the nodes it
    // came from, so a match may span the <em> in the middle of a sentence.
    function readPage() {
      var segments = [];
      var text = '';
      var lastBlock = null;
      if (!document.body) return { segments: segments, text: text };
      var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
        acceptNode: function (node) {
          var parent = node.parentElement;
          if (!node.data || !parent || SKIP[parent.nodeName]) return NodeFilter.FILTER_REJECT;
          return visible(parent) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        }
      });
      for (var node = walker.nextNode(); node; node = walker.nextNode()) {
        var block = blockAncestor(node.parentElement);
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

    function findRanges(query) {
      var page = readPage();
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

    function paint() {
      if (!state.ranges.length) return clearHighlights();
      installStyle();
      var all = new Highlight();
      for (var i = 0; i < state.ranges.length; i++) all.add(state.ranges[i]);
      all.priority = 0;
      CSS.highlights.set(ALL, all);
      var active = new Highlight(state.ranges[state.index]);
      // The active match sits inside the all-matches highlight; priority is
      // what decides which colour wins on the overlap.
      active.priority = 1;
      CSS.highlights.set(ACTIVE, active);
    }

    function clearHighlights() {
      if (!supported()) return;
      CSS.highlights.delete(ALL);
      CSS.highlights.delete(ACTIVE);
    }

    function onScreen(range) {
      var rect = range.getBoundingClientRect();
      if (!rect.width && !rect.height) return false;
      return rect.top >= 0 && rect.bottom <= window.innerHeight;
    }

    // A fresh query starts at the first match the reader can already see, the
    // way every other browser does it, rather than jumping to the top.
    function firstVisibleIndex(ranges) {
      var scanned = Math.min(ranges.length, 500);
      for (var i = 0; i < scanned; i++) {
        if (ranges[i].getBoundingClientRect().bottom > 0) return i;
      }
      return 0;
    }

    function reveal(range) {
      if (onScreen(range)) return;
      var element = range.startContainer.parentElement;
      if (!element) return;
      element.scrollIntoView({ block: 'center', inline: 'nearest' });
      // scrollIntoView centres the element, which for a long paragraph can
      // still leave the match itself off screen.
      var rect = range.getBoundingClientRect();
      if (rect.top < 0 || rect.bottom > window.innerHeight) {
        window.scrollBy(0, rect.top - window.innerHeight / 2);
      }
    }

    function stale() {
      var current = state.ranges[state.index];
      return !current || !current.getClientRects().length;
    }

    window.redentFind = function (query, forward) {
      if (!supported() || typeof query !== 'string' || !query.length) return { total: 0, current: 0 };
      try {
        var stepping = query === state.query && state.ranges.length > 0 && !stale();
        if (stepping) {
          var count = state.ranges.length;
          state.index = (state.index + (forward ? 1 : -1) + count) % count;
        } else {
          state.query = query;
          state.ranges = findRanges(query);
          state.index = state.ranges.length ? firstVisibleIndex(state.ranges) : -1;
        }
        if (!state.ranges.length) {
          clearHighlights();
          return { total: 0, current: 0 };
        }
        paint();
        reveal(state.ranges[state.index]);
        return { total: state.ranges.length, current: state.index + 1 };
      } catch (e) {
        return { total: 0, current: 0 };
      }
    };

    window.redentFindClear = function () {
      try {
        state.query = '';
        state.ranges = [];
        state.index = -1;
        clearHighlights();
      } catch (e) {}
    };
  } catch (e) {}
})();
