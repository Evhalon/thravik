// Runs in the isolated redent world. Ranges paint text without changing the
// page's text nodes, so find cannot interfere with a framework's DOM ownership.
(function () {
  'use strict';
  var ALL = 'redent-find-all';
  var ACTIVE = 'redent-find-active';
  var CONTROL_ALL = 'redent-find-control-all';
  var CONTROL_ACTIVE = 'redent-find-control-active';
  var RULES =
    '::highlight(redent-find-all){background-color:#ffe55a;color:#101010}' +
    '::highlight(redent-find-active){background-color:#ff9632;color:#101010}' +
    '.redent-find-control-all{outline:2px solid #ffe55a!important;outline-offset:-2px}' +
    '.redent-find-control-active{outline:3px solid #ff9632!important;outline-offset:-2px}';
  var SKIP = { SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, TITLE: 1, TEMPLATE: 1 };
  var state = {
    query: '', matches: [], index: -1, sheet: null, requestID: 0,
    controlMarks: [], selections: new Map(), frameSlots: [], roots: []
  };
  var graphemes = typeof Intl.Segmenter === 'function'
    ? new Intl.Segmenter(undefined, { granularity: 'grapheme' }) : null;

  function supported() {
    return typeof CSS !== 'undefined' && !!CSS.highlights && typeof Highlight === 'function';
  }

  function installStyle(root) {
    if (!root) return;
    try {
      if (!state.sheet) {
        state.sheet = new CSSStyleSheet();
        state.sheet.replaceSync(RULES);
      }
      if (!root.adoptedStyleSheets.includes(state.sheet)) {
        root.adoptedStyleSheets = root.adoptedStyleSheets.concat(state.sheet);
      }
    } catch (error) {}
  }

  function parentOf(node) {
    if (node.assignedSlot) return node.assignedSlot;
    if (node.parentElement) return node.parentElement;
    var root = node.getRootNode ? node.getRootNode() : null;
    return root && root.host ? root.host : null;
  }

  function visible(element) {
    if (!element) return false;
    var style = window.getComputedStyle(element);
    if (style.display === 'none' || style.visibility === 'hidden' || style.visibility === 'collapse') return false;
    if (style.contentVisibility === 'hidden') return false;
    if (style.display === 'contents' || element.nodeName === 'SLOT') return visible(parentOf(element));
    if (element.checkVisibility) return element.checkVisibility({ visibilityProperty: true });
    for (var node = parentOf(element); node; node = parentOf(node)) {
      if (window.getComputedStyle(node).display === 'none') return false;
    }
    return !!element.getClientRects().length;
  }

  function folded(text) {
    // Latin accents are ignored by browser find; Japanese voicing marks carry
    // meaning and must survive normalization. Original offsets are kept below.
    return text.normalize('NFD').replace(/([\p{Script=Latin}])\p{M}+/gu, '$1')
      .normalize('NFC').toLowerCase().replace(/\u03c2/g, '\u03c3').replace(/\u00ad/g, '');
  }

  function pieces(text) {
    if (graphemes) return Array.from(graphemes.segment(text));
    var offset = 0;
    return Array.from(text).map(function (character) {
      var piece = { segment: character, index: offset };
      offset += character.length;
      return piece;
    });
  }

  function normalized(text) {
    return folded(text).replace(/[\s\u00a0]+/gu, ' ');
  }

  function newRun(page, root) {
    var run = { text: '', segments: [], root: root, order: page.groups.length };
    page.groups.push(run);
    page.run = run;
    return run;
  }

  function boundary(page) { page.run = null; }

  function appendText(node, page) {
    if (!node.data) return;
    var parent = node.parentElement || parentOf(node);
    if (!parent) return;
    var rendered = page.visibility.get(parent);
    if (rendered === undefined) {
      rendered = visible(parent);
      page.visibility.set(parent, rendered);
    }
    if (!rendered) return;
    var root = node.getRootNode();
    var run = page.run && page.run.root === root ? page.run : newRun(page, root);
    var segment = { node: node, start: run.text.length, starts: [], ends: [] };
    pieces(node.data).forEach(function (piece) {
      var value = folded(piece.segment);
      if (/^[\s\u00a0]+$/u.test(value)) value = run.text.endsWith(' ') ? '' : ' ';
      for (var index = 0; index < value.length; index++) {
        segment.starts.push(piece.index);
        segment.ends.push(piece.index + piece.segment.length);
      }
      run.text += value;
    });
    if (segment.starts.length) run.segments.push(segment);
  }

  function searchableValue(control) {
    if (control.nodeName === 'SELECT') {
      return Array.from(control.selectedOptions).map(function (option) { return option.text; }).join(' ');
    }
    if (/^(checkbox|file|hidden|image|password|radio)$/.test((control.type || '').toLowerCase())) return '';
    return control.value || '';
  }

  function appendControl(control, page) {
    boundary(page);
    if (!visible(control)) return;
    var value = searchableValue(control);
    if (value) page.groups.push({ control: control, value: value, order: page.groups.length });
  }

  function appendFrame(frame, page) {
    boundary(page);
    if (!visible(frame)) return;
    page.frames.push({ node: frame, order: page.groups.length });
  }

  function childrenOf(node) {
    if (node.nodeName !== 'SLOT') return node.childNodes;
    var assigned = node.assignedNodes({ flatten: true });
    return assigned.length ? assigned : node.childNodes;
  }

  function walkRendered(node, page) {
    if (node.nodeType === Node.TEXT_NODE) return appendText(node, page);
    if (node.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
      Array.from(node.childNodes).forEach(function (child) { walkRendered(child, page); });
      return;
    }
    if (node.nodeType !== Node.ELEMENT_NODE || SKIP[node.nodeName]) return;
    if (/^(INPUT|TEXTAREA|SELECT)$/.test(node.nodeName)) return appendControl(node, page);
    if (/^(IFRAME|FRAME)$/.test(node.nodeName)) return appendFrame(node, page);
    if (node.nodeName === 'BR') {
      if (!page.run || page.run.text.endsWith(' ') || !visible(node)) return;
      var offset = Array.prototype.indexOf.call(node.parentNode.childNodes, node);
      page.run.segments.push({ node: node.parentNode, start: page.run.text.length, starts: [offset], ends: [offset + 1] });
      page.run.text += ' ';
      return;
    }
    var style = window.getComputedStyle(node);
    if (style.display === 'none' || style.contentVisibility === 'hidden') return;
    var separates = !/^(inline|contents)/.test(style.display) && node.nodeName !== 'SLOT';
    if (separates) boundary(page);
    if (node.shadowRoot) {
      page.roots.push(node.shadowRoot);
      walkRendered(node.shadowRoot, page);
    } else {
      Array.from(childrenOf(node)).forEach(function (child) { walkRendered(child, page); });
    }
    if (separates) boundary(page);
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

  function rangeFor(run, start, end) {
    var head = segmentAt(run.segments, start);
    var tail = segmentAt(run.segments, end - 1);
    if (!head || !tail) return null;
    var startOffset = head.starts[start - head.start];
    var endOffset = tail.ends[end - 1 - tail.start];
    if (startOffset === undefined || endOffset === undefined) return null;
    var range = document.createRange();
    range.setStart(head.node, startOffset);
    range.setEnd(tail.node, endOffset);
    range.findOrder = run.order;
    return range;
  }

  function matchesInRun(run, query) {
    if (run.control) return matchesInControl(run, query);
    var matches = [];
    var offset = run.text.indexOf(query);
    while (offset >= 0) {
      var range = rangeFor(run, offset, offset + query.length);
      if (range) matches.push(range);
      offset = run.text.indexOf(query, offset + query.length);
    }
    return matches;
  }

  function matchesInControl(group, query) {
    var run = { text: '' };
    // Form values have no DOM text nodes; their source offsets drive the
    // active control's selection without focusing it.
    var starts = [];
    var ends = [];
    pieces(group.value).forEach(function (piece) {
      var value = folded(piece.segment);
      if (/^[\s\u00a0]+$/u.test(value)) value = run.text.endsWith(' ') ? '' : ' ';
      for (var index = 0; index < value.length; index++) {
        starts.push(piece.index);
        ends.push(piece.index + piece.segment.length);
      }
      run.text += value;
    });
    var matches = [];
    var offset = run.text.indexOf(query);
    while (offset >= 0) {
      matches.push({ control: group.control, start: starts[offset], end: ends[offset + query.length - 1], findOrder: group.order });
      offset = run.text.indexOf(query, offset + query.length);
    }
    return matches;
  }

  function frameIndex(frame) {
    for (var index = 0; index < window.frames.length; index++) {
      if (window.frames[index] === frame.contentWindow) return index;
    }
    return -1;
  }

  function findMatches(query) {
    if (!document.body) return [];
    var page = { groups: [], run: null, frames: [], roots: [document], visibility: new Map() };
    walkRendered(document.body, page);
    state.roots = page.roots;
    var needle = normalized(query);
    var matches = needle ? page.groups.flatMap(function (run) { return matchesInRun(run, needle); }) : [];
    var before = 0;
    state.frameSlots = page.frames.map(function (frame) {
      while (before < matches.length && matches[before].findOrder < frame.order) before++;
      return { index: frameIndex(frame.node), before: before };
    }).filter(function (slot) { return slot.index >= 0; });
    return matches;
  }

  function clearControlMarks() {
    state.controlMarks.forEach(function (mark) { mark.control.classList.remove(mark.name); });
    state.controlMarks = [];
  }

  function markControl(control, name) {
    if (control.classList.contains(name)) return;
    control.classList.add(name);
    state.controlMarks.push({ control: control, name: name });
  }

  function retire(name) {
    if (!supported()) return;
    var previous = CSS.highlights.get(name);
    if (previous) previous.clear();
    CSS.highlights.delete(name);
  }

  function publish(name, highlight) {
    retire(name);
    if (highlight.size) CSS.highlights.set(name, highlight);
  }

  function restoreSelections(keeping) {
    state.selections.forEach(function (selection, control) {
      if (control === keeping) return;
      if (control.selectionStart === selection.appliedStart && control.selectionEnd === selection.appliedEnd) {
        try { control.setSelectionRange(selection.start, selection.end, selection.direction); } catch (error) {}
      }
      state.selections.delete(control);
    });
  }

  function selectControl(match) {
    var control = match.control;
    if (!control || typeof control.setSelectionRange !== 'function' || control.selectionStart === null) return;
    var selection = state.selections.get(control);
    if (!selection || control.selectionStart !== selection.appliedStart || control.selectionEnd !== selection.appliedEnd) {
      selection = { start: control.selectionStart, end: control.selectionEnd, direction: control.selectionDirection };
      state.selections.set(control, selection);
    }
    try {
      control.setSelectionRange(match.start, match.end);
      selection.appliedStart = control.selectionStart;
      selection.appliedEnd = control.selectionEnd;
    } catch (error) {}
  }

  function paint() {
    clearControlMarks();
    if (!state.matches.length) return clearHighlights();
    installStyle(document);
    var all = new Highlight();
    state.matches.forEach(function (match) {
      installStyle((match.control || match.startContainer).getRootNode());
      if (match.control) markControl(match.control, CONTROL_ALL);
      else all.add(match);
    });
    all.priority = 0;
    publish(ALL, all);
    paintActive();
  }

  function paintActive() {
    state.controlMarks = state.controlMarks.filter(function (mark) {
      if (mark.name !== CONTROL_ACTIVE) return true;
      mark.control.classList.remove(mark.name);
      return false;
    });
    var active = state.matches[state.index];
    restoreSelections(active && active.control);
    var highlight = new Highlight();
    if (active && active.control) {
      markControl(active.control, CONTROL_ACTIVE);
      selectControl(active);
    } else if (active) highlight.add(active);
    highlight.priority = 1;
    publish(ACTIVE, highlight);
  }

  function clearHighlights() {
    retire(ALL);
    retire(ACTIVE);
    clearControlMarks();
    restoreSelections();
  }

  function rectFor(match) {
    return match.control ? match.control.getBoundingClientRect() : match.getBoundingClientRect();
  }

  function elementFor(match) {
    return match.control || match.startContainer.parentElement || parentOf(match.startContainer);
  }

  function frontmostDialog() {
    var selector = 'dialog[open],[aria-modal="true"],[role="dialog"],[role="alertdialog"]';
    var dialogs = state.roots.flatMap(function (root) { return Array.from(root.querySelectorAll(selector)); }).filter(visible);
    dialogs.sort(function (first, second) {
      if (first.contains(second)) return 1;
      if (second.contains(first)) return -1;
      var difference = layerDepth(first) - layerDepth(second);
      if (difference) return difference;
      var firstZ = Number(window.getComputedStyle(first).zIndex) || 0;
      var secondZ = Number(window.getComputedStyle(second).zIndex) || 0;
      if (firstZ !== secondZ) return secondZ - firstZ;
      return first.compareDocumentPosition(second) & Node.DOCUMENT_POSITION_FOLLOWING ? 1 : -1;
    });
    return dialogs[0] || null;
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

  function composedContains(container, element) {
    for (var node = element; node; node = parentOf(node)) {
      if (node === container) return true;
    }
    return false;
  }

  function firstVisibleIndex(matches, forward) {
    var dialog = frontmostDialog();
    var indices = matches.map(function (match, index) { return index; });
    if (!forward) indices.reverse();
    if (dialog) {
      var dialogIndex = indices.find(function (index) { return composedContains(dialog, elementFor(matches[index])); });
      if (dialogIndex !== undefined) return dialogIndex;
    }
    var visibleIndex = indices.find(function (index) {
      var rect = rectFor(matches[index]);
      return forward ? rect.bottom > 0 : rect.top < window.innerHeight;
    });
    return visibleIndex === undefined ? (forward ? 0 : matches.length - 1) : visibleIndex;
  }

  function scrollsForReader(style, axis) {
    return /auto|scroll|overlay/.test(axis === 'x' ? style.overflowX : style.overflowY);
  }

  function scrollContainers(element) {
    var root = document.scrollingElement || document.documentElement;
    var containers = [];
    for (var node = element; node && node !== root; node = parentOf(node)) {
      if (node === document.body) continue;
      var style = window.getComputedStyle(node);
      var horizontal = node.scrollWidth > node.clientWidth && scrollsForReader(style, 'x');
      var vertical = node.scrollHeight > node.clientHeight && scrollsForReader(style, 'y');
      if (horizontal || vertical) containers.push({ node: node, horizontal: horizontal, vertical: vertical });
    }
    return containers;
  }

  function centre(match, container) {
    var rect = rectFor(match);
    var box = container.node.getBoundingClientRect();
    if (container.vertical && (rect.top < box.top || rect.bottom > box.bottom)) {
      container.node.scrollTop += rect.top - box.top - (container.node.clientHeight - rect.height) / 2;
    }
    if (container.horizontal && (rect.left < box.left || rect.right > box.right)) {
      container.node.scrollLeft += rect.left - box.left - (container.node.clientWidth - rect.width) / 2;
    }
  }

  function pageScrolls(axis) {
    return [document.documentElement, document.body].every(function (element) {
      if (!element) return true;
      var style = window.getComputedStyle(element);
      return !/hidden|clip/.test(axis === 'x' ? style.overflowX : style.overflowY);
    });
  }

  function reveal(match) {
    var element = elementFor(match);
    if (!element) return;
    scrollContainers(element).forEach(function (container) { centre(match, container); });
    var rect = rectFor(match);
    var x = pageScrolls('x') && (rect.left < 0 || rect.right > window.innerWidth)
      ? rect.left - (window.innerWidth - rect.width) / 2 : 0;
    var y = pageScrolls('y') && (rect.top < 0 || rect.bottom > window.innerHeight)
      ? rect.top - (window.innerHeight - rect.height) / 2 : 0;
    if (x || y) window.scrollBy(x, y);
  }

  function preservedIndex(previous, oldIndex, matches, forward) {
    if (!matches.length) return -1;
    if (!previous) return firstVisibleIndex(matches, forward);
    var exact = matches.findIndex(function (match) {
      if (previous.control) return match.control === previous.control && match.start === previous.start;
      return !match.control && match.startContainer === previous.startContainer
        && match.startOffset === previous.startOffset;
    });
    if (exact >= 0) return exact;
    var overlapping = matches.findIndex(function (match) {
      if (previous.control) {
        return match.control === previous.control && match.start < previous.end && match.end > previous.start;
      }
      if (match.control || match.startContainer.getRootNode() !== previous.startContainer.getRootNode()) return false;
      return match.compareBoundaryPoints(Range.START_TO_END, previous) > 0
        && match.compareBoundaryPoints(Range.END_TO_START, previous) < 0;
    });
    if (overlapping >= 0) return overlapping;
    if (previous.control ? !previous.control.isConnected : !previous.startContainer.isConnected) {
      return Math.min(Math.max(oldIndex, 0), matches.length - 1);
    }
    return firstVisibleIndex(matches, forward);
  }

  function accepted(requestID) {
    if (typeof requestID !== 'number') return true;
    if (requestID < state.requestID) return false;
    state.requestID = requestID;
    return true;
  }

  function result() { return { total: state.matches.length, current: state.index + 1 }; }

  function refresh(query, forward) {
    var previous = state.matches[state.index];
    var oldIndex = state.index;
    state.query = query;
    state.matches = findMatches(query);
    state.index = preservedIndex(previous, oldIndex, state.matches, forward);
    paint();
    return result();
  }

  window.redentFindRefresh = function (query, requestID, forward) {
    if (!accepted(requestID)) return result();
    if (typeof query !== 'string' || !query.length) {
      window.redentFindClear(requestID);
      return result();
    }
    if (!supported()) return { total: 0, current: 0 };
    try { return refresh(query, forward !== false); } catch (error) {
      window.redentFindClear(requestID);
      return result();
    }
  };

  window.redentFindActivate = function (index, requestID) {
    if (!accepted(requestID)) return result();
    state.index = Number.isInteger(index) && index >= 0 && index < state.matches.length ? index : -1;
    paintActive();
    if (state.index >= 0) reveal(state.matches[state.index]);
    return result();
  };

  window.redentFindRevealElement = function (element) { if (element) reveal({ control: element }); };
  window.redentFindFrameSlots = function () { return state.frameSlots; };
  window.redentFindSnapshot = function () { return result(); };

  window.redentFind = function (query, forward, requestID) {
    if (!accepted(requestID)) return result();
    if (typeof query !== 'string' || !query.length) {
      window.redentFindClear(requestID);
      return result();
    }
    if (!supported()) return { total: 0, current: 0 };
    try {
      var stepping = query === state.query && state.matches.length > 0;
      refresh(query, forward !== false);
      if (stepping && state.matches.length) {
        state.index = (state.index + (forward ? 1 : -1) + state.matches.length) % state.matches.length;
        paintActive();
      }
      if (state.index >= 0) reveal(state.matches[state.index]);
      return result();
    } catch (error) {
      window.redentFindClear(requestID);
      return result();
    }
  };

  window.redentFindClear = function (requestID) {
    if (!accepted(requestID)) return;
    state.query = '';
    state.matches = [];
    state.frameSlots = [];
    state.roots = [];
    state.index = -1;
    clearHighlights();
  };
})();
