// Redent Reader. Runs in the isolated "redent" world of the main frame. Finds
// the page's article, rebuilds it from scratch — no page attribute, handler or
// script is ever copied — and lays it over the page in a closed shadow root.
// Toggling off removes the overlay and leaves the page exactly as it was.
(function () {
  'use strict';
  try {
    var HOST_ID = 'redent-reader-host';
    var MIN_TEXT = 400;
    var BLOCK = { P: 1, H2: 1, H3: 1, H4: 1, H5: 1, H6: 1, UL: 1, OL: 1, LI: 1, BLOCKQUOTE: 1,
      PRE: 1, FIGURE: 1, FIGCAPTION: 1, HR: 1, TABLE: 1, THEAD: 1, TBODY: 1, TR: 1, TD: 1, TH: 1,
      DL: 1, DT: 1, DD: 1 };
    var INLINE = { A: 1, EM: 1, STRONG: 1, B: 1, I: 1, CODE: 1, SUP: 1, SUB: 1, BR: 1, IMG: 1,
      MARK: 1, SMALL: 1, S: 1, U: 1, Q: 1, ABBR: 1, TIME: 1, KBD: 1 };
    var DROP = { SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, IFRAME: 1, FORM: 1, BUTTON: 1, INPUT: 1,
      SELECT: 1, TEXTAREA: 1, NAV: 1, ASIDE: 1, FOOTER: 1, SVG: 1, CANVAS: 1, VIDEO: 1,
      AUDIO: 1, OBJECT: 1, EMBED: 1, TEMPLATE: 1, DIALOG: 1, H1: 1 };
    var NOISE = /comment|share|social|related|promo|sidebar|footer|masthead|menu|subscribe|newsletter|advert|sponsor|cookie|banner|popup|modal|breadcrumb|paywall|outbrain|taboola/i;
    var saved = null;

    function text(el) { return (el.textContent || '').replace(/\s+/g, ' ').trim(); }

    function linkDensity(el) {
      var total = text(el).length;
      if (!total) return 1;
      var linked = 0;
      var links = el.querySelectorAll('a');
      for (var i = 0; i < links.length; i++) linked += text(links[i]).length;
      return linked / total;
    }

    function isNoise(el) {
      var label = (el.className && el.className.baseVal === undefined ? el.className : '') + ' ' + (el.id || '');
      return NOISE.test(label) || el.hidden || el.getAttribute('aria-hidden') === 'true';
    }

    // Readability's classic scoring: every paragraph credits its parent in
    // full and its grandparent in half; link-heavy blocks are discounted.
    function findArticle() {
      var scores = new Map();
      var paragraphs = document.querySelectorAll('p, pre, td');
      for (var i = 0; i < paragraphs.length; i++) {
        var content = text(paragraphs[i]);
        if (content.length < 25) continue;
        var score = 1 + content.split(',').length + Math.min(Math.floor(content.length / 100), 3);
        var parent = paragraphs[i].parentElement;
        if (!parent) continue;
        scores.set(parent, (scores.get(parent) || 0) + score);
        if (parent.parentElement) scores.set(parent.parentElement, (scores.get(parent.parentElement) || 0) + score / 2);
      }
      var best = null, bestScore = 0;
      scores.forEach(function (score, el) {
        var adjusted = score * (1 - linkDensity(el)) * (isNoise(el) ? 0.5 : 1);
        if (adjusted > bestScore) { best = el; bestScore = adjusted; }
      });
      var article = document.querySelector('article');
      if (article && text(article).length > MIN_TEXT && (!best || article.contains(best))) return article;
      return best;
    }

    function safeURL(raw) {
      try {
        var url = new URL(raw, document.baseURI);
        return url.protocol === 'https:' || url.protocol === 'http:' ? url.href : null;
      } catch (e) { return null; }
    }

    function copyImage(source, doc) {
      var src = safeURL(source.currentSrc || source.src || source.getAttribute('data-src') || '');
      if (!src) return null;
      var img = doc.createElement('img');
      img.src = src;
      img.alt = source.alt || '';
      img.loading = 'lazy';
      return img;
    }

    // Rebuilt, never cloned: the only attributes that survive are the few set here.
    function rebuild(node, into, doc) {
      for (var child = node.firstChild; child; child = child.nextSibling) {
        if (child.nodeType === 3) { into.appendChild(doc.createTextNode(child.nodeValue)); continue; }
        if (child.nodeType !== 1) continue;
        var tag = child.tagName;
        if (DROP[tag] || isNoise(child)) continue;
        if (tag === 'IMG') { var img = copyImage(child, doc); if (img) into.appendChild(img); continue; }
        if (!BLOCK[tag] && !INLINE[tag]) {
          var wrapper = /^(DIV|SECTION|ARTICLE|MAIN|HEADER)$/.test(tag) ? doc.createElement('div') : null;
          rebuild(child, wrapper || into, doc);
          if (wrapper && wrapper.childNodes.length) into.appendChild(wrapper);
          continue;
        }
        var copy = doc.createElement(tag.toLowerCase());
        if (tag === 'A') { var href = safeURL(child.getAttribute('href') || ''); if (href) copy.href = href; }
        rebuild(child, copy, doc);
        into.appendChild(copy);
      }
    }

    function meta(selector) {
      var el = document.querySelector(selector);
      return el ? (el.getAttribute('content') || '').trim() : '';
    }

    function header(doc, body) {
      var site = meta('meta[property="og:site_name"]') || location.hostname.replace(/^www\./, '');
      var title = meta('meta[property="og:title"]') || text(document.querySelector('h1') || document.createElement('i')) || document.title;
      var byline = meta('meta[name="author"]');
      var minutes = Math.max(1, Math.round(text(body).split(' ').length / 230));
      var head = doc.createElement('header');
      var kicker = doc.createElement('p');
      kicker.className = 'kicker';
      kicker.textContent = [site, byline, minutes + ' min read'].filter(Boolean).join(' · ');
      var h1 = doc.createElement('h1');
      h1.textContent = title;
      head.appendChild(kicker);
      head.appendChild(h1);
      return head;
    }

    var STYLE =
      ':host{all:initial}' +
      '.page{position:fixed;inset:0;overflow:auto;z-index:2147483647;background:#faf8f3;color:#1d1d1f;' +
      'font:20px/1.65 "New York",ui-serif,Georgia,serif;-webkit-font-smoothing:antialiased}' +
      'article{max-width:680px;margin:0 auto;padding:72px 28px 120px}' +
      '.kicker{font:600 13px/1.4 -apple-system,system-ui,sans-serif;letter-spacing:.02em;color:#86868b;margin:0 0 12px}' +
      'h1{font-size:40px;line-height:1.15;margin:0 0 36px;font-weight:700}' +
      'h2,h3,h4{line-height:1.3;margin:1.6em 0 .5em}' +
      'img{max-width:100%;height:auto;border-radius:10px;display:block;margin:1.2em auto}' +
      'a{color:#0a6cdf;text-decoration:none}a:hover{text-decoration:underline}' +
      'pre,code{font:15px/1.5 ui-monospace,Menlo,monospace}pre{overflow:auto;padding:14px;border-radius:10px;background:rgba(0,0,0,.05)}' +
      'blockquote{margin:1.2em 0;padding-left:18px;border-left:3px solid #d2d2d7;color:#515154}' +
      'figcaption{font-size:14px;color:#86868b;text-align:center}table{border-collapse:collapse}td,th{padding:4px 8px}' +
      '@media (prefers-color-scheme:dark){.page{background:#1c1c1e;color:#e8e8ed}' +
      'a{color:#5eadff}blockquote{border-color:#48484a;color:#aeaeb2}pre{background:rgba(255,255,255,.06)}}';

    function open() {
      var source = findArticle();
      if (!source || text(source).length < MIN_TEXT) return false;
      var host = document.createElement('div');
      host.id = HOST_ID;
      var shadow = host.attachShadow({ mode: 'closed' });
      var style = document.createElement('style');
      style.textContent = STYLE;
      var page = document.createElement('div');
      page.className = 'page';
      var article = document.createElement('article');
      var body = document.createElement('div');
      rebuild(source, body, document);
      article.appendChild(header(document, body));
      article.appendChild(body);
      page.appendChild(article);
      shadow.appendChild(style);
      shadow.appendChild(page);
      saved = { overflow: document.documentElement.style.overflow, host: host };
      document.documentElement.style.overflow = 'hidden';
      document.documentElement.appendChild(host);
      page.tabIndex = -1;
      page.focus({ preventScroll: true });
      return true;
    }

    function close() {
      if (!saved) return false;
      saved.host.remove();
      document.documentElement.style.overflow = saved.overflow;
      saved = null;
      return false;
    }

    window.redentToggleReader = function () { return saved ? close() : open(); };
    window.redentReaderIsOpen = function () { return !!saved; };
  } catch (e) {}
})();
